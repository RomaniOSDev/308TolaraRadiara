import SwiftUI
import UIKit

struct ScreenBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Color("AppBackground")
                    Image("img_background")
                        .resizable()
                        .scaledToFill()
                        .opacity(colorScheme == .dark ? 0.18 : 0.12)
                    LinearGradient(
                        colors: colorScheme == .dark
                        ? [
                            Color("AppBackground").opacity(0.55),
                            Color("AppBackground").opacity(0.82),
                            Color("AppBackground").opacity(0.92)
                        ]
                        : [
                            Color("AppBackground").opacity(0.72),
                            Color("AppBackground").opacity(0.88),
                            Color("AppBackground").opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipped()
                .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }

    func appNavigationChrome(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(nil, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
    }

    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
