# Kitura-Cache
Kitura cache

[![Build Status - Master](https://travis-ci.org/IBM-Swift/Kitura.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-Cache)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
Kitura thread-safe in-memory cache.

## API
### Initialization:

```swift
  public init(defaultTTL: UInt = 0, checkFrequency: UInt = 600)
```
**Where:**
   - *defaultTTL* is the default Time To Live (TTL) of cache entries in seconds, its default value is 0, which means infinity

   - *checkFrequency* defines the frequency in seconds of checks for expired entries

### Add
```swift
public func setObject<T: Hashable>(_ object: Any, forKey key: T, withTTL: UInt?=nil) {
```
 - *key* has to be *Hashable*
 - if TTL is not specified, cache's *defaultTTL* is used for the entry

### Get
```swift
  public func object<T: Hashable>(forKey key: T) -> Any?
```

### Delete
```swift
public func removeObject<T: Hashable>(forKey key: T)
public func removeObjects<T: Hashable>(forKeys keys: T...)
public func removeObjects<T: Hashable>(forKeys keys: [T])
public func removeAllObjects()
```

### Set TTL
```swift
public func setTTL<T: Hashable>(_ ttl: UInt, forKey key: T) -> Bool
```
- returns *false* if *key* doesn't exits

### Retrieve all keys

```swift
public func keys() -> [Any]?
```

### Flush
Removes all values and resets the statistics
```swift
public func flush()
```

### Statistics
Cache statistics are stored in
```swift
public private(set) var statistics: Statistics
```
**Statistics struct contains:**
   - *hits* the number of cache hits
   - *misses* the number of cache misses
   - *numberOfKeys* the total number of keys in the cache

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
