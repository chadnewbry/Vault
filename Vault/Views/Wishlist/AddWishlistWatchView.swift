import SwiftUI
import PhotosUI

struct AddWishlistWatchView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var modelName = ""
    @State private var referenceNumber = ""
    @State private var targetPriceText = ""
    @State private var listingURL = ""
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isSaving = false

    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Watch") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $modelName)
                    TextField("Reference Number (optional)", text: $referenceNumber)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Price Alert") {
                    HStack {
                        Text("Target Price")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $targetPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Text("You'll be notified when the market price drops to or below this amount.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Listing") {
                    TextField("Chrono24 / marketplace URL (optional)", text: $listingURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Photo") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    HStack {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                        }
                        Spacer()
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                    }
                    .foregroundStyle(Color.champagne)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                .listRowBackground(Color.vaultSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.vaultBackground)
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave || isSaving)
                        .foregroundStyle(canSave ? Color.champagne : .gray)
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }

    private func save() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespaces)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespaces)
        guard !trimmedBrand.isEmpty, !trimmedModel.isEmpty else { return }
        isSaving = true

        Task {
            var photoFileName: String?
            if let image = selectedImage {
                photoFileName = await PhotoStorageService.shared.savePhoto(image)
            }

            let existingWishlist = dataManager.fetchWishlist()
            let nextOrder = existingWishlist.count

            let watch = Watch(
                brand: trimmedBrand,
                modelName: trimmedModel,
                isInWishlist: true
            )
            watch.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
            watch.priceAlertTarget = Double(targetPriceText)
            watch.listingURL = listingURL.isEmpty ? nil : listingURL
            watch.notes = notes.isEmpty ? nil : notes
            watch.wishlistOrder = nextOrder
            if let fileName = photoFileName {
                watch.photoFileNames = [fileName]
            }

            dataManager.addWatch(watch)
            dataManager.save()
            dismiss()
        }
    }
}
