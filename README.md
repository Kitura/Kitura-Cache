<p align="center">
    <a href="https://www.kitura.dev/">
        <img src="https://raw.githubusercontent.com/Kitura/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://github.com/Kitura/Kitura-Cache/actions/workflows/ci.yml">
    <img src="https://github.com/Kitura/Kitura-Cache/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI">
    </a>
    <img src="https://img.shields.io/badge/Swift-6.0%2B-orange.svg?style=flat" alt="Swift 6.0+">
    <img src="https://img.shields.io/badge/platforms-Apple%20%7C%20Linux%20%7C%20Android%20%7C%20Wasm-green.svg?style=flat" alt="Apple, Linux, Android, and Wasm">
    <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat" alt="Apache 2.0">
    </a>
</p>

# KituraCache

`KituraCache` is an in-memory, thread-safe cache which allows you to store objects against a unique, [Hashable](https://developer.apple.com/documentation/swift/hashable) key.

## Requirements

KituraCache requires **Swift 6.0** or newer. Install Swift from [Swift.org](https://www.swift.org/install/). Compatibility with older Swift versions is not guaranteed.

CI validates Linux and macOS with Swift Testing, builds the Apple platforms declared in `Package.swift`, builds API documentation with Swift-DocC, and compile-checks Android and Wasm with the official Swift SDK bundles.

## Usage

#### Add dependencies

Add the `Kitura-Cache` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-Cache` [release](https://github.com/Kitura/Kitura-Cache/releases).

```swift
.package(url: "https://github.com/Kitura/Kitura-Cache.git", from: "x.x.x")
```

Add `KituraCache` to your target's dependencies:

```swift
.target(
    name: "Example",
    dependencies: [
        .product(name: "KituraCache", package: "Kitura-Cache")
    ]
)
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
If no arguments are provided, the default cache will be non-expiring and a check will be made every minute to determine whether any entries need to be removed.


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

Use [Kitura GitHub Discussions](https://github.com/orgs/Kitura/discussions) for project-wide coordination and [KituraCache issues](https://github.com/Kitura/Kitura-Cache/issues) for package-specific bugs or feature requests.

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
