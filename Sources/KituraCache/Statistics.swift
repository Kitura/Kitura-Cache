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

// MARK Statistics

/// Statistics about the cache.
public struct Statistics {
    
    /** The total number of times an access attempt successfully retrieved an entry from the cache.
    ### Usage Example: ###
    ````swift
     let cache = KituraCache()
     ...
     let numHits = cache.statistics.hits
     ```
    */
    public internal(set) var hits = 0
    
    /** The total number of times an access attempt was unable to retrieve an entry in the cache.
    ### Usage Example: ###
    ````swift
    let cache = KituraCache()
    ...
    let numMisses = cache.statistics.misses
    ```
    */
    public internal(set) var misses = 0
    
    /** The total number of entries curently in the cache.
     ### Usage Example: ###
     ````swift
     let cache = KituraCache()
     ...
     let numKeys = cache.statistics.numberOfKeys
     ```
     */
    public internal(set) var numberOfKeys = 0
    
    mutating func reset() {
        hits = 0
        misses = 0
        numberOfKeys = 0
    }
}

