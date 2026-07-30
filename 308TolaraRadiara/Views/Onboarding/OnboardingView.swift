import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appearScale: CGFloat = 0.7
    @State private var appearOpacity: Double = 0
    @State private var sensitivity: SunSensitivity = .medium

    private let pages: [(title: String, body: String, symbol: String, image: String)] = [
        (
            "Track Solar Radiation",
            "Stay informed about daily solar radiation levels for optimal outdoor planning.",
            "sun.max.fill",
            "img_banner"
        ),
        (
            "Set Your Alerts",
            "Customize notifications to alert you when solar radiation hits your specified thresholds.",
            "bell.badge.fill",
            "img_card"
        ),
        (
            "Start Monitoring Now",
            "Begin tracking today's solar exposure and receive instant insights.",
            "chart.line.uptrend.xyaxis",
            "img_accent"
        )
    ]

    private var isQuizPage: Bool { page == pages.count }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
                sensitivityQuiz
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            HStack(spacing: 8) {
                ForEach(0...pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.35))
                        .frame(width: index == page ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }
            .padding(.bottom, 18)

            Button {
                HapticService.light()
                if page < pages.count {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    store.completeOnboarding(sensitivity: sensitivity)
                }
            } label: {
                Text(isQuizPage ? "Get Started" : "Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color("AppBackground")
                Image("img_background")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.18)
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.55),
                        Color("AppBackground").opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
        }
        .dismissKeyboardOnTap()
        .onChange(of: page) { _ in
            appearScale = 0.7
            appearOpacity = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
    }

    private var sensitivityQuiz: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)
            Image(systemName: "person.crop.circle.badge.sun.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color("AppPrimary"))
                .padding(20)
                .background(
                    Circle()
                        .fill(Color("AppSurface").opacity(0.9))
                        .shadow(color: Color("AppPrimary").opacity(0.35), radius: 14)
                )

            VStack(spacing: 10) {
                Text("Sun Sensitivity")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                Text("We’ll set starting alert thresholds based on your answer.")
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            VStack(spacing: 10) {
                ForEach(SunSensitivity.allCases) { option in
                    Button {
                        HapticService.light()
                        sensitivity = option
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .foregroundStyle(Color("AppPrimary"))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: sensitivity == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(sensitivity == option ? Color("AppPrimary") : Color("AppTextSecondary"))
                        }
                        .padding(14)
                        .background(Color("AppSurface").opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(sensitivity == option ? Color("AppPrimary").opacity(0.7) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func onboardingPage(
        _ item: (title: String, body: String, symbol: String, image: String),
        index: Int
    ) -> some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)

            ZStack {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(index == page ? appearScale : 0.92)
                    .opacity(index == page ? appearOpacity : 0.65)

                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.15),
                        Color("AppBackground").opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: item.symbol)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(22)
                    .background(
                        Circle()
                            .fill(Color("AppBackground").opacity(0.72))
                            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 16)
                    )
                    .scaleEffect(index == page ? appearScale : 0.85)
                    .opacity(index == page ? appearOpacity : 0.5)
            }
            .frame(height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
    }
}
