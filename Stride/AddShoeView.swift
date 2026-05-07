//
//  AddShoeView.swift
//  Stride
//

import SwiftUI
import SwiftData

@Observable
final class AddShoeViewModel {
    var name = ""
    var purchaseDate = Date.now
    var mileageThreshold: Double

    init(defaults: UserDefaults = .standard) {
        let stored = defaults.double(forKey: UserDefaultsKeys.defaultThreshold)
        self.mileageThreshold = stored == 0 ? 400.0 : stored
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    var canSave: Bool { !trimmedName.isEmpty }

    func save(context: ModelContext) {
        let shoe = Shoe(
            name: trimmedName,
            purchaseDate: purchaseDate,
            mileageThreshold: mileageThreshold
        )
        context.insert(shoe)
    }
}

struct AddShoeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddShoeViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Shoe") {
                    TextField("Name (e.g. Nike Pegasus 41)", text: $viewModel.name)
                        .autocorrectionDisabled()
                    DatePicker("Purchase Date", selection: $viewModel.purchaseDate, displayedComponents: .date)
                }

                Section("Mileage Threshold") {
                    Stepper(
                        value: $viewModel.mileageThreshold,
                        in: 100...1000,
                        step: 50
                    ) {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            Text("\(Int(viewModel.mileageThreshold)) mi")
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
                    Button("Save") {
                        viewModel.save(context: modelContext)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview {
    AddShoeView()
        .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
