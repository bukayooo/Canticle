import SwiftUI

/// A cross pattée (Templar-style cross), echoing the app icon, for use as a small section
/// divider / watermark throughout the reading view.
struct CrusaderCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let armThickness: CGFloat = 0.30 // fraction of width/height for the arm's narrow waist
        let flareIn: CGFloat = 0.16      // how far each arm's outer edge flares inward before its tip

        let midX = rect.midX
        let midY = rect.midY
        let halfThickness = (w * armThickness) / 2

        var path = Path()

        // Top arm
        path.move(to: CGPoint(x: midX - halfThickness, y: midY - halfThickness))
        path.addLine(to: CGPoint(x: midX - (w * (0.5 - flareIn)), y: rect.minY))
        path.addLine(to: CGPoint(x: midX, y: rect.minY + h * 0.02))
        path.addLine(to: CGPoint(x: midX + (w * (0.5 - flareIn)), y: rect.minY))
        path.addLine(to: CGPoint(x: midX + halfThickness, y: midY - halfThickness))

        // Right arm
        path.addLine(to: CGPoint(x: rect.maxX, y: midY - (h * (0.5 - flareIn)) ))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.02, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY + (h * (0.5 - flareIn)) ))
        path.addLine(to: CGPoint(x: midX + halfThickness, y: midY + halfThickness))

        // Bottom arm
        path.addLine(to: CGPoint(x: midX + (w * (0.5 - flareIn)), y: rect.maxY))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY - h * 0.02))
        path.addLine(to: CGPoint(x: midX - (w * (0.5 - flareIn)), y: rect.maxY))
        path.addLine(to: CGPoint(x: midX - halfThickness, y: midY + halfThickness))

        // Left arm
        path.addLine(to: CGPoint(x: rect.minX, y: midY + (h * (0.5 - flareIn)) ))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.02, y: midY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY - (h * (0.5 - flareIn)) ))
        path.closeSubpath()

        return path
    }
}

struct CrusaderDivider: View {
    var color: Color = Theme.crimson

    var body: some View {
        CrusaderCrossShape()
            .fill(color)
            .frame(width: 22, height: 22)
            .padding(.vertical, 8)
    }
}

#Preview {
    CrusaderDivider()
        .padding()
        .background(Theme.parchment)
}
