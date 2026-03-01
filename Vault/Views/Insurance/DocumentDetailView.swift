import SwiftUI

struct DocumentDetailView: View {
    let document: InsuranceDocument

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Zoomable Image
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { value in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation { scale = 1.0; lastScale = 1.0 }
                                    }
                                    if scale > 5.0 {
                                        withAnimation { scale = 5.0; lastScale = 5.0 }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0; lastScale = 1.0
                                } else {
                                    scale = 2.5; lastScale = 2.5
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .frame(height: 300)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: document.documentType.icon)
                            .foregroundStyle(Color.champagne)
                        Text(document.documentType.displayName)
                            .foregroundStyle(Color.champagne)
                            .font(.vaultHeadline)
                    }

                    if let watch = document.watch {
                        LabeledContent("Watch") {
                            Text("\(watch.brand) \(watch.modelName)")
                        }
                    }

                    if let date = document.date {
                        LabeledContent("Date") {
                            Text(date, style: .date)
                        }
                    }

                    if let notes = document.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vaultSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.vaultBackground)
        .task {
            image = await PhotoStorageService.shared.loadPhoto(named: document.imageFileName)
        }
    }
}
