import SwiftUI
import SwiftData

struct LogWearSheet: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let preselectedWatch: Watch?

    @State private var selectedWatch: Watch?
    @State private var selectedOccasion: WearOccasion?
    @State private var notes = ""

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var existingLog: WearLog? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<WearLog>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        return (try? dataManager.modelContext.fetch(descriptor))?.first
    }

    init(date: Date = Date(), preselectedWatch: Watch? = nil) {
        self.date = date
        self.preselectedWatch = preselectedWatch
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date header
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(date.formatted(.dateTime.month(.wide).day()))
                            .font(.vaultTitle)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    // Prompt
                    Text("What are you wearing today?")
                        .font(.vaultHeadline)
                        .foregroundStyle(Color.champagne)

                    // Watch selector
                    if watches.isEmpty {
                        Text("Add watches to your collection first")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 40)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(watches) { watch in
                                    WatchSelectionCard(
                                        watch: watch,
                                        isSelected: selectedWatch?.id == watch.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedWatch = watch
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Occasion tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Occasion")
                            .font(.vaultHeadline)
                            .foregroundStyle(.white)

                        FlowLayout(spacing: 8) {
                            ForEach(WearOccasion.allCases) { occasion in
                                OccasionTag(
                                    occasion: occasion,
                                    isSelected: selectedOccasion == occasion
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedOccasion = selectedOccasion == occasion ? nil : occasion
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.vaultHeadline)
                            .foregroundStyle(.white)

                        TextField("How does it feel today?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.vaultSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Log button
                    Button {
                        logWear()
                    } label: {
                        Text(existingLog != nil ? "Update Today's Log" : "Log Wear")
                            .font(.vaultHeadline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.champagne)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(selectedWatch == nil)
                    .opacity(selectedWatch == nil ? 0.5 : 1)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .background(Color.vaultBackground)
            .navigationTitle("Log Wear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .onAppear {
            if let existing = existingLog {
                selectedWatch = existing.watch
                if let occ = existing.occasion {
                    selectedOccasion = WearOccasion(rawValue: occ)
                }
                notes = existing.notes ?? ""
            } else if let preselectedWatch {
                selectedWatch = preselectedWatch
            }
        }
    }

    private func logWear() {
        guard let watch = selectedWatch else { return }

        if let existing = existingLog {
            existing.watch = watch
            existing.occasion = selectedOccasion?.rawValue
            existing.notes = notes.isEmpty ? nil : notes
        } else {
            let log = WearLog(
                watch: watch,
                date: Calendar.current.startOfDay(for: date),
                occasion: selectedOccasion?.rawValue,
                notes: notes.isEmpty ? nil : notes
            )
            dataManager.addWearLog(log)
        }
        dataManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
