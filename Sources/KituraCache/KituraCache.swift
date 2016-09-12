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

/// Thread-safe in-memory cache.
public class KituraCache {
    
    private var cache = [AnyKey:CacheObject]()
    private let defaultTTL: UInt
    private let checkFrequency: UInt
    
    /// The statistics of the cache.
    public private(set) var statistics: Statistics

    private var timer: DispatchSourceTimer?
    private let timerQueue: DispatchQueue
    private let queue: DispatchQueue
    
    /// Initialize an instance of `KituraCache`.
    ///
    /// - Parameter defaultTTL: The default Time to Live value in seconds set for the cache entries which
    ///                         TTL is not specified otherwise.
    /// - Parameter checkFrequency: The frequency (in seconds) of the checks for expired entries.
    public init(defaultTTL: UInt = 0, checkFrequency: UInt = 600) {
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
        if let cacheObject = cache[AnyKey(key)] {
            cacheObject.data = object
            cacheObject.setTTL(ttl)
        }
        else {
            cache[AnyKey(key)] = CacheObject(data: object, ttl: ttl)
            statistics.numberOfKeys += 1
        }
    }
    
    /// Set the cache object: update the data if the key exists, or add a new entry otherwise.
    ///
    /// - Parameter object: The data object.
    /// - Parameter forKey: The key for the data.
    /// - Parameter withTTL: The optional Time to Live value in seconds for the entry. If not specified,
    ///                     the deafult TTL is used.
    public func setObject<T: Hashable>(_ object: Any, forKey key: T, withTTL: UInt?=nil) {
        let ttl = withTTL ?? defaultTTL

        queue.sync(flags: [.barrier]) {
            setCacheObject(object, forKey: key, withTTL: ttl)
        }
    }
    
    private func getCacheObject<T: Hashable>(forKey key: T) -> Any? {
        if let cacheObject = cache[AnyKey(key)], !cacheObject.expired() {
            statistics.hits += 1
            return cacheObject.data
        }
        else {
            statistics.misses += 1
            return nil
        }
    }
    
    /// Retrieve an object from the cache.
    ///
    /// - Parameter forKey: The key of the entry to retrieve.
    /// - Returns: The object stored in the cache for the key.
    public func object<T: Hashable>(forKey key: T) -> Any? {
        var object : Any?
        queue.sync() {
            object = getCacheObject(forKey: key)
        }
        return object
    }
    
    /// Remove an object from the cache.
    ///
    /// - Parameter forKey: The key of the entry to remove.
    public func removeObject<T: Hashable>(forKey key: T) {
        removeObjects(forKeys: [key])
    }
    
    /// Remove objects from the cache.
    ///
    /// - Parameter forKeys: The keys of the entries to remove.
    public func removeObjects<T: Hashable>(forKeys keys: T...) {
        removeObjects(forKeys: keys)
    }
    
    /// Remove objects from the cache.
    ///
    /// - Parameter forKeys: An array of the keys of the entries to remove.
    public func removeObjects<T: Hashable>(forKeys keys: [T]) {
        queue.sync(flags: [.barrier]) {
            removeCacheObjects(forKeys: keys)
        }
    }

    private func removeCacheObjects<T: Hashable>(forKeys keys: [T]) {
        for key in keys {
            if let _ = cache.removeValue(forKey: AnyKey(key)) {
                statistics.numberOfKeys -= 1
            }
        }
    }
    
    /// Remove all objects from the cache.
    public func removeAllObjects() {
        queue.sync(flags: [.barrier]) {
            removeAllCacheObjects()
        }
    }
    
    private func removeAllCacheObjects() {
        self.cache.removeAll()
        self.statistics.numberOfKeys = 0
    }
    
    /// Set the Time to Live value for the cache entry.
    ///
    /// - Parameter ttl: The Time to Live value in seconds.
    /// - Parameter forKey: The key of the entry.
    /// - Returns: True if the TTL was successfully set, and false if the key doesn't exist.
    public func setTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        var success = false
        queue.sync(flags: [.barrier]) {
            success = setCacheObjectTTL(ttl, forKey: key)
        }
        return success
    }
    
    private func setCacheObjectTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        if let cacheObject = cache[AnyKey(key)], !cacheObject.expired() {
            cacheObject.setTTL(ttl)
            return true
        }
        return false
    }

    /// Get the cache keys.
    ///
    /// - Returns: An array of the cache keys.
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
            keys.append(key.key)
        }
        return keys
    }
    
    /// Remove all cache entries and reset the statisics.
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
        timer!.scheduleRepeating(deadline: DispatchTime.now(), interval: Double(checkFrequency), leeway: DispatchTimeInterval.milliseconds(1))
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
        timer.scheduleRepeating(deadline: DispatchTime.now(), interval: Double(checkFrequency))
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
