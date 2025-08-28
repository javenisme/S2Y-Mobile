import XCTest
@testable import HealthAssistantKit

final class PlannerTests: XCTestCase {
    func testPlansAverageHeartRate30Days() async throws {
        let planner = RuleBasedQueryPlanner()
        let intent = try await planner.plan(from: "What's my average heart rate in the last 30 days?")
        XCTAssertEqual(intent.metric, "heart_rate")
        XCTAssertEqual(intent.function, .mean)
        XCTAssertNotNil(intent.startISO8601)
        XCTAssertNotNil(intent.endISO8601)
    }
}

