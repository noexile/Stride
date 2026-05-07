import SwiftUI
import SwiftData

// MARK: - ViewModel

@Observable
final class EditShoeViewModel {
    var name: String
    var purchaseDate: Date
    var mileageThreshold: Double
    var status: ShoeStatus
    var notes: String

    init(shoe: Shoe) {
        self.name = shoe.name
        self.purchaseDate = shoe.purchaseDate
        self.mileageThreshold = shoe.mileageThreshold
        self.status = shoe.status
        self.notes = shoe.notes ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    var canSave: Bool { !trimmedName.isEmpty }

    func applyChanges(to shoe: Shoe) {
        shoe.name = trimmedName
        shoe.purchaseDate = purchaseDate
        shoe.mileageThreshold = mileageThreshold
        shoe.status = status
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        shoe.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
    }
}

// MARK: - View

struct EditShoeView: View {
    @Environment(\.dismiss) private var dismiss
    let shoe: Shoe
    @State private var viewModel: EditShoeViewModel

    init(shoe: Shoe) {
        self.shoe = shoe
        self._viewModel = State(initialValue: EditShoeViewModel(shoe: shoe))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shoe") {
                    TextField("Name (e.g. Nike Pegasus 41)", text: $viewModel.name)
                        .autocorrectionDisabled()
                    DatePicker(
                        "Purchase Date",
                        selection: $viewModel.purchaseDate,
                        displayedComponents: .date
                    )
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

                Section("Status") {
                    Toggle(
                        "Active",
                        isOn: Binding(
                            get: { viewModel.status == .active },
                            set: { viewModel.status = $0 ? .active : .retired }
                        )
                    )
                }

                Section("Notes") {
                    TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Shoe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.applyChanges(to: shoe)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditShoeView(shoe: Shoe(name: "Preview Shoe", mileageThreshold: 400))
    }
    .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
