import SwiftUI

struct DeparturesView: View {
    @ObservedObject var store: DeparturesStore
    var maxRows: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            content
            footer
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "bus")
            Text(store.stopName)
                .font(.headline)
                .lineLimit(2)
            Spacer()
            if store.isLoading { ProgressView().controlSize(.small) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = store.errorMessage, store.departures.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                Button("Retry") { Task { await store.refresh() } }
            }
            .padding(.vertical, 4)
        } else if store.departures.isEmpty {
            Text(store.isLoading ? "Loading…" : "No departures listed.")
                .foregroundStyle(.secondary)
        } else {
            let rows = maxRows.map { Array(store.departures.prefix($0)) } ?? store.departures
            ForEach(rows) { DepartureRow(departure: $0) }
        }
    }

    private var footer: some View {
        HStack {
            if let updated = store.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
            }
            if store.errorMessage != nil, !store.departures.isEmpty {
                Image(systemName: "exclamationmark.triangle").help(store.errorMessage ?? "")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        HStack(spacing: 10) {
            Text(departure.routeName)
                .font(.system(.body, design: .rounded).weight(.bold))
                .frame(minWidth: 36)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(red: 0.55, green: 0.0, blue: 0.1)))
                .foregroundStyle(.white)
            Text(departure.destination)
                .lineLimit(1)
            Spacer(minLength: 8)
            Circle()
                .fill(departure.isLive ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 7, height: 7)
                .help(departure.isLive ? "Live (tracked bus)" : "Timetabled")
            Text(departure.countdownText)
                .monospacedDigit()
                .frame(minWidth: 52, alignment: .trailing)
        }
    }
}
