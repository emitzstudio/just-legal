//
//  EVakeelLogo.swift
//  LexIndia
//
//  The E-Vakeel mark: hand-drawn scales of justice with an AI spark —
//  used on the floating button and in the assistant header.
//

import SwiftUI

/// Scales of justice drawn as a single stroked path.
struct ScalesGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * width, y: rect.minY + y * height)
        }

        // Finial
        path.addEllipse(in: CGRect(
            x: rect.minX + 0.455 * width,
            y: rect.minY + 0.045 * height,
            width: 0.09 * width,
            height: 0.09 * height
        ))

        // Pole
        path.move(to: point(0.5, 0.16))
        path.addLine(to: point(0.5, 0.84))

        // Base
        path.move(to: point(0.33, 0.9))
        path.addLine(to: point(0.67, 0.9))

        // Beam
        path.move(to: point(0.14, 0.3))
        path.addLine(to: point(0.86, 0.3))

        // Hangers
        path.move(to: point(0.22, 0.3))
        path.addLine(to: point(0.22, 0.5))
        path.move(to: point(0.78, 0.3))
        path.addLine(to: point(0.78, 0.5))

        // Pans — shallow bowls
        path.move(to: point(0.09, 0.5))
        path.addQuadCurve(to: point(0.35, 0.5), control: point(0.22, 0.68))
        path.move(to: point(0.65, 0.5))
        path.addQuadCurve(to: point(0.91, 0.5), control: point(0.78, 0.68))

        return path
    }
}

/// The circular E-Vakeel face: accent gradient, scales mark, saffron spark.
struct EVakeelButtonFace: View {
    var diameter: CGFloat = 58
    var showsSpark: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LexColor.brand, LexColor.brandDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            ScalesGlyph()
                .stroke(style: StrokeStyle(lineWidth: diameter * 0.042, lineCap: .round, lineJoin: .round))
                .foregroundStyle(LexColor.onBrand)
                .padding(diameter * 0.23)
            if showsSpark {
                Image(systemName: "sparkle")
                    .font(.system(size: diameter * 0.17, weight: .bold))
                    .foregroundStyle(LexColor.saffron)
                    .offset(x: diameter * 0.27, y: -diameter * 0.29)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}
