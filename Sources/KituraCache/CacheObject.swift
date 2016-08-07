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

class CacheObject {
    var data : Any
    var expirationDate : Date
    
    init(data: Any, ttl: UInt) {
        self.data = data
        expirationDate = CacheObject.expirationDate(fromTTL: ttl)
    }
    
    func expired() -> Bool {
        return expirationDate.timeIntervalSinceNow < 0
    }
    
    func setTTL(_ ttl: UInt) {
        expirationDate = CacheObject.expirationDate(fromTTL: ttl)
    }
    
    class func expirationDate(fromTTL ttl: UInt) -> Date {
        return ttl == 0 ? Date.distantFuture : Date().addingTimeInterval(TimeInterval(ttl))
    }
}
