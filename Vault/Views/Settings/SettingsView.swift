import SwiftUI

struct SettingsView: View {
    private let baseURL = "https://chadnewbry.github.io/Vault/"

    var body: some View {
        List {
            Section("Legal") {
                Link(destination: URL(string: "\(baseURL)privacy-policy.html")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
                Link(destination: URL(string: "\(baseURL)terms-of-service.html")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            }

            Section("Help") {
                Link(destination: URL(string: "\(baseURL)support.html")!) {
                    Label("Support", systemImage: "questionmark.circle.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}
