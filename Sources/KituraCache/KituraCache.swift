/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import Dispatch

// MARK KituraCache

/// A thread-safe, in-memory cache for storing an object against a `Hashable` key.
public class KituraCache {
    
    private var cache = [AnyHashable : CacheObject]()
    private let defaultTTL: UInt
    private let checkFrequency: UInt
    
    /// `Statistics` about the cache.
    public private(set) var statistics: Statistics

    private var timer: DispatchSourceTimer?
    private let timerQueue: DispatchQueue
    private let queue: DispatchQueue
    
    /// Creates a cache.
    ///
    /// ```swift
    /// let cache = KituraCache(defaultTTL: 3600, checkFrequency: 600)
    /// ```
    ///
    /// - Parameters:
    ///   - defaultTTL: The time-to-live value, in seconds, used for new entries when none is specified in ``setObject(_:forKey:withTTL:)``. A value of `0` means entries never expire.
    ///   - checkFrequency: The frequency, in seconds, used to check for expired entries.
    public init(defaultTTL: UInt = 0, checkFrequency: UInt = 60) {
        self.defaultTTL = defaultTTL
        self.checkFrequency = checkFrequency
        statistics = Statistics()
        
        queue =  DispatchQueue(label: "KituraCache: queue", attributes: [DispatchQueue.Attributes.concurrent])
        timerQueue =  DispatchQueue(label: "KituraCache: timerQueue")

        startDataChecks()
    }
    
    deinit {
        stopDataChecks()
    }
    
    private func setCacheObject<T: Hashable>(_ object: Any, forKey key: T, withTTL ttl: UInt) {
        if let cacheObject = cache[AnyHashable(key)] {
            cacheObject.data = object
            cacheObject.setTTL(ttl)
        }
        else {
            cache[AnyHashable(key)] = CacheObject(data: object, ttl: ttl)
            statistics.numberOfKeys += 1
        }
    }
    
    //MARK: Adding objects
    
    /// Adds a new entry, or updates the existing entry for the same key.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.setObject(item, forKey: item.id)
    /// ```
    ///
    /// - Parameters:
    ///   - object: The object to store in the cache.
    ///   - key: The `Hashable` key to associate with the entry.
    ///   - withTTL: The optional time-to-live value, in seconds, for the entry. If omitted, the cache's default TTL is used.
    public func setObject<T: Hashable>(_ object: Any, forKey key: T, withTTL: UInt?=nil) {
        let ttl = withTTL ?? defaultTTL

        queue.sync(flags: [.barrier]) {
            setCacheObject(object, forKey: key, withTTL: ttl)
        }
    }
    
    private func getCacheObject<T: Hashable>(forKey key: T) -> Any? {
        if let cacheObject = cache[AnyHashable(key)], !cacheObject.expired() {
            statistics.hits += 1
            return cacheObject.data
        }
        else {
            statistics.misses += 1
            return nil
        }
    }
    
    //MARK: Retrieving objects
    
    /// Retrieves an object from the cache for a specified key.
    ///
    /// ```swift
    /// let cache = KituraCache()
    ///
    /// if let item = cache.object(forKey: 1) {
    ///   // Object with key of 1 retrieved from cache.
    /// } else {
    ///   // No object stored in cache with key of 1.
    /// }
    /// ```
    ///
    /// - Parameter key: The key associated with the entry to retrieve.
    /// - Returns: The object stored in the cache for the specified key, or `nil` if no object exists for that key.
    public func object<T: Hashable>(forKey key: T) -> Any? {
        var object : Any?
        queue.sync() {
            object = getCacheObject(forKey: key)
        }
        return object
    }
    
    /// Retrieves all keys currently present in the cache.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// let allKeys = cache.keys()
    /// ```
    ///
    /// - Returns: An array of all keys currently present in the cache.
    public func keys() -> [Any] {
        var keys : [Any]?
        queue.sync() {
            keys = cacheKeys()
        }
        return keys!
    }
    
    private func cacheKeys() -> [Any] {
        var keys = [Any]()
        for key in self.cache.keys {
            keys.append(key.base)
        }
        return keys
    }
    
    //MARK: Removing objects
    
    /// Removes an object from the cache for a specified key.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.removeObject(forKey: 1)
    /// ```
    ///
    /// - Parameter key: The key associated with the entry to remove.
    public func removeObject<T: Hashable>(forKey key: T) {
        removeObjects(forKeys: [key])
    }
    
    /// Removes objects from the cache for multiple specified keys.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.removeObjects(forKeys: 1, 2, 3)
    /// ```
    ///
    /// - Parameter keys: The keys associated with the entries to remove.
    public func removeObjects<T: Hashable>(forKeys keys: T...) {
        removeObjects(forKeys: keys)
    }
    
    /// Removes objects from the cache for multiple specified keys.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.removeObjects(forKeys: [1, 2, 3])
    /// ```
    ///
    /// - Parameter keys: The keys associated with the entries to remove.
    public func removeObjects<T: Hashable>(forKeys keys: [T]) {
        queue.sync(flags: [.barrier]) {
            removeCacheObjects(forKeys: keys)
        }
    }

    private func removeCacheObjects<T: Hashable>(forKeys keys: [T]) {
        for key in keys {
            if let _ = cache.removeValue(forKey: AnyHashable(key)) {
                statistics.numberOfKeys -= 1
            }
        }
    }
    
    /// Removes all objects from the cache.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.removeAllObjects()
    /// ```
    public func removeAllObjects() {
        queue.sync(flags: [.barrier]) {
            removeAllCacheObjects()
        }
    }
    
    private func removeAllCacheObjects() {
        self.cache.removeAll()
        self.statistics.numberOfKeys = 0
    }
    
    //MARK: Changing TTL for an entry
    
    /// Sets the time-to-live value, in seconds, for a cache entry.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.setTTL(ttl: 360, forKey: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - ttl: The time-to-live value, in seconds.
    ///   - key: The key identifying the entry to update.
    /// - Returns: `true` if the TTL was set successfully, or `false` if the key does not exist.
    public func setTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        var success = false
        queue.sync(flags: [.barrier]) {
            success = setCacheObjectTTL(ttl, forKey: key)
        }
        return success
    }
    
    private func setCacheObjectTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        if let cacheObject = cache[AnyHashable(key)], !cacheObject.expired() {
            cacheObject.setTTL(ttl)
            return true
        }
        return false
    }
    
    //MARK: Resetting the cache
    
    /// Removes all cache entries and resets the cache statistics.
    ///
    /// ```swift
    /// let cache = KituraCache()
    /// cache.flush()
    /// ```
    public func flush() {
        queue.sync(flags: [.barrier]) {
            flushCache()
        }
    }
    
    private func flushCache() {
        cache.removeAll()
        statistics.reset()
    }
    
    
    private func check() {
        for (key, cacheObject) in cache {
            if cacheObject.expired() {
                if let _ = cache.removeValue(forKey: key) {
                    statistics.numberOfKeys -= 1
                }
            }
        }
    }
    
    private func startDataChecks() {
        timer = DispatchSource.makeTimerSource(queue: timerQueue)

        #if swift(>=4)
            timer!.schedule(deadline: DispatchTime.now(), repeating: Double(checkFrequency), leeway: DispatchTimeInterval.milliseconds(1))
        #else
            timer!.scheduleRepeating(deadline: DispatchTime.now(), interval: Double(checkFrequency), leeway: DispatchTimeInterval.milliseconds(1))
        #endif

        timer!.setEventHandler() {
            self.queue.sync(flags: [.barrier], execute: self.check)
        }
        
        timer!.resume()
    }
    
    private func restartDataChecks() {
        guard let timer = timer else {
            return
        }
        timer.suspend()

        #if swift(>=4)
            timer.schedule(deadline: DispatchTime.now(), repeating: Double(checkFrequency))
        #else
            timer.scheduleRepeating(deadline: DispatchTime.now(), interval: Double(checkFrequency))
        #endif

        timer.resume()
    }
    
    private func stopDataChecks() {
        guard let _ = timer else {
            return
        }
        timer!.cancel()
        timer = nil
    }
}
