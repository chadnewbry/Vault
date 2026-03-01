import Foundation

/// Protocol for market data providers. Implement to integrate with watch market APIs.
protocol MarketDataProvider {
    /// Fetch the current market price for a watch by reference number.
    /// Returns nil if no data available. Throws on network/API errors.
    func fetchPrice(referenceNumber: String) async throws -> Double?
}

/// Stub provider that always returns nil. Replace with a real API integration
/// (e.g., WatchCharts, Chrono24 affiliate) when API access is available.
struct StubMarketDataProvider: MarketDataProvider {
    func fetchPrice(referenceNumber: String) async throws -> Double? {
        return nil
    }
}

/// Example provider skeleton for WatchCharts or similar API.
/// Uncomment and configure when API key is available.
/*
struct WatchChartsProvider: MarketDataProvider {
    let apiKey: String
    let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchPrice(referenceNumber: String) async throws -> Double? {
        let encoded = referenceNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? referenceNumber
        guard let url = URL(string: "https://api.watchcharts.com/v1/watches/search?ref=\(encoded)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: request)
        // Parse response — adapt to actual API schema
        struct Response: Decodable {
            struct Watch: Decodable { let marketPrice: Double? }
            let results: [Watch]
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.results.first?.marketPrice
    }
}
*/
