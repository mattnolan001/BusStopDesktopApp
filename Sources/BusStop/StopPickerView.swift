import SwiftUI

struct StopPickerView: View {
    @ObservedObject var store: DeparturesStore
    var onDone: () -> Void

    // A plain ObservableObject rather than @State: the Command Line Tools lack the SwiftUI macro plugin.
    @StateObject private var model = Model()

    private final class Model: ObservableObject {
        @Published var query = ""
        @Published var loadError: String?
    }

    private var matches: [Stop] {
        let q = model.query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return store.allStops.filter {
            $0.name.localizedCaseInsensitiveContains(q)
                || $0.atcoCode == q
                || $0.services.contains { $0.caseInsensitiveCompare(q) == .orderedSame }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Search by stop name, bus number or stop code", text: $model.query)
                .textFieldStyle(.roundedBorder)
            if let loadError = model.loadError {
                Label(loadError, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
            } else if store.allStops.isEmpty {
                ProgressView("Loading stops…")
            }
            List(matches) { stop in
                Button {
                    store.select(stop)
                    onDone()
                } label: {
                    VStack(alignment: .leading) {
                        Text(stop.displayName)
                        if !stop.services.isEmpty {
                            Text("Buses: " + stop.services.joined(separator: ", "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(minWidth: 380, minHeight: 360)
        .task {
            do { try await store.loadStopsIfNeeded() } catch { model.loadError = error.localizedDescription }
        }
    }
}
