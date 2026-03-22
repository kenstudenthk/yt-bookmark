import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    var onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "play.rectangle.fill",
            imageColor: .red,
            title: "Never lose your place",
            subtitle: "Save any YouTube timestamp in one tap",
            cta: "Continue"
        ),
        OnboardingPage(
            systemImage: "square.and.arrow.up",
            imageColor: .blue,
            title: "Share from YouTube",
            subtitle: "Tap Share → YT Bookmark to save your timestamp",
            cta: "Continue"
        ),
        OnboardingPage(
            systemImage: "checkmark.circle.fill",
            imageColor: .green,
            title: "You're all set!",
            subtitle: "Your saved bookmarks will appear in the app",
            cta: "Get Started"
        ),
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { index in
                OnboardingPageView(
                    page: pages[index],
                    isLast: index == pages.count - 1
                ) {
                    if index < pages.count - 1 {
                        withAnimation { currentPage = index + 1 }
                    } else {
                        onComplete()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .interactiveDismissDisabled()
    }
}

// MARK: - OnboardingPage model

private struct OnboardingPage {
    let systemImage: String
    let imageColor: Color
    let title: String
    let subtitle: String
    let cta: String
}

// MARK: - OnboardingPageView

private struct OnboardingPageView: View {

    let page: OnboardingPage
    let isLast: Bool
    let onCTA: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(page.imageColor)
                .padding(.bottom, 40)

            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            Button(action: onCTA) {
                Text(page.cta)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}
