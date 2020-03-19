func sum(_ v: [Double]) -> Double {
    var total: Double = 0
    for x in v {
        total += x
    }
    return total
}

func sumSquared(_ v: [Double]) -> Double {
    var total: Double = 0
    for x in v {
        total += x * x
    }
    return total
}

func mean(_ v: [Double]) -> Double {
    if v.count == 0 {
        return 0
    } else {
        let invCount: Double = 1.0 / Double(v.count)
        return sum(v) * invCount
    }
}

func median(_ v: [Double]) -> Double {
    guard v.count >= 2 else { return mean(v) }

    // If we have odd number of elements, then
    // center element is the median.
    let sorted = v.sorted()
    let center = v.count / 2
    if v.count % 2 == 1 {
        return sorted[center]
    }

    // If have even number of elements we need
    // to return an average between two middle elements.
    let center2 = v.count / 2 - 1
    return (sorted[center] + sorted[center2]) / 2
}

func std(_ v: [Double]) -> Double {
    let count = Double(v.count)
    // Standard deviation is undefined for n = 0 or 1.
    guard count > 0 else { return 0 }
    guard count > 1 else { return 0 }

    let meanValue = mean(v)
    let avgSquares = sumSquared(v) * (1.0 / count)
    return (count / (count - 1) * (avgSquares - meanValue * meanValue)).squareRoot()
}
