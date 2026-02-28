import SwiftUI

struct CollectionView: View {
    var body: some View {
        NavigationStack {
            PlaceholderView(icon: "watch.analog", title: "Your Collection", subtitle: "Add your first timepiece to get started")
                .navigationTitle("Collection")
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
