import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "watch.analog")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart.fill")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(Color.champagne)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
