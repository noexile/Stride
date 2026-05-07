import SwiftUI
import SwiftData

struct ShoeDetailView: View {
    let shoe: Shoe
    @State private var showingEdit = false

    var body: some View {
        List {
            Section("Mileage") {
                MileageProgressRow(shoe: shoe)
            }

            Section("Details") {
                LabeledContent("Purchase date", value: shoe.purchaseDate, format: .dateTime.day().month().year())
                LabeledContent("Threshold", value: shoe.mileageThreshold, format: .number.precision(.fractionLength(0)).grouping(.automatic))
                    .badge("mi")
                LabeledContent("Status", value: shoe.status.rawValue.capitalized)
                if let notes = shoe.notes {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Assigned runs (\(shoe.assignments.count))") {
                if shoe.assignments.isEmpty {
                    Text("No runs assigned yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(shoe.assignments.sorted { $0.run.startDate > $1.run.startDate }) { assignment in
                        AssignedRunRow(assignment: assignment)
                    }
                }
            }
        }
        .navigationTitle(shoe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditShoeView(shoe: shoe)
        }
    }
}

// MARK: - Mileage progress

private struct MileageProgressRow: View {
    let shoe: Shoe

    private var progress: Double { min(shoe.totalMileage / shoe.mileageThreshold, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", shoe.totalMileage))
                    .font(.title.bold())
                Text("/ \(Int(shoe.mileageThreshold)) mi")
                    .foregroundStyle(.secondary)
                Spacer()
                warningLabel
            }
            ProgressView(value: progress)
                .tint(progressTint)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var warningLabel: some View {
        switch shoe.warningState {
        case .ok:
            EmptyView()
        case .approaching:
            Label("Approaching", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.yellow)
        case .exceeded:
            Label("Exceeded", systemImage: "exclamationmark.octagon.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
        }
    }

    private var progressTint: Color {
        switch shoe.warningState {
        case .ok: .blue
        case .approaching: .yellow
        case .exceeded: .red
        }
    }
}

// MARK: - Assigned run row

private struct AssignedRunRow: View {
    let assignment: ShoeRunAssignment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.2f mi", assignment.run.distanceMiles))
                    .font(.headline)
                Text(assignment.run.startDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let source = assignment.run.sourceName {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShoeDetailView(shoe: Shoe(name: "Preview Shoe", mileageThreshold: 400))
    }
    .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
