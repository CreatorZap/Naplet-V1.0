import Foundation
import SwiftUI

// MARK: - Sleep Location
/// Onde o bebê dormiu
enum SleepLocation: String, Codable, CaseIterable, Identifiable {
    case crib = "crib"
    case breastfeeding = "breastfeeding"
    case arms = "arms"
    case coSleep = "co_sleep"
    case bottle = "bottle"
    case stroller = "stroller"
    case car = "car"
    case swing = "swing"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .crib:
            return "sleep_location_crib".localized
        case .breastfeeding:
            return "sleep_location_breastfeeding".localized
        case .arms:
            return "sleep_location_arms".localized
        case .coSleep:
            return "sleep_location_co_sleep".localized
        case .bottle:
            return "sleep_location_bottle".localized
        case .stroller:
            return "sleep_location_stroller".localized
        case .car:
            return "sleep_location_car".localized
        case .swing:
            return "sleep_location_swing".localized
        }
    }

    var icon: String {
        switch self {
        case .crib: return "bed.double.fill"
        case .breastfeeding: return "figure.2.arms.open"
        case .arms: return "figure.arms.open"
        case .coSleep: return "person.2.fill"
        case .bottle: return "waterbottle.fill"
        case .stroller: return "stroller.fill"
        case .car: return "car.fill"
        case .swing: return "figure.child.and.lock.fill"
        }
    }

    var color: Color {
        switch self {
        case .crib: return .blue
        case .breastfeeding: return .pink
        case .arms: return .orange
        case .coSleep: return .purple
        case .bottle: return .cyan
        case .stroller: return .green
        case .car: return .gray
        case .swing: return .yellow
        }
    }
}

// MARK: - Sleep Start Mood
/// Como o bebê estava ao começar a dormir
enum SleepStartMood: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case fussy = "fussy"
    case tookLong = "took_long"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:
            return "sleep_start_easy".localized
        case .fussy:
            return "sleep_start_fussy".localized
        case .tookLong:
            return "sleep_start_took_long".localized
        }
    }

    var icon: String {
        switch self {
        case .easy: return "moon.zzz.fill"
        case .fussy: return "exclamationmark.triangle.fill"
        case .tookLong: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .fussy: return .orange
        case .tookLong: return .yellow
        }
    }
}

// MARK: - Wake Type
/// Como o bebê acordou
enum WakeType: String, Codable, CaseIterable, Identifiable {
    case natural = "natural"
    case wokenUp = "woken_up"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .natural:
            return "wake_type_natural".localized
        case .wokenUp:
            return "wake_type_woken_up".localized
        }
    }

    var icon: String {
        switch self {
        case .natural: return "sunrise.fill"
        case .wokenUp: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .natural: return .yellow
        case .wokenUp: return .blue
        }
    }
}

// MARK: - Wake Mood
/// Humor do bebê ao acordar
enum WakeMood: String, Codable, CaseIterable, Identifiable {
    case happy = "happy"
    case neutral = "neutral"
    case cranky = "cranky"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .happy:
            return "wake_mood_happy".localized
        case .neutral:
            return "wake_mood_neutral".localized
        case .cranky:
            return "wake_mood_cranky".localized
        }
    }

    var icon: String {
        switch self {
        case .happy: return "heart.fill"
        case .neutral: return "hand.thumbsup.fill"
        case .cranky: return "cloud.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .happy: return .green
        case .neutral: return .gray
        case .cranky: return .red
        }
    }
}
