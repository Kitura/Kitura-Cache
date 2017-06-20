/**
 * Copyright IBM Corporation 2016
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

import XCTest
import Foundation

@testable import KituraCache

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

class TestCache : XCTestCase {
    
    static var allTests : [(String, (TestCache) -> () throws -> Void)] {
        return [
           ("testBasic", testBasic),
           ("testTTL", testTTL),
        ]
    }
        
    struct Numbers {
        var one : Int
        var two : String
        var three : [String:[Int]]
    }
    
    let value1 =  Numbers(one: 1, two: "two", three: ["three":[1,2,3], "four":[1,2,3]])
    let value2 =  Numbers(one: 2, two: "twenty two", three: ["twenty three":[21,22,23], "twenty four":[1,2,3]])
    let value3 =  Numbers(one: 3, two: "thirty two", three: ["thirty three":[21,22,23], "thirty four":[1,2,3]])

    func testBasic() {
        let cache = KituraCache()
        cache.setObject(value1, forKey: "key1")
        cache.setObject(value2, forKey: "key2")
        cache.setObject(value3, forKey: "key3")
        
        XCTAssertEqual(cache.statistics.numberOfKeys, 3)

        var keys = cache.keys()
        XCTAssertEqual(keys.count, 3)
        
        let obj2 = cache.object(forKey: "key2")
        XCTAssertNotNil(obj2)
        let object2 = obj2 as! Numbers
        XCTAssertEqual(object2.one, value2.one)
        XCTAssertEqual(object2.two, value2.two)
        XCTAssertEqual(object2.three["twenty three"]!, value2.three["twenty three"]!)
        
        cache.removeObject(forKey: "key3")
        let object3 = cache.object(forKey: "key3")
        XCTAssertNil(object3)
        
        XCTAssertEqual(cache.statistics.numberOfKeys, 2)
        XCTAssertEqual(cache.statistics.hits, 1)
        XCTAssertEqual(cache.statistics.misses, 1)
        
        cache.removeObject(forKey: "key2")
        cache.setObject(value2, forKey: "key2")
        cache.removeObject(forKey: "key2")
        
        keys = cache.keys()
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0] as? String, "key1")
        
        cache.removeAllObjects()
        XCTAssertEqual(cache.statistics.numberOfKeys, 0)
        XCTAssertEqual(cache.statistics.hits, 1)
        XCTAssertEqual(cache.statistics.misses, 1)
        
        cache.setObject(value1, forKey: "key1")
        cache.flush()
        XCTAssertEqual(cache.statistics.numberOfKeys, 0)
        XCTAssertEqual(cache.statistics.hits, 0)
        XCTAssertEqual(cache.statistics.misses, 0)
    }
    
    func testTTL() {
        // Without this, the first call to sleep() below
        // sometimes returns immediately, causing the test to fail.
        usleep(500000)

        let cache = KituraCache(defaultTTL: 10, checkFrequency: 4)
        cache.setObject(value1, forKey: "key1")
        cache.setObject(value2, forKey: "key2")
        cache.setObject(value3, forKey: "key3")
        
        sleep(7)
        var keys = cache.keys()
        XCTAssertEqual(keys.count, 3)

        sleep(7)
        keys = cache.keys()
        XCTAssertEqual(keys.count, 0)
        
        cache.setObject(value1, forKey: "key1", withTTL: 100)
        cache.setObject(value2, forKey: "key2", withTTL: 2)
        cache.setObject(value3, forKey: "key3")

        sleep(7)
        keys = cache.keys()
        XCTAssertEqual(keys.count, 2)
        
        sleep(7)
        keys = cache.keys()
        XCTAssertEqual(keys.count, 1)
        
        sleep(7)
        keys = cache.keys()
        XCTAssertEqual(keys.count, 1)
    }
    
 }
