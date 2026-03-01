import SwiftUI
import PhotosUI

struct AddEditWatchView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    var existingWatch: Watch?
    private var isEditing: Bool { existingWatch != nil }

    @State private var brand = ""
    @State private var modelName = ""
    @State private var referenceNumber = ""
    @State private var serialNumber = ""
    @State private var movementType: MovementType = .automatic
    @State private var caseSize = ""
    @State private var caseMaterial: CaseMaterial = .steel
    @State private var dialColor = ""
    @State private var selectedComplications: Set<String> = []
    @State private var purchaseDate = Date()
    @State private var hasPurchaseDate = false
    @State private var purchasePrice = ""
    @State private var currentValue = ""
    @State private var notes = ""
    @State private var photoFileNames: [String] = []
    @State private var photoImages: [String: UIImage] = [:]
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showingBrandPicker = false
    @State private var brandSearch = ""

    private static let complicationOptions = [
        "Date", "Chronograph", "GMT", "Moonphase", "Tourbillon",
        "Minute Repeater", "Perpetual Calendar", "Power Reserve",
        "World Time", "Alarm", "Dual Time", "Flyback Chronograph"
    ]

    private static let brandList = [
        "A. Lange & Söhne", "Audemars Piguet", "Ball", "Blancpain",
        "Breguet", "Breitling", "Bulgari", "Cartier", "Casio",
        "Chopard", "Citizen", "Corum", "Doxa",
        "F.P. Journe", "Franck Muller", "Frederique Constant",
        "Girard-Perregaux", "Glashütte Original", "Grand Seiko",
        "Hamilton", "Hublot", "IWC", "Jacob & Co",
        "Jaeger-LeCoultre", "Junghans", "Longines", "Maurice Lacroix",
        "Mido", "Montblanc", "Nomos", "Omega", "Oris",
        "Panerai", "Patek Philippe", "Piaget", "Rado",
        "Richard Mille", "Rolex", "Seiko", "Sinn", "TAG Heuer",
        "Tissot", "Tudor", "Ulysse Nardin", "Vacheron Constantin",
        "Zenith"
    ]

    var body: some View {
        NavigationStack {
            Form {
                photosSection
                brandSection
                detailsSection
                specsSection
                complicationsSection
                purchaseSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.vaultBackground)
            .navigationTitle(isEditing ? "Edit Watch" : "Add Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.champagne)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWatch() }
                        .foregroundStyle(Color.champagne)
                        .fontWeight(.semibold)
                        .disabled(brand.isEmpty || modelName.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .onChange(of: photoItems) { _, newItems in
                handlePhotoSelection(newItems)
            }
            .sheet(isPresented: $showingBrandPicker) {
                BrandPickerView(
                    brands: Self.brandList,
                    selectedBrand: $brand,
                    searchText: $brandSearch
                )
            }
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photoFileNames, id: \.self) { fileName in
                        ZStack(alignment: .topTrailing) {
                            if let img = photoImages[fileName] {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vaultSurface)
                                    .frame(width: 90, height: 90)
                            }
                            Button { removePhoto(fileName) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .font(.caption)
                            }
                            .offset(x: 4, y: -4)
                        }
                    }

                    if photoFileNames.count < 10 {
                        PhotosPicker(selection: $photoItems, maxSelectionCount: 10 - photoFileNames.count, matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle").font(.title2)
                                Text("Add").font(.caption)
                            }
                            .foregroundStyle(Color.champagne)
                            .frame(width: 90, height: 90)
                            .background(Color.vaultSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Photos (first = hero)")
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var brandSection: some View {
        Section("Brand & Model") {
            Button { showingBrandPicker = true } label: {
                HStack {
                    Text("Brand").foregroundStyle(.white)
                    Spacer()
                    Text(brand.isEmpty ? "Select" : brand)
                        .foregroundStyle(brand.isEmpty ? .secondary : Color.champagne)
                }
            }
            TextField("Model", text: $modelName)
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Reference Number", text: $referenceNumber)
            TextField("Serial Number", text: $serialNumber)
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var specsSection: some View {
        Section("Specifications") {
            Picker("Movement", selection: $movementType) {
                ForEach(MovementType.allCases) { t in Text(t.displayName).tag(t) }
            }
            HStack {
                Text("Case Size"); Spacer()
                TextField("mm", text: $caseSize)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("mm").foregroundStyle(.secondary)
            }
            Picker("Case Material", selection: $caseMaterial) {
                ForEach(CaseMaterial.allCases) { m in Text(m.displayName).tag(m) }
            }
            TextField("Dial Color", text: $dialColor)
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var complicationsSection: some View {
        Section("Complications") {
            FlowLayout(spacing: 8) {
                ForEach(Self.complicationOptions, id: \.self) { comp in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        if selectedComplications.contains(comp) {
                            selectedComplications.remove(comp)
                        } else {
                            selectedComplications.insert(comp)
                        }
                    } label: {
                        Text(comp)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedComplications.contains(comp) ? Color.champagne : Color.champagne.opacity(0.15))
                            .foregroundStyle(selectedComplications.contains(comp) ? .black : Color.champagne)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var purchaseSection: some View {
        Section("Purchase Info") {
            Toggle("Purchase Date", isOn: $hasPurchaseDate).tint(Color.champagne)
            if hasPurchaseDate {
                DatePicker("Date", selection: $purchaseDate, displayedComponents: .date).tint(Color.champagne)
            }
            HStack {
                Text("Price"); Spacer()
                TextField("0", text: $purchasePrice)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text("USD").foregroundStyle(.secondary)
            }
            HStack {
                Text("Current Value"); Spacer()
                TextField("0", text: $currentValue)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text("USD").foregroundStyle(.secondary)
            }
        }
        .listRowBackground(Color.vaultSurface)
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
        }
        .listRowBackground(Color.vaultSurface)
    }

    // MARK: - Actions

    private func loadExisting() {
        guard let w = existingWatch else { return }
        brand = w.brand
        modelName = w.modelName
        referenceNumber = w.referenceNumber ?? ""
        serialNumber = w.serialNumber ?? ""
        movementType = w.movementType
        if let s = w.caseSize { caseSize = String(format: "%.0f", s) }
        caseMaterial = w.caseMaterial
        dialColor = w.dialColor ?? ""
        selectedComplications = Set(w.complications)
        if let pd = w.purchaseDate { purchaseDate = pd; hasPurchaseDate = true }
        if let pp = w.purchasePrice { purchasePrice = String(format: "%.0f", pp) }
        if let cv = w.currentValue { currentValue = String(format: "%.0f", cv) }
        notes = w.notes ?? ""
        photoFileNames = w.photoFileNames
        Task {
            for name in w.photoFileNames {
                if let img = await PhotoStorageService.shared.loadPhoto(named: name) {
                    photoImages[name] = img
                }
            }
        }
    }

    private func saveWatch() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if let watch = existingWatch {
            watch.brand = brand
            watch.modelName = modelName
            watch.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
            watch.serialNumber = serialNumber.isEmpty ? nil : serialNumber
            watch.movementType = movementType
            watch.caseSize = Double(caseSize)
            watch.caseMaterial = caseMaterial
            watch.dialColor = dialColor.isEmpty ? nil : dialColor
            watch.complications = Array(selectedComplications)
            watch.purchaseDate = hasPurchaseDate ? purchaseDate : nil
            watch.purchasePrice = Double(purchasePrice)
            watch.currentValue = Double(currentValue)
            watch.notes = notes.isEmpty ? nil : notes
            watch.photoFileNames = photoFileNames
            dataManager.save()
        } else {
            let watch = Watch(brand: brand, modelName: modelName, movementType: movementType, caseMaterial: caseMaterial)
            watch.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
            watch.serialNumber = serialNumber.isEmpty ? nil : serialNumber
            watch.caseSize = Double(caseSize)
            watch.dialColor = dialColor.isEmpty ? nil : dialColor
            watch.complications = Array(selectedComplications)
            watch.purchaseDate = hasPurchaseDate ? purchaseDate : nil
            watch.purchasePrice = Double(purchasePrice)
            watch.currentValue = Double(currentValue)
            watch.notes = notes.isEmpty ? nil : notes
            watch.photoFileNames = photoFileNames
            dataManager.addWatch(watch)
        }
        dismiss()
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let fileName = await PhotoStorageService.shared.savePhoto(image) {
                    photoFileNames.append(fileName)
                    photoImages[fileName] = image
                }
            }
        }
        photoItems = []
    }

    private func removePhoto(_ fileName: String) {
        Task { await PhotoStorageService.shared.deletePhoto(named: fileName) }
        photoFileNames.removeAll { $0 == fileName }
        photoImages.removeValue(forKey: fileName)
    }
}

// MARK: - Brand Picker

struct BrandPickerView: View {
    let brands: [String]
    @Binding var selectedBrand: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss

    private var filtered: [String] {
        if searchText.isEmpty { return brands }
        return brands.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty && !filtered.contains(where: { $0.lowercased() == searchText.lowercased() }) {
                    Button {
                        selectedBrand = searchText
                        dismiss()
                    } label: {
                        HStack {
                            Text("Custom: \"\(searchText)\"").foregroundStyle(Color.champagne)
                            Spacer()
                            Image(systemName: "plus.circle").foregroundStyle(Color.champagne)
                        }
                    }
                }
                ForEach(filtered, id: \.self) { brand in
                    Button {
                        selectedBrand = brand
                        dismiss()
                    } label: {
                        HStack {
                            Text(brand).foregroundStyle(.primary)
                            Spacer()
                            if selectedBrand == brand {
                                Image(systemName: "checkmark").foregroundStyle(Color.champagne)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search brands")
            .navigationTitle("Select Brand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.champagne)
                }
            }
        }
    }
}
