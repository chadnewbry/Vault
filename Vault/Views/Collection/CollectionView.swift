import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(StoreManager.self) private var storeManager
    @Binding var selectedTab: AppTab
    @State private var searchText = ""
    @State private var sortOption: WatchSortOption = .dateAdded
    @State private var showingAddWatch = false
    @State private var showingSortPicker = false
    @State private var showingPaywall = false
    @State private var filterBrand: String?
    @State private var filterMovement: MovementType?
    @State private var filterMaterial: CaseMaterial?
    @State private var showingFilters = false
    @State private var watchToEdit: Watch?
    @State private var watchToDelete: Watch?
    @State private var watchToLogWear: Watch?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var watches: [Watch] {
        var result = dataManager.fetchWatches()

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.brand.lowercased().contains(q) ||
                $0.modelName.lowercased().contains(q) ||
                ($0.referenceNumber?.lowercased().contains(q) ?? false)
            }
        }

        if let brand = filterBrand {
            result = result.filter { $0.brand == brand }
        }
        if let movement = filterMovement {
            result = result.filter { $0.movementType == movement }
        }
        if let material = filterMaterial {
            result = result.filter { $0.caseMaterial == material }
        }

        switch sortOption {
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .brand:
            result.sort { $0.brand.localizedCompare($1.brand) == .orderedAscending }
        case .value:
            result.sort { ($0.currentValue ?? 0) > ($1.currentValue ?? 0) }
        case .wearFrequency:
            result.sort { $0.wearCount > $1.wearCount }
        }

        return result
    }

    private var allBrands: [String] {
        Array(Set(dataManager.fetchWatches().map(\.brand))).sorted()
    }

    private var collectionCount: Int {
        dataManager.fetchWatches().count
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if dataManager.fetchWatches().isEmpty {
                    emptyState
                } else {
                    galleryContent
                }
                addButton
            }
            .background(Color.vaultBackground)
            .navigationTitle("Collection")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    freeCounter
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        filterButton
                        sortButton
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search watches")
            .sheet(isPresented: $showingAddWatch) {
                AddEditWatchView()
                    .environment(dataManager)
                    .environment(storeManager)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(storeManager)
            }
            .confirmationDialog("Sort By", isPresented: $showingSortPicker) {
                ForEach(WatchSortOption.allCases) { option in
                    Button(option.rawValue) {
                        withAnimation { sortOption = option }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    brands: allBrands,
                    selectedBrand: $filterBrand,
                    selectedMovement: $filterMovement,
                    selectedMaterial: $filterMaterial
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $watchToEdit) { watch in
                AddEditWatchView(existingWatch: watch)
                    .environment(dataManager)
                    .environment(storeManager)
            }
            .sheet(item: $watchToLogWear) { watch in
                LogWearSheet(date: Date(), preselectedWatch: watch)
                    .environment(dataManager)
            }
            .alert("Delete Watch", isPresented: Binding(
                get: { watchToDelete != nil },
                set: { if !$0 { watchToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { watchToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let watch = watchToDelete {
                        dataManager.deleteWatch(watch)
                        watchToDelete = nil
                    }
                }
            } message: {
                if let watch = watchToDelete {
                    Text("Are you sure you want to delete \(watch.brand) \(watch.modelName)? This cannot be undone.")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "watch.analog")
                .font(.system(size: 48))
                .foregroundStyle(Color.champagne)
            Text("Your Collection")
                .font(.vaultTitle)
                .foregroundStyle(.white)
            Text("Add your first timepiece to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var galleryContent: some View {
        ScrollView {
            if hasActiveFilters {
                activeFilterChips
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(watches) { watch in
                    NavigationLink(value: watch.id) {
                        WatchGridCell(watch: watch)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            watchToEdit = watch
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            watchToLogWear = watch
                        } label: {
                            Label("Log Wear", systemImage: "clock.arrow.circlepath")
                        }
                        Divider()
                        Button(role: .destructive) {
                            watchToDelete = watch
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 80)
        }
        .navigationDestination(for: UUID.self) { watchID in
            if let watch = dataManager.fetchWatches().first(where: { $0.id == watchID }) {
                WatchDetailView(selectedTab: $selectedTab, watch: watch)
                    .environment(dataManager)
            }
        }
    }

    private var addButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if storeManager.canAddWatch(currentCount: collectionCount) {
                showingAddWatch = true
            } else {
                showingPaywall = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(Color.champagne)
                .clipShape(Circle())
                .shadow(color: Color.champagne.opacity(0.4), radius: 8, y: 4)
        }
        .padding(20)
    }

    @ViewBuilder
    private var freeCounter: some View {
        if !storeManager.isPremium {
            let remaining = storeManager.freeRemaining(currentCount: collectionCount)
            Button {
                showingPaywall = true
            } label: {
                HStack(spacing: 4) {
                    Text("\(remaining) free remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.champagne)
                }
            }
        }
    }

    private var sortButton: some View {
        Button { showingSortPicker = true } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(Color.champagne)
        }
    }

    private var filterButton: some View {
        Button { showingFilters = true } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(Color.champagne)
        }
    }

    private var hasActiveFilters: Bool {
        filterBrand != nil || filterMovement != nil || filterMaterial != nil
    }

    private var activeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let brand = filterBrand {
                    chipView(brand) { filterBrand = nil }
                }
                if let movement = filterMovement {
                    chipView(movement.displayName) { filterMovement = nil }
                }
                if let material = filterMaterial {
                    chipView(material.displayName) { filterMaterial = nil }
                }
                Button("Clear All") {
                    filterBrand = nil; filterMovement = nil; filterMaterial = nil
                }
                .font(.caption)
                .foregroundStyle(Color.champagne)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func chipView(_ text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.champagne.opacity(0.2))
        .foregroundStyle(Color.champagne)
        .clipShape(Capsule())
    }
}

// MARK: - Sort Option

enum WatchSortOption: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case brand = "Brand"
    case value = "Value"
    case wearFrequency = "Wear Frequency"
    var id: String { rawValue }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    let brands: [String]
    @Binding var selectedBrand: String?
    @Binding var selectedMovement: MovementType?
    @Binding var selectedMaterial: CaseMaterial?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !brands.isEmpty {
                    Section("Brand") {
                        ForEach(brands, id: \.self) { brand in
                            Button {
                                selectedBrand = selectedBrand == brand ? nil : brand
                            } label: {
                                HStack {
                                    Text(brand); Spacer()
                                    if selectedBrand == brand {
                                        Image(systemName: "checkmark").foregroundStyle(Color.champagne)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                Section("Movement") {
                    ForEach(MovementType.allCases) { type in
                        Button {
                            selectedMovement = selectedMovement == type ? nil : type
                        } label: {
                            HStack {
                                Text(type.displayName); Spacer()
                                if selectedMovement == type {
                                    Image(systemName: "checkmark").foregroundStyle(Color.champagne)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                Section("Material") {
                    ForEach(CaseMaterial.allCases) { mat in
                        Button {
                            selectedMaterial = selectedMaterial == mat ? nil : mat
                        } label: {
                            HStack {
                                Text(mat.displayName); Spacer()
                                if selectedMaterial == mat {
                                    Image(systemName: "checkmark").foregroundStyle(Color.champagne)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.champagne)
                }
            }
        }
    }
}
