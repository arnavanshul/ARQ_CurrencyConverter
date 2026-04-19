//
//  ExchangeInteractor.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation
import UIKit

enum FetchContext {
    case availableCurrencies
    case exchangeRates
}

protocol ExchangeInteractorInputProtocol: AnyObject {
    var output: ExchangeInteractorOutputProtocol? { get set }
    func fetchCurrencyExchangeRates(currencies: [Currency])
    func fetchAvailableCurrencies()
    func fetchInitialData()
}

protocol ExchangeInteractorOutputProtocol: AnyObject {
    func didFetchRates(tickers: [Ticker]?)
    func didFetchAvailableCurrencies(currencies: [Currency])
    func didFailToFetchData(error: NetworkError, context: FetchContext)
    func didFinishCalculation()
}

class ExchangeInteractor {
    weak var output: ExchangeInteractorOutputProtocol?
    
    private let networkService: NetworkServiceProtocol
    
    var tickers: [Ticker] = []
    var availableCurrencies: [Currency] = []
    
    private var tickerMap: [Currency: Ticker] = [:]
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
}

extension ExchangeInteractor: ExchangeInteractorInputProtocol {
    func fetchInitialData() {
        networkService.fetchAvailableCurrencies { [weak self] result in
            switch result {
            case .success(let codes):
                self?.availableCurrencies = codes.compactMap { Currency(rawValue: $0) }
                self?.fetchCurrencyExchangeRates(currencies: self?.availableCurrencies ?? [])
            case .failure(let error):
                self?.output?.didFailToFetchData(error: error, context: .availableCurrencies)
            }
        }
    }
    
    func fetchCurrencyExchangeRates(currencies: [Currency]) {
        let currenciesToFetch = currencies.isEmpty ? availableCurrencies : currencies
        networkService.fetchRates(currencies: currencies) { [weak self] result in
            switch result {
            case .success(let response):
                print(response)
                self?.processResponse(exchangeRates: response)
                self?.output?.didFetchRates(tickers: self?.tickers)
            case .failure(let error):
                print(error)
                self?.output?.didFailToFetchData(error: error, context: .exchangeRates)
            }
        }
    }
    
    func processResponse(exchangeRates response: TickerResponse) {
        tickers = response.tickers
        tickerMap = tickers.reduce(into: [:]) { map, ticker in
            if let code = ticker.currency {
                map[code] = ticker
            }
        }
    }
    
    func fetchAvailableCurrencies() {
        networkService.fetchAvailableCurrencies { [weak self] result in
            switch result {
            case .success(let response):
                print(response)
                self?.processResponse(availableCurrencies: response)
                self?.output?.didFetchAvailableCurrencies(currencies: self?.availableCurrencies ?? [])
            case .failure(let error):
                print(error)
                self?.output?.didFailToFetchData(error: error, context: .availableCurrencies)
            }
        }
    }
    
    func processResponse(availableCurrencies response: [String]) {
        availableCurrencies = response.compactMap { Currency(rawValue: $0) }
        fetchCurrencyExchangeRates(currencies: availableCurrencies)
    }
}
