import Foundation

public final class RuleBasedQueryPlanner: QueryPlanner {
    private let iso8601 = ISO8601DateFormatter()

    public init() {}

    public func plan(from naturalLanguage: String) async throws -> QueryIntent {
        let lower = naturalLanguage.lowercased()
        let metric: String
        if lower.contains("heart") || lower.contains("心率") {
            metric = "heart_rate"
        } else if lower.contains("step") || lower.contains("步") {
            metric = "steps"
        } else if lower.contains("sleep") || lower.contains("睡") {
            metric = "sleep_duration"
        } else if lower.contains("energy") || lower.contains("能量") {
            metric = "active_energy"
        } else {
            metric = "steps"
        }

        let function: AggregationFunction? = lower.contains("average") || lower.contains("平均") ? .mean : nil

        let now = Date()
        let start: Date
        if lower.contains("30") && lower.contains("day") || lower.contains("30 天") {
            start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        } else if lower.contains("7") && (lower.contains("day") || lower.contains("天")) {
            start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        } else if lower.contains("week") || lower.contains("周") {
            start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        } else {
            start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        }

        return QueryIntent(
            metric: metric,
            function: function,
            startISO8601: iso8601.string(from: start),
            endISO8601: iso8601.string(from: now)
        )
    }
}

