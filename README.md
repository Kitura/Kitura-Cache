<p align="center">
    <a href="http://kitura.dev/">
        <img src="https://raw.githubusercontent.com/Kitura/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://github.com/Kitura/Kitura-Cache/actions/workflows/ci.yml">
    <img src="https://github.com/Kitura/Kitura-Cache/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI">
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
The latest version of KituraCache requires **Swift 6.0** or newer. You can download Swift by following this [link](https://swift.org/download/). Compatibility with older Swift versions is not guaranteed.

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

## Documentation

KituraCache uses Swift-DocC for API documentation. Generate the documentation locally with:

```bash
swift package --allow-writing-to-directory .build generate-documentation --target KituraCache --output-path .build/KituraCache.doccarchive --warnings-as-errors
```

Preview it in a browser with:

```bash
swift package --disable-sandbox preview-documentation --target KituraCache
```

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/Kitura/Kitura-Cache/blob/master/LICENSE.txt).
