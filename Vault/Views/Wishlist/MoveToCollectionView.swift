import SwiftUI

struct MoveToCollectionView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    let watch: Watch

    @State private var purchasePrice: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var movementType: MovementType
    @State private var caseMaterial: CaseMaterial

    init(watch: Watch) {
        self.watch = watch
        _movementType = State(initialValue: watch.movementType)
        _caseMaterial = State(initialValue: watch.caseMaterial)
    }

    private var canSave: Bool {
        !purchasePrice.isEmpty && Double(purchasePrice) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.champagne)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Adding to Collection")
                                .font(.vaultHeadline)
                                .foregroundStyle(.white)
                            Text("\(watch.brand) \(watch.modelName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Purchase Details") {
                    HStack {
                        Text("Price Paid")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                .listRowBackground(Color.vaultSurface)

                Section("Watch Details") {
                    Picker("Movement", selection: $movementType) {
                        ForEach(MovementType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Case Material", selection: $caseMaterial) {
                        ForEach(CaseMaterial.allCases) { material in
                            Text(material.displayName).tag(material)
                        }
                    }
                }
                .listRowBackground(Color.vaultSurface)

                Section {
                    Text("This watch will be moved from your wishlist to your main collection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.vaultSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.vaultBackground)
            .navigationTitle("Move to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Collection") { save() }
                        .disabled(!canSave)
                        .foregroundStyle(canSave ? Color.champagne : .gray)
                }
            }
        }
    }

    private func save() {
        guard let price = Double(purchasePrice) else { return }
        watch.isInWishlist = false
        watch.purchasePrice = price
        watch.purchaseDate = purchaseDate
        watch.movementType = movementType
        watch.caseMaterial = caseMaterial
        dataManager.save()
        dismiss()
    }
}
