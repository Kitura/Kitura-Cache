[![Kitura](https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Documentation/KituraLogo-wide.png)](http://kitura.io/)

[![Docs](https://img.shields.io/badge/read%20our-docs-1FBCE4.svg)](http://www.kitura.io/en/api/)
[![Build Status - Master](https://travis-ci.org/IBM-Swift/Kitura-Cache.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-Cache)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)
[![Slack Status](http://swift-at-ibm-slack.mybluemix.net/badge.svg)](http://swift-at-ibm-slack.mybluemix.net/)
[![GitHub stars](https://img.shields.io/github/stars/IBM-Swift/Kitura.svg?style=social&label=Stars)](https://github.com/IBM-Swift/Kitura)

# KituraCache

`KituraCache` is an in-memory, thread-safe cache which allows you to store objects against a unique, [Hashable](https://developer.apple.com/documentation/swift/hashable) key.

**To use KituraCache, import the package and initialise:**
```swift
import KituraCache

let cache = KituraCache()
```
If no arguments are provided, the default cache will be non-expiring and a check will be made every 10 minutes to determine whether any entries need to be removed. To learn more about how to configure the cache further, refer to `KituraCache.init(...)`.


**To add an entry to the cache, or update an entry if the key already exists:**
```swift
cache.setObject(item, forKey: item.id)
```
In the above example, item is a struct and its id field conforms to Hashable.


**To retrieve an entry from the cache:**
```swift
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
```


**To delete a single entry, pass the entry's key as a parameter:**
```swift
cache.removeObject(forKey: 1)
```
In the above cases, entries have been stored in the cache with integer keys. To delete multiple entries at once, refer to `KituraCache`.


**To reset the cache and its `Statistics`:**
```swift
cache.flush()
```

Refer to `KituraCache` and  `Statistics` for more information about

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).

