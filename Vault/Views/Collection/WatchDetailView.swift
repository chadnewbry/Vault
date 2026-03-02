import SwiftUI
import SwiftData

struct WatchDetailView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var showingAddDocument = false
    @State private var showingLogWear = false
    @State private var showingCustomDatePicker = false
    @State private var customWearDate = Date()
    @State private var woreTodayConfirmed = false
    @State private var selectedPhotoIndex = 0
    @Binding var selectedTab: AppTab
    @Bindable var watch: Watch

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                photoCarousel
                specsCard
                valueCard
                wearCard
                WatchAnalyticsCard(watch: watch)
                insuranceCard
                if let notes = watch.notes, !notes.isEmpty {
                    notesCard(notes)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.vaultBackground)
        .navigationTitle(watch.modelName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(Color.champagne)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditWatchView(existingWatch: watch)
                .environment(dataManager)
        }
        .sheet(isPresented: $showingAddDocument) {
            NavigationStack {
                AddDocumentView(preselectedWatch: watch)
            }
            .environment(dataManager)
        }
        .sheet(isPresented: $showingLogWear) {
            LogWearSheet(date: Date(), preselectedWatch: watch)
                .environment(dataManager)
        }
        .sheet(isPresented: $showingCustomDatePicker) {
            customDatePickerSheet
        }
        .alert("Delete Watch", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                dataManager.deleteWatch(watch)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? This cannot be undone.")
        }
    }

    // MARK: - Photo Carousel

    private var photoCarousel: some View {
        TabView(selection: $selectedPhotoIndex) {
            if watch.photoFileNames.isEmpty {
                ZStack {
                    Color.vaultSurface
                    Image(systemName: "watch.analog")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.champagne.opacity(0.3))
                }
                .tag(0)
            } else {
                ForEach(Array(watch.photoFileNames.enumerated()), id: \.offset) { index, fileName in
                    AsyncPhotoView(fileName: fileName)
                        .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: watch.photoFileNames.count > 1 ? .always : .never))
        .frame(height: 360)
    }

    // MARK: - Specs

    private var specsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(watch.brand)
                .font(.caption)
                .foregroundStyle(Color.champagne)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(watch.modelName)
                .font(.vaultTitle)
                .foregroundStyle(.white)

            Divider().background(Color.champagne.opacity(0.2))

            if let ref = watch.referenceNumber, !ref.isEmpty { specRow("Reference", ref) }
            if let serial = watch.serialNumber, !serial.isEmpty { specRow("Serial", serial) }
            specRow("Movement", watch.movementType.displayName)
            if let size = watch.caseSize { specRow("Case Size", "\(Int(size))mm") }
            specRow("Case Material", watch.caseMaterial.displayName)
            if let dial = watch.dialColor, !dial.isEmpty { specRow("Dial", dial) }

            if !watch.complications.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Complications").font(.caption).foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(watch.complications, id: \.self) { comp in
                            Text(comp)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.champagne.opacity(0.15))
                                .foregroundStyle(Color.champagne)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Value

    private var valueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value").font(.vaultHeadline).foregroundStyle(.white)
            HStack {
                valueItem("Purchase", watch.purchasePrice)
                Spacer()
                valueItem("Current", watch.currentValue)
                Spacer()
                if let pct = watch.appreciationPercentage {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Change").font(.caption).foregroundStyle(.secondary)
                        Text("\(pct >= 0 ? "+" : "")\(pct, specifier: "%.1f")%")
                            .font(.headline)
                            .foregroundStyle(pct >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Wear

    private var wearCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wear History").font(.vaultHeadline).foregroundStyle(.white)
                Text("\(watch.wearCount) times worn")
                    .font(.subheadline).foregroundStyle(.secondary)
                if let lastWorn = watch.lastWorn {
                    Text("Last worn \(lastWorn, style: .relative) ago")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // Quick wear actions
            HStack(spacing: 10) {
                Button {
                    quickLogWear(date: Date())
                } label: {
                    Label("Wore Today", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.champagne)
                        .clipShape(Capsule())
                }

                Button {
                    customWearDate = Date()
                    showingCustomDatePicker = true
                } label: {
                    Label("Custom Date", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.champagne)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.champagne.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Full log option
            Button {
                showingLogWear = true
            } label: {
                Text("Log with Details")
                    .font(.caption)
                    .foregroundStyle(Color.champagne.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }

            // Navigate to wear history tab
            Button {
                selectedTab = .wearHistory
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    Text("View Wear History")
                        .font(.caption)
                }
                .foregroundStyle(Color.champagne)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.champagne.opacity(0.1))
                .clipShape(Capsule())
            }

            if woreTodayConfirmed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Wear logged!")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
                .transition(.scale.combined(with: .opacity))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Insurance Documents

    private var insuranceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Documents")
                        .font(.vaultHeadline)
                        .foregroundStyle(.white)
                    Text("\(watch.insuranceDocuments.count) document\(watch.insuranceDocuments.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingAddDocument = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.champagne)
                }
            }

            if !watch.insuranceDocuments.isEmpty {
                let sorted = watch.insuranceDocuments.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                ForEach(sorted.prefix(3)) { doc in
                    NavigationLink {
                        DocumentDetailView(document: doc)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: doc.documentType.icon)
                                .font(.body)
                                .foregroundStyle(Color.champagne)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(doc.documentType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let date = doc.date {
                                        Text(date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                if sorted.count > 3 {
                    NavigationLink {
                        DocumentListView(filterWatch: watch)
                            .environment(dataManager)
                    } label: {
                        Text("View All \(sorted.count) Documents")
                            .font(.subheadline)
                            .foregroundStyle(Color.champagne)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

        private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(.vaultHeadline).foregroundStyle(.white)
            Text(notes).font(.body).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Quick Wear Logging

    private func quickLogWear(date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if already logged for this date
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<WearLog>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        if let existing = try? dataManager.modelContext.fetch(descriptor),
           existing.contains(where: { $0.watch?.id == watch.id }) {
            // Already logged for this watch today — show confirmation anyway
            withAnimation(.spring(response: 0.3)) { woreTodayConfirmed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { woreTodayConfirmed = false }
            }
            return
        }

        let log = WearLog(watch: watch, date: startOfDay)
        dataManager.addWearLog(log)
        dataManager.save()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3)) { woreTodayConfirmed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { woreTodayConfirmed = false }
        }
    }

    private var customDatePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "Wear Date",
                    selection: $customWearDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.champagne)

                Button {
                    quickLogWear(date: customWearDate)
                    showingCustomDatePicker = false
                } label: {
                    Text("Log Wear")
                        .font(.vaultHeadline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.champagne)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.vaultBackground)
            .navigationTitle("Choose Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCustomDatePicker = false }
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func specRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.white)
        }
    }

    private func valueItem(_ label: String, _ amount: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            if let amount {
                Text(amount, format: .currency(code: "USD"))
                    .font(.headline).foregroundStyle(.white)
            } else {
                Text("—").font(.headline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Async Photo View

struct AsyncPhotoView: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.vaultSurface
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(Color.champagne)
            }
        }
        .task {
            image = await PhotoStorageService.shared.loadPhoto(named: fileName)
        }
    }
}
