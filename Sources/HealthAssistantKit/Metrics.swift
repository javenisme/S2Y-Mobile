import Foundation

public enum DefaultMetrics {
    public static let steps = Metric(identifier: "steps", unit: "count", defaultGranularity: "day")
    public static let heartRate = Metric(identifier: "heart_rate", unit: "count/min", defaultGranularity: "day")
    public static let restingHeartRate = Metric(identifier: "resting_heart_rate", unit: "count/min", defaultGranularity: "day")
    public static let sleepDuration = Metric(identifier: "sleep_duration", unit: "minute", defaultGranularity: "day")
    public static let activeEnergy = Metric(identifier: "active_energy", unit: "kcal", defaultGranularity: "day")
    public static let weight = Metric(identifier: "weight", unit: "kg", defaultGranularity: "day")

    public static func registerDefaults() async {
        await MetricDictionary.shared.register(steps)
        await MetricDictionary.shared.register(heartRate)
        await MetricDictionary.shared.register(restingHeartRate)
        await MetricDictionary.shared.register(sleepDuration)
        await MetricDictionary.shared.register(activeEnergy)
        await MetricDictionary.shared.register(weight)
    }
}

