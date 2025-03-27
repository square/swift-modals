import Foundation

extension Comparable {
    /// Returns this value or `value`, whichever is lesser
    public func upperBounded(by value: Self) -> Self {
        min(self, value)
    }

    /// Returns this value or `value`, whichever is greater
    public func lowerBounded(by value: Self) -> Self {
        max(self, value)
    }

    /// Returns this value clamped between `a` and `b`. The order of the parameters does not
    /// matter.
    public func clampedBetween(_ a: Self, _ b: Self) -> Self {
        let lowerBound = min(a, b)
        let upperBound = max(a, b)
        return min(max(self, lowerBound), upperBound)
    }
}
