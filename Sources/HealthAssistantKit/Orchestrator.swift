import Foundation

public final class Orchestrator: LLMOrchestrating {
    private let reader: HealthDataReader
    private let insight = InsightEngine()

    public init(reader: HealthDataReader) {
        self.reader = reader
    }

    public func execute(intent: QueryIntent) async throws -> String {
        let formatter = ISO8601DateFormatter()
        let start = formatter.date(from: intent.startISO8601 ?? "") ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let end = formatter.date(from: intent.endISO8601 ?? "") ?? Date()
        let window = TimeWindow(start: start, end: end)
        let series = try await reader.read(metric: intent.metric, window: window, granularity: .day)
        let summary = insight.summarize(values: series, function: intent.function)
        return summary
    }
}

