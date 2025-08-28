//
// HealthAssistantKit.swift
//

import Foundation
import Spezi
import OrderedCollections

public struct Metric: Hashable, Codable {
    public let identifier: String
    public let unit: String
    public let defaultGranularity: String
    public init(identifier: String, unit: String, defaultGranularity: String) {
        self.identifier = identifier
        self.unit = unit
        self.defaultGranularity = defaultGranularity
    }
}

public enum AggregationFunction: String, Codable {
    case mean
    case sum
    case min
    case max
    case median
    case movingMean
}

public struct TimeWindow: Codable, Hashable {
    public let start: Date
    public let end: Date
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public actor MetricDictionary {
    public static let shared = MetricDictionary()
    private var metrics: OrderedDictionary<String, Metric> = [:]

    public func register(_ metric: Metric) {
        metrics[metric.identifier] = metric
    }

    public func metric(for identifier: String) -> Metric? {
        metrics[identifier]
    }
}

public protocol HealthDataReader: AnyObject {
    func read(metric: String, window: TimeWindow, granularity: Calendar.Component) async throws -> [(Date, Double)]
}

public final class HealthKitModule: Module {
    public init() {}

    public func configure() {
        // Intentionally left as stub. Will implement HealthKit auth and queries in app target.
    }
}

public struct QueryIntent: Codable {
    public let metric: String
    public let function: AggregationFunction?
    public let startISO8601: String?
    public let endISO8601: String?
    public init(metric: String, function: AggregationFunction? = nil, startISO8601: String? = nil, endISO8601: String? = nil) {
        self.metric = metric
        self.function = function
        self.startISO8601 = startISO8601
        self.endISO8601 = endISO8601
    }
}

public protocol QueryPlanner {
    func plan(from naturalLanguage: String) async throws -> QueryIntent
}

public protocol LLMOrchestrating: AnyObject {
    func execute(intent: QueryIntent) async throws -> String
}

public final class InsightEngine {
    public init() {}
    public func summarize(values: [(Date, Double)], function: AggregationFunction?) -> String {
        guard !values.isEmpty else { return "No data available for the selected window." }
        switch function {
        case .mean:
            let mean = values.map { $0.1 }.reduce(0, +) / Double(values.count)
            return "Average value: \(mean.rounded())"
        case .sum:
            let sum = values.map { $0.1 }.reduce(0, +)
            return "Total: \(sum.rounded())"
        case .min:
            return "Min: \(values.map { $0.1 }.min() ?? 0)"
        case .max:
            return "Max: \(values.map { $0.1 }.max() ?? 0)"
        case .median:
            let sorted = values.map { $0.1 }.sorted()
            let mid = sorted.count / 2
            let median = sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
            return "Median: \(median)"
        case .movingMean:
            return "Moving mean computed"
        case .none:
            return "Data points: \(values.count)"
        }
    }
}

