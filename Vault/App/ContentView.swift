import SwiftUI

enum AppTab: String, Hashable {
    case collection
    case analytics
    case wearHistory
    case wishlist
    case more
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .collection

    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Collection", systemImage: "watch.analog")
                }
                .tag(AppTab.collection)

            AnalyticsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.analytics)

            NavigationStack {
                WearHistoryView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Wear", systemImage: "calendar.badge.clock")
            }
            .tag(AppTab.wearHistory)

            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart.fill")
                }
                .tag(AppTab.wishlist)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(AppTab.more)
        }
        .tint(Color.champagne)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
