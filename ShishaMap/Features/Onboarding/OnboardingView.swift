import CoreLocation
import SwiftUI

struct OnboardingView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var currentPage = 0
    private let lastPage = 2

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                locationPage.tag(1)
                featuresPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            bottomControls
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Page 1: ウェルカム

    private var welcomePage: some View {
        OnboardingPageView(
            assetImage: "LaunchIcon",
            title: "ChillSearching へようこそ",
            subtitle: "近くのカフェやラウンジを見つけて、\nお気に入りを記録しましょう"
        )
    }

    // MARK: - Page 2: 位置情報の説明

    private var locationPage: some View {
        OnboardingPageView(
            systemImage: "location.circle.fill",
            imageColor: .blue,
            title: "現在地から近くの店舗を検索",
            subtitle: "位置情報を使って、あなたの周辺にある\nお店を地図上に表示します"
        )
    }

    // MARK: - Page 3: 主要機能の紹介

    private var featuresPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            Text("あなただけのお気に入りを見つけよう")
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "map.fill", color: .brown, text: "地図で近くの店を発見")
                featureRow(icon: "magnifyingglass", color: .blue, text: "条件で絞り込み検索")
                featureRow(icon: "heart.fill", color: .pink, text: "お気に入りに保存")
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - 下部コントロール

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if currentPage == 1 {
                Button {
                    locationManager.requestPermission()
                    withAnimation { currentPage = lastPage }
                } label: {
                    Text("位置情報を許可して次へ")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
            } else if currentPage == lastPage {
                Button {
                    completeOnboarding()
                } label: {
                    Text("はじめる")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
            } else {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("次へ")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
            }

            if currentPage < lastPage {
                Button("スキップ") {
                    completeOnboarding()
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Private

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(text)
                .font(.body)
        }
    }

    private func completeOnboarding() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        onComplete()
    }
}

// MARK: - 再利用可能なページテンプレート

private struct OnboardingPageView: View {
    let systemImage: String?
    let assetImage: String?
    let imageColor: Color
    let title: String
    let subtitle: String

    init(systemImage: String, imageColor: Color, title: String, subtitle: String) {
        self.systemImage = systemImage
        self.assetImage = nil
        self.imageColor = imageColor
        self.title = title
        self.subtitle = subtitle
    }

    init(assetImage: String, title: String, subtitle: String) {
        self.systemImage = nil
        self.assetImage = assetImage
        self.imageColor = .clear
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let assetImage {
                Image(assetImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 72))
                    .foregroundStyle(imageColor)
            }

            Text(title)
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(LocationManager())
}
