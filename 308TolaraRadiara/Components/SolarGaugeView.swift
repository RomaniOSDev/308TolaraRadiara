import SwiftUI

struct SolarGaugeView: View {
    let value: Double
    let maxValue: Double
    let lowThreshold: Double
    let highThreshold: Double
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 18
                let start = Angle.degrees(135)
                let total = Angle.degrees(270)

                var track = Path()
                track.addArc(center: center, radius: radius, startAngle: start, endAngle: start + total, clockwise: false)
                context.stroke(track, with: .color(Color("AppTextSecondary").opacity(0.28)), style: StrokeStyle(lineWidth: 18, lineCap: .round))

                let gradient = Gradient(colors: [.green, .yellow, .orange, .red])
                var valuePath = Path()
                valuePath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: start,
                    endAngle: start + Angle(degrees: 270 * animatedProgress),
                    clockwise: false
                )
                context.stroke(
                    valuePath,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: size.height),
                        endPoint: CGPoint(x: size.width, y: 0)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

                let lowAngle = start + Angle(degrees: 270 * min(max(lowThreshold / maxValue, 0), 1))
                let highAngle = start + Angle(degrees: 270 * min(max(highThreshold / maxValue, 0), 1))
                drawMarker(context: context, center: center, radius: radius, angle: lowAngle, color: Color("AppAccent"))
                drawMarker(context: context, center: center, radius: radius, angle: highAngle, color: Color("AppPrimary"))
            }
            .frame(width: 240, height: 240)

            VStack(spacing: 4) {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .shadow(color: Color("AppPrimary").opacity(0.35), radius: 8)
                Text("W/m²")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(SolarReading(value: value).intensityLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(intensityColor(progress))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) { _ in
            withAnimation(.easeOut(duration: 0.55)) {
                animatedProgress = progress
            }
        }
    }

    private func drawMarker(context: GraphicsContext, center: CGPoint, radius: CGFloat, angle: Angle, color: Color) {
        let rad = CGFloat(angle.radians)
        let inner = CGPoint(x: center.x + cos(rad) * (radius - 14), y: center.y + sin(rad) * (radius - 14))
        let outer = CGPoint(x: center.x + cos(rad) * (radius + 14), y: center.y + sin(rad) * (radius + 14))
        var path = Path()
        path.move(to: inner)
        path.addLine(to: outer)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }
}

struct MiniHistoryChart: View {
    let values: [Double]

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let maxV = max(values.max() ?? 1, 1)
            let minV = min(values.min() ?? 0, maxV - 1)
            let range = max(maxV - minV, 1)
            let stepX = size.width / CGFloat(values.count - 1)

            var path = Path()
            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - CGFloat((value - minV) / range) * size.height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            var fill = path
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()

            context.fill(
                fill,
                with: .linearGradient(
                    Gradient(colors: [Color("AppPrimary").opacity(0.35), Color("AppPrimary").opacity(0.02)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
            context.stroke(
                path,
                with: .color(Color("AppAccent")),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(height: 72)
    }
}

struct InsightLineChart: View {
    let points: [(label: String, value: Double)]

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }
            let maxV = max(points.map(\.value).max() ?? 1, 1)
            let stepX = size.width / CGFloat(points.count - 1)
            var path = Path()
            for (index, point) in points.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - CGFloat(point.value / maxV) * (size.height - 8) - 4
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color("AppAccent"), Color("AppPrimary")]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )

            for (index, point) in points.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - CGFloat(point.value / maxV) * (size.height - 8) - 4
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(Color("AppPrimary")))
            }
        }
        .frame(height: 160)
    }
}
