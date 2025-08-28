import Foundation
import HealthAssistantKit

final class MockReader: HealthDataReader {
    func read(metric: String, window: TimeWindow, granularity: Calendar.Component) async throws -> [(Date, Double)] {
        // Generate a simple ramp series for demo
        var values: [(Date, Double)] = []
        var date = window.start
        var i = 0.0
        while date <= window.end {
            values.append((date, i))
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            i += 1
        }
        return values
    }
}

let planner = RuleBasedQueryPlanner()
let reader = MockReader()
let orchestrator = Orchestrator(reader: reader)

let question = CommandLine.arguments.dropFirst().joined(separator: " ")
let nl = question.isEmpty ? "What's my average heart rate in the last 7 days?" : question

Task {
    let intent = try await planner.plan(from: nl)
    let answer = try await orchestrator.execute(intent: intent)
    print("Q:\n\(nl)\n\nA:\n\(answer)")
    exit(0)
}

RunLoop.current.run()
