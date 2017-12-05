<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="http://www.kitura.io/">
    <img src="https://img.shields.io/badge/docs-kitura.io-1FBCE4.svg" alt="Docs">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Kitura-Cache">
    <img src="https://travis-ci.org/IBM-Swift/Kitura-Cache.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat" alt="Mac OS X">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# KituraCache

`KituraCache` is an in-memory, thread-safe cache which allows you to store objects against a unique, [Hashable](https://developer.apple.com/documentation/swift/hashable) key.

**To use KituraCache, import the package and initialise:**
```swift
import KituraCache

let cache = KituraCache()
```
If no arguments are provided, the default cache will be non-expiring and a check will be made every 10 minutes to determine whether any entries need to be removed.


**To add an entry to the cache, or update an entry if the key already exists:**

In the following examples, item is a`struct` with an integer id field.
```swift
cache.setObject(item, forKey: item.id)
```


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


**To reset the cache and its `Statistics`:**
```swift
cache.flush()
```

_Refer to [KituraCache](https://ibm-swift.github.io/Kitura-Cache/Classes/KituraCache) and [Statistics](https://ibm-swift.github.io/Kitura-Cache/Structs/Statistics) for more information and further configuration._

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).

