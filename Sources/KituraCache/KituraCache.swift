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

/// A thread-safe, in-memory cache for storing an object with a Hashable key. Time To Live can be specified per entry, or will take a default value specified when the cache is initialised.
public class KituraCache {
    
    private var cache = [AnyKey:CacheObject]()
    private let defaultTTL: UInt
    private let checkFrequency: UInt
    
    /// The `Statistics` of the cache.
    public private(set) var statistics: Statistics

    private var timer: DispatchSourceTimer?
    private let timerQueue: DispatchQueue
    private let queue: DispatchQueue
    
    /**
     Initialize an instance of KituraCache.
     ### Usage Example: ###
     ````swift
     let cache = KituraCache(defaultTTL: 3600, checkFrequency: 600)
     ````
     - Parameter defaultTTL: The default Time to Live value (in seconds). Used for cache entries for which the TTL is not specified otherwise. If it is not specified here, the default value is 0 which maps to infinity.
     - Parameter checkFrequency: The frequency (in seconds) to check for expired entries. If it is not specified here, the default value is 600 (10 minutes).
     */
    
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
    
    //MARK: Adding objects to the cache.
    
    /**
     Set the cache object. Adds a new entry or updates the data if the key already exists in the cache.
     ### Usage Example: ###
     ````swift
     //In this case, item is an instance of a struct object with an id field which conforms to Hashable.
     let cache = KituraCache()
     ...
     cache.setObject(item, forKey: item.id)
     ````
     - Parameter object: The data object.
     - Parameter forKey: The Hashable key for the data.
     - Parameter withTTL: The optional Time to Live value (in seconds) for the entry. If not specified,
                          the default TTL is used.
     */
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
    
    //MARK: Retrieving objects from the cache.
    
    /**
     Retrieve an object from the cache for a specified key.
     ### Usage Example: ###
     ````swift
     //In this case, item has been stored in the cache with an Int key
     let cache = KituraCache()
     ...
     if let item = cache.object(forKey: 1) {
         //Object with key of 1 retrieved from cache.
         ...
     }
     else {
         //No object stored in cache with key of 1.
         ...
     }
     ````
     - Parameter forKey: The key of the entry to retrieve from the cache.
     - Returns: The object stored in the cache for the specified key.
     - Note: The return value will be nil if there is no object in the cache with the specified key.
     */
    public func object<T: Hashable>(forKey key: T) -> Any? {
        var object : Any?
        queue.sync() {
            object = getCacheObject(forKey: key)
        }
        return object
    }
    
    /**
     Get all of the keys in the cache.
     ### Usage Example: ###
     ````swift
     let cache = KituraCache()
     ...
     let allKeys = cache.keys()
     ````
     - Returns: An array of the cache keys.
     */
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
    
    //MARK: Removing objects from the cache.
    
    /**
     Remove an object from the cache for a specified key.
     ### Usage Example: ###
     ````swift
     //In this case, objects have been stored in the cache with an Int key
     let cache = KituraCache()
     ...
     cache.removeObject(forKey: 1)
     ````
     - Parameter forKey: The key of the entry to remove from the cache.
     */
    public func removeObject<T: Hashable>(forKey key: T) {
        removeObjects(forKeys: [key])
    }
    
    /**
     Remove objects from the cache for multiple, specified keys.
     ### Usage Example: ###
     ````swift
     //In this case, objects have been stored in the cache with an Int key
     let cache = KituraCache()
     ...
     cache.removeObjects(forKeys: 1, 2, 3)
     ````
     - Parameter forKeys: The keys of the entries to remove.
     */
    public func removeObjects<T: Hashable>(forKeys keys: T...) {
        removeObjects(forKeys: keys)
    }
    
    /**
     Remove objects from the cache for multiple, specified keys provided in an array.
     ### Usage Example: ###
     ````swift
     //In this case, objects have been stored in the cache with an Int key
     let cache = KituraCache()
     ...
     cache.removeObjects(forKeys: [1, 2, 3])
     ````
     - Parameter forKeys: An array of keys of the entries to remove.
     */
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
    
    /**
     Remove all objects from the cache.
     ### Usage Example: ###
     ````swift
     let cache = KituraCache()
     ...
     cache.removAlleObjects()
     ````
     */
    public func removeAllObjects() {
        queue.sync(flags: [.barrier]) {
            removeAllCacheObjects()
        }
    }
    
    private func removeAllCacheObjects() {
        self.cache.removeAll()
        self.statistics.numberOfKeys = 0
    }
    
    //MARK: Changing TTL for an entry.
    
    /**
     Set the Time to Live value (in seconds) for a cache entry.
     ### Usage Example: ###
     ````swift
     //In this case, objects have been stored in the cache with an Int key
     let cache = KituraCache()
     ...
     cache.setTTL(ttl: 360, forKey: 1)
     ````
     - Parameter ttl: The Time to Live value in seconds.
     - Parameter forKey: The key specifying which entry to set the TTL.
     - Returns: True if the TTL was set successfully. False if the key doesn't exist.
     */
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
    
    //MARK: Resetting the cache.
    
    /**
     Remove all cache entries and reset the cache statistics.
     ### Usage Example: ###
     ````swift
     let cache = KituraCache()
     ...
     cache.flush()
     ````
     */
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
