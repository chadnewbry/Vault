import SwiftUI

struct WatchGridCell: View {
    let watch: Watch
    var onLogWear: ((Watch) -> Void)?
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.vaultSurface
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "watch.analog")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.champagne.opacity(0.4))
                }
            }
            .frame(height: 180)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(watch.brand)
                    .font(.caption)
                    .foregroundStyle(Color.champagne)
                    .lineLimit(1)

                Text(watch.modelName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let value = watch.currentValue {
                    Text(value, format: .currency(code: "USD"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
        }
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .contextMenu {
            Button {
                onLogWear?(watch)
            } label: {
                Label("Log Wear", systemImage: "clock.arrow.circlepath")
            }

            NavigationLink(value: watch.id) {
                Label("View Details", systemImage: "info.circle")
            }
        }
        .task {
            if let fileName = watch.photoFileNames.first {
                thumbnail = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}
