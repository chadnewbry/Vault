import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            PlaceholderView(icon: "chart.bar.fill", title: "Analytics", subtitle: "Track value trends and collection insights")
                .navigationTitle("Analytics")
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
