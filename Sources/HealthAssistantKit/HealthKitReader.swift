import Foundation

public enum HealthKitError: Error {
    case notAvailableOnThisPlatform
}

public final class UnavailableHealthKitReader: HealthDataReader {
    public init() {}
    public func read(metric: String, window: TimeWindow, granularity: Calendar.Component) async throws -> [(Date, Double)] {
        throw HealthKitError.notAvailableOnThisPlatform
    }
}

#if canImport(HealthKit) && !os(macOS) && !os(tvOS) && !os(watchOS)
import HealthKit

public final class HealthKitReader: HealthDataReader {
    private let healthStore = HKHealthStore()
    public init() {}

    public func requestAuthorization() async throws {
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 }
        try await healthStore.requestAuthorization(toShare: [], read: types)
    }

    public func read(metric: String, window: TimeWindow, granularity: Calendar.Component) async throws -> [(Date, Double)] {
        // Stub: return empty for now; real implementation will query HKStatisticsCollection
        return []
    }
}
#endif

