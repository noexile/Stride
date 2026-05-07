import SwiftUI
import SwiftData

// MARK: - ViewModel

@Observable
final class RunsSyncViewModel {
    var isSyncing = false
    var errorMessage: String?

    private let service: HealthKitServiceProtocol

    init(service: HealthKitServiceProtocol = HealthKitService.shared) {
        self.service = service
    }

    func sync(context: ModelContext) async {
        isSyncing = true
        errorMessage = nil
        defer { isSyncing = false }
        do {
            try await service.requestAuthorization()
            _ = try await service.importNewRuns(into: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View

struct RunsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @State private var viewModel = RunsSyncViewModel()

    var body: some View {
        NavigationStack {
            List(runs) { run in
                RunRowView(run: run)
            }
            .navigationTitle("Runs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.sync(context: modelContext) }
                    } label: {
                        if viewModel.isSyncing {
                            ProgressView()
                        } else {
                            Label("Sync", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }
            }
            .overlay {
                if runs.isEmpty && !viewModel.isSyncing {
                    ContentUnavailableView(
                        "No Runs",
                        systemImage: "figure.run",
                        description: Text("Tap ↻ to import runs from HealthKit.")
                    )
                }
            }
            .alert("Sync Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Row

private struct RunRowView: View {
    let run: Run

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "%.2f mi", run.distanceMiles))
                    .font(.headline)
                Spacer()
                Text(run.startDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if let source = run.sourceName {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if let surface = run.wearSurface {
                    Text(surface.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    RunsView()
        .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
