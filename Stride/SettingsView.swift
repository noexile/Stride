//
//  SettingsView.swift
//  Stride
//

import SwiftUI

@Observable
final class SettingsViewModel {
    private let key = "settings.defaultThreshold"

    var defaultThreshold: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: key)
            return stored == 0 ? 400.0 : stored
        }
        set {
            UserDefaults.standard.set(newValue.clamped(to: 100...1000), forKey: key)
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = SettingsViewModel()

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New Shoe Defaults") {
                    Stepper(
                        value: Binding(
                            get: { vm.defaultThreshold },
                            set: { vm.defaultThreshold = $0 }
                        ),
                        in: 100...1000,
                        step: 50
                    ) {
                        HStack {
                            Text("Default Threshold")
                            Spacer()
                            Text("\(Int(vm.defaultThreshold)) mi")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link("Privacy Policy", destination: URL(string: "https://github.com/noexile/Stride")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
