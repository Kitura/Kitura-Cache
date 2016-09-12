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

/// The statistics of the cache.
public struct Statistics {
    
    /// The number of the cache hits.
    public internal(set) var hits = 0
    
    /// The number of the cache misses.
    public internal(set) var misses = 0
    
    /// The total number of keys in the cache.
    public internal(set) var numberOfKeys = 0
    
    mutating func reset() {
        hits = 0
        misses = 0
        numberOfKeys = 0
    }
}

