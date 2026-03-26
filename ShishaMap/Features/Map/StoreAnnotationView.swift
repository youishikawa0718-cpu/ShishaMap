import SwiftUI

struct StoreAnnotationView: View {
    let store: Store

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.brown)
                    .frame(width: 36, height: 36)
                Image(systemName: "smoke.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 16))
            }
            Image(systemName: "arrowtriangle.down.fill")
                .foregroundStyle(Color.brown)
                .font(.system(size: 8))
                .offset(y: -2)
        }
    }
}

#Preview {
    StoreAnnotationView(store: .mock)
}
