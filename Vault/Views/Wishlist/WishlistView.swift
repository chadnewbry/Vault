import SwiftUI

struct WishlistView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var showingAddWatch = false
    @State private var thumbnails: [UUID: UIImage] = [:]

    private var wishlist: [Watch] {
        dataManager.fetchWishlist()
            .sorted { $0.wishlistOrder < $1.wishlistOrder }
    }

    var body: some View {
        NavigationStack {
            Group {
                if wishlist.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Wishlist")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddWatch = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.champagne)
                    }
                }
            }
            .sheet(isPresented: $showingAddWatch) {
                AddWishlistWatchView()
            }
            .background(Color.vaultBackground)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.champagne.opacity(0.5))
            Text("Wishlist")
                .font(.vaultTitle)
                .foregroundStyle(.white)
            Text("Save the watches you're dreaming about and track their prices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showingAddWatch = true
            } label: {
                Label("Add First Watch", systemImage: "plus.circle.fill")
                    .foregroundStyle(Color.vaultBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.champagne)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vaultBackground)
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(wishlist) { watch in
                NavigationLink(destination: WishlistDetailView(watch: watch)) {
                    WishlistCardRow(watch: watch, thumbnail: thumbnails[watch.id])
                }
                .listRowBackground(Color.vaultSurface)
                .listRowSeparatorTint(Color.white.opacity(0.08))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    dataManager.deleteWatch(wishlist[index])
                }
                dataManager.save()
            }
            .onMove { source, destination in
                var reordered = wishlist
                reordered.move(fromOffsets: source, toOffset: destination)
                for (idx, watch) in reordered.enumerated() {
                    watch.wishlistOrder = idx
                }
                dataManager.save()
            }
        }
        .listStyle(.plain)
        .background(Color.vaultBackground)
        .scrollContentBackground(.hidden)
        .toolbar {
            EditButton()
                .foregroundStyle(Color.champagne)
        }
        .task {
            await loadThumbnails()
        }
    }

    private func loadThumbnails() async {
        for watch in wishlist {
            guard let fileName = watch.photoFileNames.first,
                  thumbnails[watch.id] == nil else { continue }
            if let image = await PhotoStorageService.shared.loadPhoto(named: fileName) {
                thumbnails[watch.id] = image
            }
        }
    }
}

// MARK: - Card Row

private struct WishlistCardRow: View {
    let watch: Watch
    let thumbnail: UIImage?

    private var hasPriceDrop: Bool {
        let history = ValueTrackingService.valueOverTime(for: watch)
        guard history.count >= 2 else { return false }
        return history[history.count - 1].1 < history[history.count - 2].1
    }

    var body: some View {
        HStack(spacing: 14) {
            // Photo / Placeholder
            Group {
                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.vaultBackground
                        .overlay {
                            Image(systemName: "watch.analog")
                                .foregroundStyle(Color.champagne.opacity(0.5))
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(watch.brand)
                        .font(.caption)
                        .foregroundStyle(Color.champagne)
                        .textCase(.uppercase)
                        .tracking(1)
                    Spacer()
                    if hasPriceDrop {
                        Label("Dropped", systemImage: "arrow.down.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                Text(watch.modelName)
                    .font(.vaultHeadline)
                    .foregroundStyle(.white)

                if let ref = watch.referenceNumber, !ref.isEmpty {
                    Text(ref)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    if let current = watch.currentValue {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(String(format: "$%.0f", current))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let target = watch.priceAlertTarget {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(String(format: "$%.0f", target))
                                .font(.subheadline)
                                .foregroundStyle(Color.champagne.opacity(0.8))
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}
