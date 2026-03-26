import MapKit
import SwiftUI

struct MapView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .tokyo)
    @State private var selectedStoreID: String?

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedStoreID) {
            UserAnnotation()
            ForEach(viewModel.filteredStores) { store in
                Annotation(store.name, coordinate: store.coordinate, anchor: .bottom) {
                    StoreAnnotationView(store: store)
                }
                .tag(store.placeID)
            }
        }
        .mapControls {
            MapCompass()
            MapUserLocationButton()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.fetchNearbyDebounced(coordinate: context.region.center)
        }
        .sheet(item: selectedStore) { store in
            MiniCardView(store: store)
                .presentationDetents([.height(140)])
                .presentationBackgroundInteraction(.enabled)
        }
        .overlay(alignment: .top) {
            if let message = viewModel.errorMessage {
                ErrorBannerView(
                    message: message,
                    isRetryable: viewModel.isRetryable
                ) {
                    Task { await viewModel.retry() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.errorMessage)
        .task {
            await viewModel.fetchNearby(coordinate: .tokyo)
        }
    }

    /// selectedStoreID から Store を逆引きする
    private var selectedStore: Binding<Store?> {
        Binding(
            get: { viewModel.filteredStores.first { $0.placeID == selectedStoreID } },
            set: { selectedStoreID = $0?.placeID }
        )
    }
}

// MARK: - エラーバナー

private struct ErrorBannerView: View {
    let message: String
    let isRetryable: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message).font(.subheadline)
            if isRetryable {
                Button("再試行", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

// MARK: - フォールバック座標

extension CLLocationCoordinate2D {
    static let tokyo = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
}

extension MapCameraPosition {
    static let tokyo = MapCameraPosition.region(MKCoordinateRegion(
        center: .tokyo,
        latitudinalMeters: 3000,
        longitudinalMeters: 3000
    ))
}

#Preview {
    MapView()
        .environment(StoreViewModel(repository: MockStoreRepository()))
}
