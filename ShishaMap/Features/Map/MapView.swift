import MapKit
import SwiftUI

struct MapView: View {
    @Environment(StoreViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .tokyo)
    @State private var selectedStoreID: String?
    @State private var showFilter = false

    var body: some View {
        ZStack {
            mapContent
            overlayControls
        }
        .sheet(item: selectedStore) { store in
            NavigationStack {
                MiniCardView(store: store)
            }
            .presentationDetents([.height(180)])
            .presentationBackgroundInteraction(.enabled)
        }
        .sheet(isPresented: $showFilter) {
            FilterSheetView(filter: Bindable(viewModel).filter)
                .presentationDetents([.medium])
        }
        .task {
            await viewModel.fetchNearby(coordinate: .tokyo)
        }
    }

    // MARK: - マップ本体

    private var mapContent: some View {
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
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.fetchNearbyDebounced(coordinate: context.region.center)
        }
    }

    // MARK: - オーバーレイ

    private var overlayControls: some View {
        VStack {
            // エラーバナー
            if let message = viewModel.errorMessage {
                ErrorBannerView(
                    message: message,
                    isRetryable: viewModel.isRetryable
                ) {
                    Task { await viewModel.retry() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    // フィルターボタン
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .brown)
                    }
                    .overlay(alignment: .topTrailing) {
                        if viewModel.filter.activeCount > 0 {
                            Text("\(viewModel.filter.activeCount)")
                                .font(.caption2).bold()
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(.red, in: Circle())
                                .offset(x: 6, y: -6)
                        }
                    }

                    // 現在地ボタン
                    Button {
                        withAnimation { cameraPosition = .userLocation(fallback: .tokyo) }
                    } label: {
                        Image(systemName: "location.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .brown)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .padding(.bottom, 8)
        }
        .animation(.easeInOut, value: viewModel.errorMessage)
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
                    .tint(.brown)
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
