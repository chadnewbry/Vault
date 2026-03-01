import SwiftUI
import SwiftData

enum WearOccasion: String, CaseIterable, Identifiable {
    case casual, formal, sport, travel, specialEvent = "special_event"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .casual: "Casual"
        case .formal: "Formal"
        case .sport: "Sport"
        case .travel: "Travel"
        case .specialEvent: "Special Event"
        }
    }

    var icon: String {
        switch self {
        case .casual: "tshirt.fill"
        case .formal: "briefcase.fill"
        case .sport: "figure.run"
        case .travel: "airplane"
        case .specialEvent: "star.fill"
        }
    }
}

struct DailyWearLogView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    let date: Date

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

    var body: some View {
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

                // Watch selector - horizontal scroll
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
        .onAppear {
            if let existing = existingLog {
                selectedWatch = existing.watch
                if let occ = existing.occasion {
                    selectedOccasion = WearOccasion(rawValue: occ)
                }
                notes = existing.notes ?? ""
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
        dismiss()
    }
}

// MARK: - Watch Selection Card

struct WatchSelectionCard: View {
    let watch: Watch
    let isSelected: Bool

    @State private var photo: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "watch.analog")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.champagne.opacity(0.5))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.champagne : Color.clear, lineWidth: 3)
            )

            Text(watch.brand)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(watch.modelName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(width: 90)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .task {
            if let fileName = watch.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}

// MARK: - Occasion Tag

struct OccasionTag: View {
    let occasion: WearOccasion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: occasion.icon)
                .font(.caption)
            Text(occasion.displayName)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Color.champagne.opacity(0.2) : Color.vaultSurface)
        .foregroundStyle(isSelected ? Color.champagne : .secondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.champagne : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
