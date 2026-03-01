import SwiftUI

struct WishlistDetailView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    let watch: Watch

    @State private var thumbnailImage: UIImage?
    @State private var showingAddPrice = false
    @State private var showingMoveToCollection = false
    @State private var showingEditTarget = false
    @State private var newPriceText = ""
    @State private var editedTargetText = ""
    @State private var isLoadingPhoto = true

    private var priceHistory: [(Date, Double)] {
        ValueTrackingService.valueOverTime(for: watch)
    }

    private var hasPriceDrop: Bool {
        guard priceHistory.count >= 2 else { return false }
        let sorted = priceHistory
        return sorted[sorted.count - 1].1 < sorted[sorted.count - 2].1
    }

    private var shareText: String {
        var parts: [String] = []
        parts.append("I'm eyeing a \(watch.brand) \(watch.modelName)")
        if let ref = watch.referenceNumber, !ref.isEmpty {
            parts.append("(Ref. \(ref))")
        }
        if let target = watch.priceAlertTarget {
            parts.append(String(format: "— budget around $%.0f", target))
        }
        if let url = watch.listingURL, !url.isEmpty {
            parts.append("\nListing: \(url)")
        }
        return parts.joined(separator: " ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                photoSection
                infoSection
                priceSection
                chartSection
                actionsSection
            }
            .padding()
        }
        .background(Color.vaultBackground)
        .navigationTitle("\(watch.brand) \(watch.modelName)")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .task {
            await loadPhoto()
        }
        .sheet(isPresented: $showingAddPrice) {
            addPriceSheet
        }
        .sheet(isPresented: $showingEditTarget) {
            editTargetSheet
        }
        .sheet(isPresented: $showingMoveToCollection) {
            MoveToCollectionView(watch: watch)
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if isLoadingPhoto {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vaultSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .overlay {
                        ProgressView()
                            .tint(Color.champagne)
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vaultSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "watch.analog")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.champagne.opacity(0.4))
                    }
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(watch.brand)
                        .font(.caption)
                        .foregroundStyle(Color.champagne)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Text(watch.modelName)
                        .font(.vaultTitle)
                        .foregroundStyle(.white)
                }
                Spacer()
                if hasPriceDrop {
                    Label("Price Dropped!", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.8))
                        .clipShape(Capsule())
                }
            }

            if let ref = watch.referenceNumber, !ref.isEmpty {
                Label(ref, systemImage: "number")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let notes = watch.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let urlString = watch.listingURL, !urlString.isEmpty,
               let url = URL(string: urlString) {
                Link(destination: url) {
                    Label("View Listing", systemImage: "safari")
                        .font(.subheadline)
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                priceCard(
                    label: "Current",
                    value: watch.currentValue.map { String(format: "$%.0f", $0) } ?? "—",
                    accent: watch.currentValue != nil
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))

                priceCard(
                    label: "Target",
                    value: watch.priceAlertTarget.map { String(format: "$%.0f", $0) } ?? "—",
                    accent: false
                )

                if let current = watch.currentValue, let target = watch.priceAlertTarget {
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.1))

                    let diff = current - target
                    priceCard(
                        label: diff <= 0 ? "Under Target" : "Above Target",
                        value: String(format: "$%.0f", abs(diff)),
                        accent: diff <= 0
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.vaultSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button {
                    newPriceText = ""
                    showingAddPrice = true
                } label: {
                    Label("Add Price Entry", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.champagne)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.vaultSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    editedTargetText = watch.priceAlertTarget.map { String(format: "%.0f", $0) } ?? ""
                    showingEditTarget = true
                } label: {
                    Label("Edit Target", systemImage: "target")
                        .font(.subheadline)
                        .foregroundStyle(Color.champagne)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.vaultSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func priceCard(label: String, value: String, accent: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(accent ? Color.champagne : .white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            PriceHistoryChartView(watch: watch, targetPrice: watch.priceAlertTarget)
                .padding()
                .background(Color.vaultSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingMoveToCollection = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text("Move to Collection")
                        .font(.vaultHeadline)
                }
                .foregroundStyle(Color.vaultBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.champagne)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Sheets

    private var addPriceSheet: some View {
        NavigationStack {
            Form {
                Section("Current Price") {
                    HStack {
                        Text("Price")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $newPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                .listRowBackground(Color.vaultSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.vaultBackground)
            .navigationTitle("Add Price Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddPrice = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let price = Double(newPriceText) {
                            let entry = ValueHistory(watch: watch, date: Date(), value: price, source: "manual")
                            dataManager.addValueHistory(entry)
                            dataManager.save()
                        }
                        showingAddPrice = false
                    }
                    .disabled(Double(newPriceText) == nil)
                    .foregroundStyle(Double(newPriceText) != nil ? Color.champagne : .gray)
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }

    private var editTargetSheet: some View {
        NavigationStack {
            Form {
                Section("Alert Target") {
                    HStack {
                        Text("Target Price")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $editedTargetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Text("You'll be notified when the market price reaches this amount.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.vaultSurface)

                if watch.priceAlertTarget != nil {
                    Section {
                        Button("Remove Alert", role: .destructive) {
                            watch.priceAlertTarget = nil
                            dataManager.save()
                            showingEditTarget = false
                        }
                    }
                    .listRowBackground(Color.vaultSurface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.vaultBackground)
            .navigationTitle("Edit Target Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingEditTarget = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        watch.priceAlertTarget = Double(editedTargetText)
                        dataManager.save()
                        showingEditTarget = false
                    }
                    .foregroundStyle(Color.champagne)
                }
            }
        }
        .presentationDetents([.fraction(0.45)])
    }

    // MARK: - Helpers

    private func loadPhoto() async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        guard let fileName = watch.photoFileNames.first else { return }
        thumbnailImage = await PhotoStorageService.shared.loadPhoto(named: fileName)
    }
}
