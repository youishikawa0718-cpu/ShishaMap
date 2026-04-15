import SwiftUI

/// アプリ起動時に表示するスプラッシュ画面
struct LaunchScreenView: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -15
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .brown.opacity(0.3), radius: 15, y: 8)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))

                Text("ShishaMap")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.brown)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
            }
        }
        .task {
            withAnimation(.spring(duration: 0.7, bounce: 0.35)) {
                iconScale = 1.0
                iconRotation = 0
            }

            try? await Task.sleep(for: .seconds(0.35))

            withAnimation(.easeOut(duration: 0.4)) {
                textOffset = 0
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
