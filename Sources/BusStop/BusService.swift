import Foundation

enum BusServiceError: LocalizedError {
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "Bus data server returned HTTP \(code)."
        }
    }
}

/// bustimes.org, which merges Lothian timetables with live tracking.
/// (The Transport for Edinburgh open data API at tfe-opendata.com no longer responds.)
struct BusService {
    var baseURL = URL(string: "https://bustimes.org/")!
    var session = URLSession.shared

    /// Lothian area, for the stop picker.
    private static let areaQuery = "xmin=-3.50&ymin=55.80&xmax=-2.85&ymax=56.02"

    func departures(atcoCode: String) async throws -> [Departure] {
        let response: TimesResponse = try await get("stops/\(atcoCode)/times.json?limit=20")
        return response.times.sorted { $0.departureDate < $1.departureDate }
    }

    func stops() async throws -> [Stop] {
        let response: StopsResponse = try await get("stops.json?\(Self.areaQuery)")
        return response.stops
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.timeoutInterval = 20
        request.setValue("BusStopDesktopApp/1.0 (personal macOS menu bar app)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BusServiceError.badStatus(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
