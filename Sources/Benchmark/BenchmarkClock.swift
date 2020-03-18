import Dispatch

struct BenchmarkClock {
    var start: UInt64 = 0
    var end: UInt64 = 0

    private static func now() -> UInt64 {
        return DispatchTime.now().uptimeNanoseconds
    }

    @inlinable
    mutating func recordStart() {
        start = BenchmarkClock.now()
    }

    @inlinable
    mutating func recordEnd() {
        end = BenchmarkClock.now()
    }

    @inlinable
    var elapsed: UInt64 {
        return end - start
    }
}
