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

public class KituraCache {
    
    private var cache = [AnyKey:CacheObject]()
    private let defaultTTL: UInt
    private let checkFrequency: UInt
    public private(set) var statistics: Statistics

    #if os(Linux)
    private var timer: dispatch_source_t!
    private let timerQueue: dispatch_queue_t!
    private let queue: dispatch_queue_t!
    #else
    private var timer: DispatchSourceTimer?
    private let timerQueue: DispatchQueue
    private let queue: DispatchQueue
    #endif
    
    public init(defaultTTL: UInt = 0, checkFrequency: UInt = 600) {
        self.defaultTTL = defaultTTL
        self.checkFrequency = checkFrequency
        statistics = Statistics()
        
        #if os(Linux)
            queue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
            timerQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL)
        #else
            queue =  DispatchQueue(label: "", attributes: [.concurrent])
            timerQueue =  DispatchQueue(label: "", attributes: [])
        #endif

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
    
    public func setObject<T: Hashable>(_ object: Any, forKey key: T, withTTL: UInt?=nil) {
        let ttl = withTTL ?? defaultTTL

        #if os(Linux)
            dispatch_barrier_sync(queue) {
                self.setCacheObject(object, forKey: key, withTTL: ttl)
            }
        #else
            queue.sync(flags: [.barrier]) {
                setCacheObject(object, forKey: key, withTTL: ttl)
            }
        #endif
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
    
    public func object<T: Hashable>(forKey key: T) -> Any? {
        var object : Any?
        #if os(Linux)
            dispatch_sync(queue) {
                object = self.getCacheObject(forKey: key)
            }
        #else
            queue.sync() {
                object = getCacheObject(forKey: key)
            }
        #endif
        return object
    }
    
    public func removeObject<T: Hashable>(forKey key: T) {
        removeObjects(forKeys: [key])
    }
    
    public func removeObjects<T: Hashable>(forKeys keys: T...) {
        removeObjects(forKeys: keys)
    }
    
    public func removeObjects<T: Hashable>(forKeys keys: [T]) {
        #if os(Linux)
            dispatch_barrier_sync(queue) {
                self.removeCacheObjects(forKeys: keys)
            }
        #else
            queue.sync(flags: [.barrier]) {
                removeCacheObjects(forKeys: keys)
            }
        #endif
    }

    private func removeCacheObjects<T: Hashable>(forKeys keys: [T]) {
        for key in keys {
            if let _ = cache.removeValue(forKey: AnyKey(key)) {
                statistics.numberOfKeys -= 1
            }
        }
    }
    
    public func removeAllObjects() {
        #if os(Linux)
            dispatch_barrier_sync(queue) {
                self.removeAllCacheObjects()
            }
        #else
            queue.sync(flags: [.barrier]) {
                removeAllCacheObjects()
            }
        #endif
    }
    
    private func removeAllCacheObjects() {
        self.cache.removeAll()
        self.statistics.numberOfKeys = 0
    }
    
    public func setTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        var success = false
        #if os(Linux)
            dispatch_barrier_sync(queue) {
                success = self.setCacheObjectTTL(ttl, forKey: key)
            }
        #else
            queue.sync(flags: [.barrier]) {
                success = setCacheObjectTTL(ttl, forKey: key)
            }
        #endif
        return success
    }
    
    private func setCacheObjectTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        if let cacheObject = cache[AnyKey(key)], !cacheObject.expired() {
            cacheObject.setTTL(ttl)
            return true
        }
        return false
    }

    
    public func keys() -> [Any] {
        var keys : [Any]?
        #if os(Linux)
            dispatch_sync(queue) {
                keys = self.cacheKeys()
            }
        #else
            queue.sync() {
                keys = cacheKeys()
            }
        #endif
        return keys!
    }
    
    private func cacheKeys() -> [Any] {
        var keys = [Any]()
        for key in self.cache.keys {
            keys.append(key.key)
        }
        return keys
    }
    
    public func flush() {
        #if os(Linux)
            dispatch_barrier_sync(queue) {
                self.flushCache()
            }
        #else
            queue.sync(flags: [.barrier]) {
                flushCache()
            }
        #endif
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
    
#if os(Linux)
    private func startDataChecks() {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(checkFrequency) * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
        dispatch_source_set_event_handler(timer) {
            dispatch_barrier_sync(self.queue) {
                self.check()
            }
        }
        dispatch_resume(timer)
    }
    
    private func restartDataChecks() {
        dispatch_suspend(timer)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(checkFrequency) * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
        dispatch_resume(timer)
    }
    
    private func stopDataChecks() {
        dispatch_source_cancel(timer)
        timer = nil
    }
#else
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
        timer.scheduleRepeating(deadline: DispatchTime.now(), interval: Double(UInt64(checkFrequency) * NSEC_PER_SEC))
        timer.resume()
    }
    
    private func stopDataChecks() {
        guard let _ = timer else {
            return
        }
        timer!.cancel()
        timer = nil
    }
#endif
}
