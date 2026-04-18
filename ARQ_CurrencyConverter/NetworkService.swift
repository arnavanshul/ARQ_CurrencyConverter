//
//  NetworkService.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation

protocol NetworkServiceProtocol: AnyObject {
    func fetchRates(currencies: [Currency], completion: @escaping (Result<TickerResponse, NetworkError>) -> Void)
    func fetchAvailableCurrencies(completion: @escaping (Result<[String], NetworkError>) -> Void) 
}

// MARK: - API Components
enum APIConfig {
    static let scheme = "https"
    static let domain = "api.dolarapp.dev"
}

enum APIEndpoint: String {
    case tickers = "/v1/tickers"
    case tickersCurrencies = "/v1/tickers-currencies"
}

enum APIParameter: String {
    case currencies = "currencies"
}

struct TickerResponse: Decodable {
    let tickers: [Ticker]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.tickers = try container.decode([Ticker].self)
    }
}

class NetworkService: NetworkServiceProtocol {
//    private let endpoint = "https://api.dolarapp.dev/v1/tickers"
    
    private func buildURL(for endpoint: APIEndpoint, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = APIConfig.scheme
        components.host = APIConfig.domain
        components.path = endpoint.rawValue
        components.queryItems = queryItems
        return components.url
    }
    
    func fetchRates(currencies: [Currency], completion: @escaping (Result<TickerResponse, NetworkError>) -> Void) {
        let queryValue = currencies.map { $0.rawValue }.joined(separator: ",")
        let queryItems = [URLQueryItem(name: APIParameter.currencies.rawValue, value: queryValue)]
        
        guard let url = buildURL(for: .tickers, queryItems: queryItems) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle transport errors
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.transportError(error))) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async { completion(.failure(.serverError(httpResponse.statusCode))) }
                return
            }
            
            // Ensure data exists
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.noData)) }
                return
            }
            // 3. Decoding logic
            do {
                let decodedResponse = try JSONDecoder().decode(TickerResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(decodedResponse)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
            }
        }.resume()
    }
    
    func fetchAvailableCurrencies(completion: @escaping (Result<[String], NetworkError>) -> Void) {
        guard let url = buildURL(for: .tickersCurrencies) else {
            completion(.failure(.invalidURL))
            return
        }
        
#if DEBUG
        // Simulate a successful API response for testing
        let staticDebugResponse = ["MXN", "ARS", "BRL", "COP"]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(staticDebugResponse))
        }
        return
#endif // DEBUG
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.transportError(error))) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async { completion(.failure(.serverError(httpResponse.statusCode))) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.noData)) }
                return
            }
            
            do {
                let currencyCodes = try JSONDecoder().decode([String].self, from: data)
                
                DispatchQueue.main.async { completion(.success(currencyCodes)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.decodingError(error))) }
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case transportError(Error)
    case serverError(Int)

    var localizedDescription: String {
        switch self {
        case .invalidURL: return "The URL provided was invalid."
        case .noData: return "No data was received from the server."
        case .decodingError(let error): return "Failed to process the response: \(error.localizedDescription)"
        case .transportError(let error): return "Network connection issue: \(error.localizedDescription)"
        case .serverError(let code): return "Server returned an error code: \(code)"
        }
    }
}
