import SwiftUI

/// One of the app's alternate icons (Icon Composer `.icon` files registered in the target's
/// build settings). `iconName` is nil for the primary icon, matching
/// `UIApplication.setAlternateIconName(_:)`'s convention of nil meaning "reset to primary."
/// `previewImageName` points at a same-artwork PNG bundled in `Assets.xcassets/AppIconPreviews`
/// for display in the picker, since the `.icon` files themselves aren't directly renderable as a
/// SwiftUI `Image`.
struct AppIconOption: Identifiable {
    let iconName: String?
    let displayName: String
    let previewImageName: String

    var id: String { iconName ?? "primary" }

    static let all: [AppIconOption] = [
        AppIconOption(iconName: nil, displayName: "Templar Cross—Gradient", previewImageName: "IconPreview1"),
        AppIconOption(iconName: "Icon2", displayName: "Templar Cross—Gold", previewImageName: "IconPreview2"),
        AppIconOption(iconName: "Icon3", displayName: "Templar Cross—Black", previewImageName: "IconPreview3"),
        AppIconOption(iconName: "Icon4", displayName: "Black Jerusalem Cross—Red", previewImageName: "IconPreview4"),
        AppIconOption(iconName: "Icon5", displayName: "Black Jerusalem Cross—Gold", previewImageName: "IconPreview5"),
        AppIconOption(iconName: "Icon6", displayName: "Gold Jerusalem Cross—Red", previewImageName: "IconPreview6"),
        AppIconOption(iconName: "Icon7", displayName: "Gold Jerusalem Cross—Black", previewImageName: "IconPreview7"),
        AppIconOption(iconName: "Icon8", displayName: "Gold Jerusalem Cross—Gradient", previewImageName: "IconPreview8"),
    ]
}
