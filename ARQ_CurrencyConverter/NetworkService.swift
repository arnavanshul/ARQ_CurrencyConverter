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
        
#if DEBUG
        if false {
            let tickerJsonData = """
            [
                {
                    "ask": "17.3100000000",
                    "bid": "17.3072000000",
                    "book": "usdc_mxn",
                    "date": "2026-04-20T18:21:32.195775440"
                },
                {
                    "ask": "3616.4868000000",
                    "bid": "3577.1800000000",
                    "book": "usdc_cop",
                    "date": "2026-04-20T18:21:32.141949648"
                },
                {
                    "ask": "5.0003775000",
                    "bid": "4.9499260000",
                    "book": "usdc_brl",
                    "date": "2026-04-20T18:21:32.148390888"
                },
                {
                    "ask": "1461.8800000000",
                    "bid": "1456.1804250000",
                    "book": "usdc_ars",
                    "date": "2026-04-20T18:21:32.198939054"
                }
            ]
            """
            guard let data = tickerJsonData.data(using: .utf8) else { fatalError("Unable to convert string to Data") }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TickerResponse.self, from: data)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion(.success(response)) }
            } catch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion(.failure(.noData)) }
            }
            return
        }
#endif // DEBUG
        
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
//        let staticDebugResponse = ["MXN", "ARS", "BRL", "COP", "EURc"]
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
