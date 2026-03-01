import SwiftUI

struct WearCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var showingLogSheet: Bool
    let wearLogs: [WearLog]
    let watches: [Watch]

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    private var logsByDay: [Date: WearLog] {
        var dict: [Date: WearLog] = [:]
        for log in wearLogs {
            let day = calendar.startOfDay(for: log.date)
            dict[day] = log
        }
        return dict
    }

    private var monthDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let padding = weekday - 1

        var days: [Date?] = Array(repeating: nil, count: padding)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation { changeMonth(by: -1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.champagne)
                    }

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.vaultHeadline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        withAnimation { changeMonth(by: 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.champagne)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Day headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(height: 20)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                        if let date {
                            CalendarDayCell(
                                date: date,
                                wearLog: logsByDay[calendar.startOfDay(for: date)],
                                isToday: calendar.isDateInToday(date),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                            )
                            .onTapGesture {
                                selectedDate = date
                                showingLogSheet = true
                            }
                        } else {
                            Color.clear
                                .frame(height: 56)
                        }
                    }
                }
                .padding(.horizontal)

                // Today's log summary
                if let todayLog = logsByDay[calendar.startOfDay(for: Date())] {
                    TodayWearCard(log: todayLog)
                        .padding(.horizontal)
                } else {
                    Button {
                        selectedDate = Date()
                        showingLogSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log today's wear")
                        }
                        .font(.vaultHeadline)
                        .foregroundStyle(Color.champagne)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.vaultSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }

                // Recent logs
                if !wearLogs.isEmpty {
                    RecentWearLogsSection(logs: Array(wearLogs.prefix(5)))
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let wearLog: WearLog?
    let isToday: Bool
    let isSelected: Bool

    @State private var photo: UIImage?

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? Color.champagne : .white)

            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if wearLog != nil {
                    Image(systemName: "watch.analog")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.champagne)
                } else {
                    Color.clear
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.champagne.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.champagne.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .task {
            if let fileName = wearLog?.watch?.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}

// MARK: - Today Wear Card

struct TodayWearCard: View {
    let log: WearLog

    @State private var photo: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "watch.analog")
                        .font(.title2)
                        .foregroundStyle(Color.champagne)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text("Wearing Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let watch = log.watch {
                    Text("\(watch.brand) \(watch.modelName)")
                        .font(.vaultHeadline)
                        .foregroundStyle(.white)
                }
                if let occasion = log.occasion, let occ = WearOccasion(rawValue: occasion) {
                    HStack(spacing: 4) {
                        Image(systemName: occ.icon)
                            .font(.caption2)
                        Text(occ.displayName)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.champagne)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.champagne)
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task {
            if let fileName = log.watch?.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}

// MARK: - Recent Wear Logs

struct RecentWearLogsSection: View {
    let logs: [WearLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            ForEach(logs) { log in
                RecentWearLogRow(log: log)
            }
        }
    }
}

struct RecentWearLogRow: View {
    let log: WearLog

    @State private var photo: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "watch.analog")
                        .font(.caption)
                        .foregroundStyle(Color.champagne.opacity(0.5))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                if let watch = log.watch {
                    Text("\(watch.brand) \(watch.modelName)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                HStack(spacing: 8) {
                    Text(log.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let occasion = log.occasion, let occ = WearOccasion(rawValue: occasion) {
                        Text(occ.displayName)
                            .font(.caption)
                            .foregroundStyle(Color.champagne)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .task {
            if let fileName = log.watch?.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}
