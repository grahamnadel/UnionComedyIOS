import Foundation
import SwiftUI

// MARK: - Enum for show types (no associated value)
enum ShowType: String, CaseIterable, Identifiable {
    case fridayNightFusion
    case fridayWeekendShow
    case saturdayWeekendShow
    case pickle
    case cageMatch
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fridayNightFusion: return "Friday Night Fusion"
        case .fridayWeekendShow: return "Friday Weekend Show"
        case .saturdayWeekendShow: return "Saturday Weekend Show"
        case .pickle: return "Pickle"
        case .cageMatch: return "Cage Match"
        case .custom: return "Custom"
        }
    }

    var weekday: String? {
        switch self {
        case .fridayNightFusion, .fridayWeekendShow: return "Friday"
        case .saturdayWeekendShow, .pickle: return "Saturday"
        case .cageMatch: return "Sunday"
        case .custom: return nil
        }
    }

    var defaultTime: (hour: Int, minute: Int)? {
        switch self {
        case .fridayNightFusion: return (21, 30)
        case .fridayWeekendShow: return (19, 30)
        case .saturdayWeekendShow: return (19, 30)
        case .pickle: return (20, 0)
        case .cageMatch: return (19, 0)
        case .custom: return nil
        }
    }
}

// MARK: - Struct for a specific show occurrence
struct RegularTimes: Identifiable {
    let showType: ShowType
    let date: Date

    var id: String { "\(showType.rawValue)_\(date.timeIntervalSince1970)" }
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return "\(showType.displayName) – \(formatter.string(from: date))"
    }

    // Generate upcoming occurrences
    static func upcoming(for showType: ShowType, count: Int = 4) -> [RegularTimes] {
        guard let weekday = showType.weekday,
              let time = showType.defaultTime else { return [] }
        
        let dates = nextDay(day: weekday, count: count, hour: time.hour, minute: time.minute)
        return dates.map { RegularTimes(showType: showType, date: $0) }
    }

    // Helper function to calculate next dates
    private static func weekdayNumber(from day: String) -> Int? {
        switch day.lowercased() {
        case "sunday": return 1
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        default: return nil
        }
    }

    private static func nextDay(day: String, count: Int, hour: Int, minute: Int) -> [Date] {
        guard let weekday = weekdayNumber(from: day) else { return [] }

        var dates: [Date] = []
        let calendar = Calendar.current
        var date = Date()

        while dates.count < count {
            if let nextDate = calendar.nextDate(
                after: date,
                matching: DateComponents(hour: hour, minute: minute, weekday: weekday),
                matchingPolicy: .nextTime
            ) {
                dates.append(nextDate)
                date = nextDate.addingTimeInterval(1)
            }
        }
        return dates
    }
}
