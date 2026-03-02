import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { InsuranceView() } label: { Label("Insurance Documents", systemImage: "doc.text.fill") }
                }
                Section {
                    NavigationLink { SettingsView() } label: { Label("Settings", systemImage: "gearshape.fill") }
                }
            }
            .navigationTitle("More")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
