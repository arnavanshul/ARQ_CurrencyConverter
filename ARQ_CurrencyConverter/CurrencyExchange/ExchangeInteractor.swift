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
    
    func calculateConversion(amount: Double,
                             sourceCurrency: Currency,
                             targetCurrency: Currency,
                             baseCurrency: Currency,
                             isBuyingQuote: Bool)
}

protocol ExchangeInteractorOutputProtocol: AnyObject {
    func didFetchRates(tickers: [Ticker]?)
    func didFetchAvailableCurrencies(currencies: [Currency])
    func didFailToFetchData(error: NetworkError, context: FetchContext)
    
    func didCalculateConversion(result: Double, sourceAmount: Double, ticker: Ticker, isSourceBase: Bool)
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
                self?.processResponse(availableCurrencies: codes)
                self?.fetchCurrencyExchangeRates(currencies: self?.availableCurrencies ?? [])
            case .failure(let error):
                self?.output?.didFailToFetchData(error: error, context: .availableCurrencies)
            }
        }
    }
    
    func fetchCurrencyExchangeRates(currencies: [Currency]) {
        let currenciesToFetch = currencies.isEmpty ? availableCurrencies : currencies
        networkService.fetchRates(currencies: currenciesToFetch) { [weak self] result in
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
        self.availableCurrencies = response.compactMap { Currency(rawValue: $0) }
    }
    
    func calculateConversion(amount: Double, sourceCurrency: Currency, targetCurrency: Currency, baseCurrency: Currency, isBuyingQuote: Bool) {
        let isSourceBase = (sourceCurrency == baseCurrency)
        let quoteCurrency = sourceCurrency == baseCurrency ? targetCurrency : sourceCurrency
        
        guard let ticker = tickerMap[quoteCurrency] else { return }
        
        let bid = Double(ticker.bid) ?? 0.0
        let ask = Double(ticker.ask) ?? 0.0
        
        let rate = isBuyingQuote ? bid : ask
        
        let result: Double
        if isSourceBase {
            result = amount * rate
        } else {
            result = amount / rate
        }
        
        output?.didCalculateConversion(result: result,
                                       sourceAmount: amount,
                                       ticker: ticker,
                                       isSourceBase: isSourceBase)
    }
}
