import Foundation

enum SolarSimulator {
    /// Deterministic pseudo-random solar radiation (W/m²) from hour/day — offline, no CoreLocation.
    static func radiation(for date: Date = Date()) -> Double {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let fractionalHour = Double(hour) + Double(minute) / 60.0

        let daySeed = UInt64(dayOfYear) &* 2654435761
        let hourSeed = UInt64(hour) &* 1597334677
        let mixed = daySeed &+ hourSeed &+ 0x9E3779B9
        let noise = Double(mixed % 1000) / 1000.0

        let dayFactor = 0.75 + 0.25 * sin((Double(dayOfYear) / 365.0) * 2 * .pi - .pi / 2)
        let solarCurve: Double
        if fractionalHour < 5.5 || fractionalHour > 20.5 {
            solarCurve = 0.02 + noise * 0.03
        } else {
            let normalized = (fractionalHour - 5.5) / 15.0
            solarCurve = max(0, sin(normalized * .pi))
        }

        let peak: Double = 1100
        let value = solarCurve * peak * dayFactor + noise * 80
        return (value * 10).rounded() / 10
    }

    static func reading(for date: Date = Date()) -> SolarReading {
        SolarReading(date: date, value: radiation(for: date))
    }
}
