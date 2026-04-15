import SwiftUI

struct StoreAnnotationView: View {
    let store: Store

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color.brown)
                        .frame(width: 36, height: 36)
                    Image(systemName: "wind")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                if store.isOpenNow {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                }
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
