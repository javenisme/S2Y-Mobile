import XCTest
@testable import HealthAssistantKit

final class AnalysisTests: XCTestCase {
    func testMean() throws {
        let now = Date()
        let series = [
            (now, 1.0),
            (now.addingTimeInterval(60), 2.0),
            (now.addingTimeInterval(120), 3.0)
        ]
        let m = try Aggregators.mean(series)
        XCTAssertEqual(m, 2.0, accuracy: 1e-6)
    }

    func testPearson() throws {
        let r = try Correlator.pearson([1,2,3,4], [2,3,4,5])
        XCTAssertGreaterThan(r, 0.99)
    }
}

