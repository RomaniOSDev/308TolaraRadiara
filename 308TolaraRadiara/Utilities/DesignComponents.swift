import SwiftUI

struct SoftCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppSurface").opacity(0.98),
                        Color("AppSurface").opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("AppAccent").opacity(0.55),
                                Color("AppTextPrimary").opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
    }
}

struct GlassyCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color("AppSurface").opacity(0.92))
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("AppTextPrimary").opacity(0.10),
                                    Color("AppPrimary").opacity(0.10),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color("AppTextPrimary").opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color("AppPrimary").opacity(0.22), radius: 16, y: 8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: Color("AppPrimary").opacity(0.45),
                radius: configuration.isPressed ? 4 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}

struct AchievementBanner: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Color("AppPrimary"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color("AppSurface"), Color("AppBackground")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        .padding(.horizontal, 16)
    }
}

struct BannerHero: View {
    let imageName: String
    var height: CGFloat = 120

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.05),
                        Color("AppBackground").opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
    }
}

struct IntensitySwatch: View {
    let fraction: Double

    var body: some View {
        Circle()
            .fill(intensityColor(fraction))
            .frame(width: 12, height: 12)
            .shadow(color: intensityColor(fraction).opacity(0.5), radius: 4)
    }
}

func intensityColor(_ fraction: Double) -> Color {
    let t = min(max(fraction, 0), 1)
    if t < 0.25 { return Color.green }
    if t < 0.5 { return Color.yellow }
    if t < 0.75 { return Color.orange }
    return Color.red
}
