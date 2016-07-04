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

public class Cache {
    
    private var cache = [AnyKey:CacheObject]()
    private let defaultTTL: UInt
    private let checkPeriod: UInt
    public private(set) var statistics: Statistics
    
    private var timer: dispatch_source_t!
    private let timerQueue: dispatch_queue_t!
    private let queue: dispatch_queue_t!
    
    public init(defaultTTL: UInt = 0, checkPeriod: UInt = 600) {
        self.defaultTTL = defaultTTL
        self.checkPeriod = checkPeriod
        statistics = Statistics()
        queue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
        timerQueue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
        startDataChecks()
    }
    
    deinit {
        stopDataChecks()
    }
    
    public func setObject<T: Hashable>(_ object: Any, forKey key: T, withTTL: UInt?=nil) {
        let ttl = withTTL ?? defaultTTL
        
        dispatch_barrier_sync(queue) {
            if let cacheObject = self.cache[AnyKey(key)] {
                cacheObject.data = object
                cacheObject.setTTL(ttl)
            }
            else {
                self.cache[AnyKey(key)] = CacheObject(data: object, ttl: ttl)
                self.statistics.numberOfKeys += 1
            }
        }
    }
    
    public func object<T: Hashable>(forKey key: T) -> Any? {
        var object : Any?
        dispatch_sync(queue) {
            if let cacheObject = self.cache[AnyKey(key)] where !cacheObject.expired() {
                object = cacheObject.data
                self.statistics.hits += 1
            }
            else {
                self.statistics.misses += 1
            }
        }
        return object
    }
    
    public func removeObject<T: Hashable>(forKey key: T) {
        removeObjects(forKeys: [key])
    }
    
    public func removeObjects<T: Hashable>(forKeys keys: T...) {
        removeObjects(forKeys: keys)
    }
    
    public func removeObjects<T: Hashable>(forKeys keys: [T]) {
        dispatch_barrier_sync(queue) {
            for key in keys {
                if let _ = self.cache.removeValue(forKey: AnyKey(key)) {
                    self.statistics.numberOfKeys -= 1
                }
            }
        }
    }
    
    public func removeAllObjects() {
        dispatch_barrier_sync(queue) {
            self.cache.removeAll()
            self.statistics.numberOfKeys = 0
        }
    }
    
    public func setTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool {
        var success = false
        dispatch_barrier_sync(queue) {
            if let cacheObject = self.cache[AnyKey(key)] where !cacheObject.expired() {
                cacheObject.setTTL(ttl)
                success = true
            }
        }
        return success
    }
    
    public func keys() -> [Any]? {
        var keys = [Any]()
        dispatch_sync(queue) {
            for key in self.cache.keys {
                keys.append(key.key)
            }            
        }
        return keys
    }
    
    public func flush() {
        dispatch_barrier_sync(queue) {
            self.cache.removeAll()
            self.statistics.reset()
        }
    }
    
    private func startDataChecks() {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(checkPeriod) * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
        dispatch_source_set_event_handler(timer) {
            dispatch_barrier_sync(self.queue) {
                for (key, cacheObject) in self.cache {
                    if cacheObject.expired() {
                        if let _ = self.cache.removeValue(forKey: key) {
                            self.statistics.numberOfKeys -= 1
                        }
                    }
                }
            }
        }
        dispatch_resume(timer)
    }
    
    private func restartDataChecks() {
        dispatch_suspend(timer)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(checkPeriod) * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
        dispatch_resume(timer)
    }
    
    private func stopDataChecks() {
        dispatch_source_cancel(timer)
        timer = nil
    }
}