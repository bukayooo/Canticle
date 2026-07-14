import SwiftUI
import UIKit

/// Crusader-inspired palette and typography, matched to the app icon: a gold-to-black gradient
/// with a red Templar cross pattée. The reading surface reads like vellum lit by candlelight in
/// dark mode, and aged parchment in light mode.
enum Theme {
    /// The red of the Templar cross in the app icon.
    static let crimson = Color(.displayP3, red: 0.80, green: 0.11, blue: 0.09)
    /// The gold from the icon's gradient.
    static let gold = Color(.displayP3, red: 0.729, green: 0.616, blue: 0.365)
    static let deepGold = Color(.displayP3, red: 0.55, green: 0.44, blue: 0.22)
    static let ink = Color(.displayP3, red: 0.09, green: 0.08, blue: 0.07)

    static var parchment: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(displayP3Red: 0.07, green: 0.065, blue: 0.06, alpha: 1)
                : UIColor(displayP3Red: 0.97, green: 0.945, blue: 0.87, alpha: 1)
        })
    }

    static var parchmentPanel: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(displayP3Red: 0.12, green: 0.105, blue: 0.09, alpha: 1)
                : UIColor(displayP3Red: 1.0, green: 0.985, blue: 0.94, alpha: 1)
        })
    }

    static var primaryText: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(displayP3Red: 0.93, green: 0.90, blue: 0.82, alpha: 1)
                : UIColor(displayP3Red: 0.14, green: 0.11, blue: 0.08, alpha: 1)
        })
    }

    static var secondaryText: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(displayP3Red: 0.70, green: 0.65, blue: 0.55, alpha: 1)
                : UIColor(displayP3Red: 0.40, green: 0.34, blue: 0.26, alpha: 1)
        })
    }

    static let backgroundGradient = LinearGradient(
        colors: [deepGold.opacity(0.35), .black],
        startPoint: .top,
        endPoint: UnitPoint(x: 0.5, y: 0.9)
    )
}

enum Typography {
    static let heading = Font.system(.title3, design: .serif).weight(.bold)
    static let canticleTitle = Font.system(.headline, design: .serif).italic()
    static let rubric = Font.system(.footnote, design: .serif).italic()
    static let body = Font.system(.body, design: .serif)
    static let versicle = Font.system(.body, design: .serif).weight(.semibold)
    static let reference = Font.system(.subheadline, design: .serif).weight(.bold)
    static let officeName = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let caption = Font.system(.caption, design: .serif)
}
