//
//  AddShoeView.swift
//  Stride
//

import SwiftUI
import SwiftData

struct AddShoeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var purchaseDate = Date.now
    @State private var mileageThreshold = 400.0

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shoe") {
                    TextField("Name (e.g. Nike Pegasus 41)", text: $name)
                        .autocorrectionDisabled()
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }

                Section("Mileage Threshold") {
                    Stepper(
                        value: $mileageThreshold,
                        in: 100...1000,
                        step: 50
                    ) {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            Text("\(Int(mileageThreshold)) mi")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Shoe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let shoe = Shoe(
            name: trimmedName,
            purchaseDate: purchaseDate,
            mileageThreshold: mileageThreshold
        )
        modelContext.insert(shoe)
        dismiss()
    }
}

#Preview {
    AddShoeView()
        .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
