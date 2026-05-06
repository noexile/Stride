//
//  ContentView.swift
//  Stride
//
//  Created by Alexander Zorov on 6.05.26.
//

import SwiftUI
import SwiftData

struct ShoeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shoe.purchaseDate, order: .reverse) private var shoes: [Shoe]
    @State private var showingAddShoe = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(shoes) { shoe in
                    ShoeRowView(shoe: shoe)
                }
                .onDelete(perform: deleteShoes)
            }
            .navigationTitle("My Shoes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddShoe = true
                    } label: {
                        Label("Add Shoe", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddShoe) {
                AddShoeView()
            }
            .overlay {
                if shoes.isEmpty {
                    ContentUnavailableView(
                        "No Shoes",
                        systemImage: "shoeprints.fill",
                        description: Text("Tap + to add your first shoe.")
                    )
                }
            }
        }
    }

    private func deleteShoes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(shoes[index])
            }
        }
    }
}

private struct ShoeRowView: View {
    let shoe: Shoe

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shoe.name)
                    .font(.headline)
                Text(mileageLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            warningBadge
        }
        .padding(.vertical, 4)
    }

    private var mileageLabel: String {
        let total = shoe.totalMileage
        let threshold = shoe.mileageThreshold
        return String(format: "%.0f / %.0f mi", total, threshold)
    }

    @ViewBuilder
    private var warningBadge: some View {
        switch shoe.warningState {
        case .ok:
            EmptyView()
        case .approaching:
            Label("Approaching", systemImage: "exclamationmark.triangle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.yellow)
                .imageScale(.large)
        case .exceeded:
            Label("Exceeded", systemImage: "exclamationmark.octagon.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.red)
                .imageScale(.large)
        }
    }
}

#Preview {
    ShoeListView()
        .modelContainer(for: [Shoe.self, Run.self, ShoeRunAssignment.self], inMemory: true)
}
