import SwiftUI

struct WishlistView: View {
    var body: some View {
        NavigationStack {
            PlaceholderView(icon: "heart.fill", title: "Wishlist", subtitle: "Save the watches you're dreaming about")
                .navigationTitle("Wishlist")
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
