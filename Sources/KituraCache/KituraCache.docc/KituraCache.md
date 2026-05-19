# ``KituraCache``

Store values in an in-memory, thread-safe cache with optional time-based expiration.

## Overview

`KituraCache` provides a small in-process cache for Swift applications. Values are stored under any `Hashable` key and can either live until removed or expire after a configured time-to-live.

Create a non-expiring cache:

```swift
let cache = KituraCache()
```

Create a cache whose entries expire by default:

```swift
let cache = KituraCache(defaultTTL: 3600, checkFrequency: 600)
```

Store and retrieve values:

```swift
cache.setObject(user, forKey: user.id)

if let user = cache.object(forKey: userID) as? User {
  // Use the cached value.
}
```

Use `Statistics` to inspect cache hits, misses, and the current number of stored keys.

## Topics

### Creating a Cache

- ``KituraCache/init(defaultTTL:checkFrequency:)``

### Storing and Retrieving Values

- ``KituraCache/setObject(_:forKey:withTTL:)``
- ``KituraCache/object(forKey:)``
- ``KituraCache/keys()``
- ``KituraCache/setTTL(_:forKey:)``

### Removing Values

- ``KituraCache/removeObject(forKey:)``
- ``KituraCache/removeObjects(forKeys:)-(T...)``
- ``KituraCache/removeObjects(forKeys:)-([T])``
- ``KituraCache/removeAllObjects()``
- ``KituraCache/flush()``

### Inspecting Cache State

- ``KituraCache/statistics``
- ``Statistics``
- ``Statistics/hits``
- ``Statistics/misses``
- ``Statistics/numberOfKeys``
