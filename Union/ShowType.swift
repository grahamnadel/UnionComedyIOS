import Foundation
import SwiftUI

// MARK: - Enum for show types (no associated value)
enum ShowType: String, CaseIterable, Identifiable {
    case fridayNightFusion
    case fridayWeekendShow
    case saturdayWeekendShow
    case pickle
    case cageMatch
    case classShow
    case special

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fridayNightFusion: return "Friday Night Fusion"
        case .fridayWeekendShow: return "Friday Weekend Show"
        case .saturdayWeekendShow: return "Saturday Weekend Show"
        case .pickle: return "Pickle"
        case .cageMatch: return "Cage Match"
        case .classShow: return "Class Show"
        case .special: return "Special"
        }
    }

    var weekday: String? {
        switch self {
        case .fridayNightFusion, .fridayWeekendShow: return "Friday"
        case .saturdayWeekendShow, .pickle: return "Saturday"
        case .cageMatch: return "Sunday"
        case .special, .classShow: return nil
        }
    }

    var defaultTime: (hour: Int, minute: Int)? {
        switch self {
        case .fridayNightFusion: return (21, 0)
        case .fridayWeekendShow: return (19, 30)
        case .saturdayWeekendShow: return (19, 30)
        case .pickle: return (21, 0)
        case .cageMatch: return (19, 0)
        case .special, .classShow: return nil
        }
    }
    
    var requiredTeamCount: Int? {
        switch self {
        case .fridayNightFusion: return 2
        case .fridayWeekendShow: return 2
        case .saturdayWeekendShow: return 2
        case .pickle: return 1
        case .cageMatch: return 2
        case .special, .classShow: return nil
        }
    }
    
    static func dateToShow(date: Date) -> ShowType? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        
        let weekdayName = calendar.weekdaySymbols[(components.weekday ?? 1) - 1]
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        for showType in ShowType.allCases {
            if let showTime = showType.defaultTime {
                if showTime == (hour, minute) && showType.weekday == weekdayName {
                    return showType
                }
            }
        }
        
        return nil // or .custom if you prefer
    }

}
