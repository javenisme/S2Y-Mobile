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
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 }
        try await healthStore.requestAuthorization(toShare: [], read: types)
    }

    public func read(metric: String, window: TimeWindow, granularity: Calendar.Component) async throws -> [(Date, Double)] {
        if metric == "sleep_duration" {
            return try await readSleep(window: window)
        } else {
            return try await readQuantity(metric: metric, window: window)
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func enumerateDays(from start: Date, to end: Date) -> [Date] {
        var days: [Date] = []
        var current = startOfDay(start)
        let endDay = startOfDay(end)
        while current <= endDay {
            days.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return days
    }

    private func typeForMetric(_ metric: String) -> (HKSampleType, HKStatisticsOptions?, HKUnit?)? {
        switch metric {
        case "steps":
            return (HKObjectType.quantityType(forIdentifier: .stepCount)!, .cumulativeSum, HKUnit.count())
        case "heart_rate":
            return (HKObjectType.quantityType(forIdentifier: .heartRate)!, .discreteAverage, HKUnit.count().unitDivided(by: .minute()))
        case "resting_heart_rate":
            return (HKObjectType.quantityType(forIdentifier: .restingHeartRate)!, .discreteAverage, HKUnit.count().unitDivided(by: .minute()))
        case "active_energy":
            return (HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, .cumulativeSum, HKUnit.kilocalorie())
        case "weight":
            return (HKObjectType.quantityType(forIdentifier: .bodyMass)!, .discreteAverage, HKUnit.gramUnit(with: .kilo))
        default:
            return nil
        }
    }

    private func readQuantity(metric: String, window: TimeWindow) async throws -> [(Date, Double)] {
        guard let (sampleType, options, unit) = typeForMetric(metric), let quantityType = sampleType as? HKQuantityType, let options else {
            return []
        }
        let anchor = startOfDay(window.start)
        var interval = DateComponents()
        interval.day = 1
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end, options: [.strictStartDate, .strictEndDate])
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options, anchorDate: anchor, intervalComponents: interval)
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let days = self.enumerateDays(from: window.start, to: window.end)
                var valuesByDay: [Date: Double] = [:]
                results?.enumerateStatistics(from: self.startOfDay(window.start), to: self.startOfDay(window.end)) { statistics, _ in
                    let dayStart = self.startOfDay(statistics.startDate)
                    var value: Double = 0
                    if options.contains(.cumulativeSum), let sum = statistics.sumQuantity() {
                        value = sum.doubleValue(for: unit)
                    } else if options.contains(.discreteAverage), let avg = statistics.averageQuantity() {
                        value = avg.doubleValue(for: unit)
                    }
                    valuesByDay[dayStart] = value
                }
                let series = days.map { day in (day, valuesByDay[day] ?? 0) }
                continuation.resume(returning: series)
            }
            self.healthStore.execute(query)
        }
    }

    private func readSleep(window: TimeWindow) async throws -> [(Date, Double)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end, options: [.strictStartDate, .strictEndDate])
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let days = self.enumerateDays(from: window.start, to: window.end)
                var totals: [Date: Double] = [:]
                for sample in samples ?? [] {
                    guard let cat = sample as? HKCategorySample else { continue }
                    let dayStart = self.startOfDay(cat.startDate)
                    let duration = cat.endDate.timeIntervalSince(cat.startDate) / 60.0
                    totals[dayStart, default: 0] += duration
                }
                let series = days.map { day in (day, totals[day] ?? 0) }
                continuation.resume(returning: series)
            }
            self.healthStore.execute(query)
        }
    }
}
#endif

