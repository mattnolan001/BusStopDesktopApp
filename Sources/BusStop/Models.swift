import Foundation

/// Response of bustimes.org `GET /stops/{atco}/times.json`.
struct TimesResponse: Decodable {
    let times: [Departure]
}

struct Departure: Decodable, Identifiable {
    let id: Int
    let routeName: String
    let destination: String
    let scheduled: Date
    let expected: Date?

    /// A tracked bus has an expected time; otherwise it's the timetable.
    var isLive: Bool { expected != nil }
    var departureDate: Date { expected ?? scheduled }

    var minutes: Int { max(0, Int(departureDate.timeIntervalSinceNow / 60)) }

    var countdownText: String {
        switch minutes {
        case 0: return "Due"
        case 1..<60: return "\(minutes) min"
        default: return departureDate.formatted(date: .omitted, time: .shortened)
        }
    }

    init(id: Int, routeName: String, destination: String, scheduled: Date, expected: Date? = nil) {
        self.id = id
        self.routeName = routeName
        self.destination = destination
        self.scheduled = scheduled
        self.expected = expected
    }

    private struct Service: Decodable { let line_name: String }
    private struct Destination: Decodable { let name: String }

    private enum CodingKeys: String, CodingKey {
        case id, service, destination
        case aimed_departure_time, expected_departure_time, aimed_arrival_time, expected_arrival_time
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        routeName = try c.decode(Service.self, forKey: .service).line_name
        destination = try c.decode(Destination.self, forKey: .destination).name
        let aimed = try c.decodeIfPresent(Date.self, forKey: .aimed_departure_time)
            ?? c.decodeIfPresent(Date.self, forKey: .aimed_arrival_time)
        guard let aimed else {
            throw DecodingError.dataCorruptedError(forKey: .aimed_departure_time, in: c,
                                                   debugDescription: "No departure or arrival time")
        }
        scheduled = aimed
        expected = try c.decodeIfPresent(Date.self, forKey: .expected_departure_time)
            ?? c.decodeIfPresent(Date.self, forKey: .expected_arrival_time)
    }
}

/// GeoJSON response of bustimes.org `GET /stops.json?xmin=…&ymin=…&xmax=…&ymax=…`.
struct StopsResponse: Decodable {
    let features: [Feature]

    struct Feature: Decodable {
        let properties: Properties
    }

    struct Properties: Decodable {
        let name: String
        let indicator: String?
        let bearing: Double?
        let url: String
        let services: [String]?
    }

    var stops: [Stop] {
        features.compactMap { f in
            let p = f.properties
            guard p.url.hasPrefix("/stops/") else { return nil }
            return Stop(atcoCode: String(p.url.dropFirst("/stops/".count)), name: p.name,
                        indicator: p.indicator, bearing: p.bearing, services: p.services ?? [])
        }
    }
}

struct Stop: Identifiable, Hashable {
    let atcoCode: String
    let name: String
    let indicator: String?
    let bearing: Double?
    let services: [String]

    var id: String { atcoCode }

    /// Compass direction buses travel from this stop, e.g. "SW".
    var direction: String? {
        guard let bearing else { return nil }
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return points[Int((bearing / 45).rounded()) % 8]
    }

    var displayName: String {
        var s = name
        if let indicator, !indicator.isEmpty, !name.contains(indicator) { s += " (\(indicator))" }
        if let direction { s += " \(direction)" }
        return s
    }
}
