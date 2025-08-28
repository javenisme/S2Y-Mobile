import Foundation

public enum AnalysisError: Error {
    case emptySeries
}

public struct Aggregators {
    public static func mean(_ series: [(Date, Double)]) throws -> Double {
        guard !series.isEmpty else { throw AnalysisError.emptySeries }
        return series.reduce(0.0) { $0 + $1.1 } / Double(series.count)
    }

    public static func sum(_ series: [(Date, Double)]) -> Double {
        series.reduce(0.0) { $0 + $1.1 }
    }
}

public struct Correlator {
    // Pearson correlation of paired day values (assumes aligned series)
    public static func pearson(_ x: [Double], _ y: [Double]) throws -> Double {
        precondition(x.count == y.count, "Series must be same length")
        guard !x.isEmpty else { throw AnalysisError.emptySeries }
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0, +)
        let sumYY = y.map { $0 * $0 }.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let numerator = n * sumXY - sumX * sumY
        let denom = sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY))
        if denom == 0 { return 0 }
        return numerator / denom
    }
}

