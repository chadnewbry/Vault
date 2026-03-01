import SwiftUI
import PhotosUI

struct AddDocumentView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    var preselectedWatch: Watch? = nil

    @State private var selectedWatch: Watch?
    @State private var documentType: DocType = .receipt
    @State private var title = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isSaving = false

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var canSave: Bool {
        selectedWatch != nil && !title.isEmpty && selectedImage != nil
    }

    var body: some View {
        Form {
            // Watch Selection
            if preselectedWatch == nil {
                Section("Watch") {
                    Picker("Watch", selection: $selectedWatch) {
                        Text("Select a watch").tag(nil as Watch?)
                        ForEach(watches) { watch in
                            Text("\(watch.brand) \(watch.modelName)").tag(watch as Watch?)
                        }
                    }
                }
            }

            // Document Info
            Section("Document Details") {
                Picker("Type", selection: $documentType) {
                    ForEach(DocType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                TextField("Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Image
            Section("Document Image") {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity)
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
        }
        .navigationTitle("Add Document")
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            if let preselectedWatch {
                selectedWatch = preselectedWatch
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

    private func save() {
        guard let watch = selectedWatch, let image = selectedImage else { return }
        isSaving = true

        Task {
            guard let fileName = await PhotoStorageService.shared.savePhoto(image) else {
                isSaving = false
                return
            }

            let doc = InsuranceDocument(
                watch: watch,
                documentType: documentType,
                imageFileName: fileName,
                title: title,
                date: date,
                notes: notes.isEmpty ? nil : notes
            )
            dataManager.addInsuranceDocument(doc)
            dataManager.save()
            dismiss()
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
