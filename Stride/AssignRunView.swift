import SwiftUI
import SwiftData

struct AssignRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Shoe.name) private var shoes: [Shoe]

    let run: Run

    var body: some View {
        NavigationStack {
            List {
                if run.assignment != nil {
                    Section {
                        Button("Unassign from shoe", role: .destructive) {
                            unassign()
                        }
                    }
                }

                Section("Assign to shoe") {
                    let activeShoes = shoes.filter { $0.status == .active }
                    if activeShoes.isEmpty {
                        Text("No active shoes — add one in the Shoes tab.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeShoes) { shoe in
                            Button { assign(to: shoe) } label: {
                                ShoePickerRow(shoe: shoe, isSelected: run.assignment?.shoe === shoe)
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Assign Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func assign(to shoe: Shoe) {
        if let existing = run.assignment {
            modelContext.delete(existing)
        }
        modelContext.insert(ShoeRunAssignment(shoe: shoe, run: run))
        dismiss()
    }

    private func unassign() {
        if let existing = run.assignment {
            modelContext.delete(existing)
        }
        dismiss()
    }
}

private struct ShoePickerRow: View {
    let shoe: Shoe
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shoe.name)
                    .foregroundStyle(.primary)
                Text(String(format: "%.0f / %.0f mi", shoe.totalMileage, shoe.mileageThreshold))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
    }
}
