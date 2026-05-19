// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 Kitura project contributors

import Foundation
import Testing

@testable import KituraCache

@Suite("KituraCache")
struct KituraCacheTests {
  private struct Numbers: Equatable {
    var one: Int
    var two: String
    var three: [String: [Int]]
  }

  private let value1 = Numbers(one: 1, two: "two", three: ["three": [1, 2, 3], "four": [1, 2, 3]])
  private let value2 = Numbers(one: 2, two: "twenty two", three: ["twenty three": [21, 22, 23], "twenty four": [1, 2, 3]])
  private let value3 = Numbers(one: 3, two: "thirty two", three: ["thirty three": [21, 22, 23], "thirty four": [1, 2, 3]])

  @Test
  func basicOperations() throws {
    let cache = KituraCache()
    cache.setObject(value1, forKey: "key1")
    cache.setObject(value2, forKey: "key2")
    cache.setObject(value3, forKey: "key3")

    #expect(cache.statistics.numberOfKeys == 3)

    var keys = cache.keys()
    #expect(keys.count == 3)

    let object2 = try #require(cache.object(forKey: "key2") as? Numbers)
    #expect(object2 == value2)

    cache.removeObject(forKey: "key3")
    #expect(cache.object(forKey: "key3") == nil)

    #expect(cache.statistics.numberOfKeys == 2)
    #expect(cache.statistics.hits == 1)
    #expect(cache.statistics.misses == 1)

    cache.removeObject(forKey: "key2")
    cache.setObject(value2, forKey: "key2")
    cache.removeObject(forKey: "key2")

    keys = cache.keys()
    #expect(keys.count == 1)
    #expect(keys[0] as? String == "key1")

    cache.removeAllObjects()
    #expect(cache.statistics.numberOfKeys == 0)
    #expect(cache.statistics.hits == 1)
    #expect(cache.statistics.misses == 1)

    cache.setObject(value1, forKey: "key1")
    cache.flush()
    #expect(cache.statistics.numberOfKeys == 0)
    #expect(cache.statistics.hits == 0)
    #expect(cache.statistics.misses == 0)
  }

  @Test(.timeLimit(.minutes(1)))
  func ttlExpiration() async {
    let cache = KituraCache(defaultTTL: 10, checkFrequency: 4)
    cache.setObject(value1, forKey: "key1")
    cache.setObject(value2, forKey: "key2")
    cache.setObject(value3, forKey: "key3")

    await wait(seconds: 7)
    var keys = cache.keys()
    #expect(keys.count == 3)

    await wait(seconds: 7)
    keys = cache.keys()
    #expect(keys.count == 0)

    cache.setObject(value1, forKey: "key1", withTTL: 100)
    cache.setObject(value2, forKey: "key2", withTTL: 2)
    cache.setObject(value3, forKey: "key3")

    await wait(seconds: 7)
    keys = cache.keys()
    #expect(keys.count == 2)

    await wait(seconds: 7)
    keys = cache.keys()
    #expect(keys.count == 1)

    await wait(seconds: 7)
    keys = cache.keys()
    #expect(keys.count == 1)
  }

  private func wait(seconds: UInt64) async {
    try? await Task.sleep(for: .seconds(seconds))
  }
}
