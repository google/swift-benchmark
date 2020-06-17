// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Statistics utility functions, ported from google/benchmark.

// TODO: consider making these generic over more Collection and Element types.
// For now, however, they are intentionally limited in scope.
extension Array where Element == Double {

    var sum: Double {
        var total: Double = 0
        for x in self {
            total += x
        }
        return total
    }

    var average: Double {
        return sum / Double(count)
    }

    var sumSquared: Double {
        var total: Double = 0
        for x in self {
            total += x * x
        }
        return total
    }

    var mean: Double {
        if count == 0 {
            return 0
        } else {
            let invCount: Double = 1.0 / Double(count)
            return sum * invCount
        }
    }

    var median: Double {
        guard count >= 2 else { return mean }

        // If we have odd number of elements, then
        // center element is the median.
        let s = self.sorted()
        let center = count / 2
        if count % 2 == 1 {
            return s[center]
        }

        // If have even number of elements we need
        // to return an average between two middle elements.
        let center2 = count / 2 - 1
        return (s[center] + s[center2]) / 2
    }

    var std: Double {
        let c = Double(count)
        // Standard deviation is undefined for n = 0 or 1.
        guard c > 0 else { return 0 }
        guard c > 1 else { return 0 }

        let meanValue = mean
        let avgSquares = sumSquared * (1.0 / c)
        return (c / (c - 1) * (avgSquares - meanValue * meanValue)).squareRoot()
    }

    func percentile(_ v: Double) -> Double {
        if v < 0 {
            fatalError("Percentile can not be negative.")
        }
        if v > 100 {
            fatalError("Percentile can not be more than 100.")
        }
        if count == 0 {
            return 0
        }
        let sorted = self.sorted()
        let p = v / 100.0
        let index = (Double(count) - 1) * p
        var low = index
        low.round(.down)
        var high = index
        high.round(.up)
        if low == high {
            return sorted[Int(low)]
        } else {
            let lowValue = sorted[Int(low)] * (high - index)
            let highValue = sorted[Int(high)] * (index - low)
            return lowValue + highValue
        }
    }
}
