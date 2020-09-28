<p align="center">
    <a href="http://kitura.dev/">
        <img src="https://raw.githubusercontent.com/Kitura/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://kitura.github.io/Kitura-Cache/index.html">
    <img src="https://img.shields.io/badge/apidoc-KituraCache-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/Kitura/Kitura-Cache">
    <img src="https://travis-ci.org/Kitura/Kitura-Cache.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# KituraCache

`KituraCache` is an in-memory, thread-safe cache which allows you to store objects against a unique, [Hashable](https://developer.apple.com/documentation/swift/hashable) key.

## Swift version
The latest version of KituraCache requires **Swift 4.0** but recommends using **4.1.2** or newer. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

#### Add dependencies

Add the `Kitura-Cache` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-Cache` [release](https://github.com/Kitura/Kitura-Cache/releases).

```swift
.package(url: "https://github.com/Kitura/Kitura-Cache.git", from: "x.x.x")
```

Add `KituraCache` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["KituraCache"]),
```

#### Import package

```swift
import KituraCache
```

## Example

**To use KituraCache, add the dependencies and import the package as defined above, then initialize:**
```swift
let cache = KituraCache()
```
If no arguments are provided, the default cache will be non-expiring and a check will be made every 10 minutes to determine whether any entries need to be removed.


**To add an entry to the cache, or update an entry if the key already exists:**

In the following examples, item is a `struct` with an integer id field.
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

## API Documentation
For more information visit our [API reference](https://kitura.github.io/Kitura-Cache/index.html).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/Kitura/Kitura-Cache/blob/master/LICENSE.txt).
