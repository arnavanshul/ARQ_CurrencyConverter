//
//  ExchangeInteractor.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation
import UIKit

protocol ExchangeInteractorInputProtocol: AnyObject {
    var output: ExchangeInteractorOutputProtocol? { get set }
    func fetchCurrencyExchangeRates()
    func fetchAvailableCurrencies()
}

protocol ExchangeInteractorOutputProtocol: AnyObject {
    func didFetchRates(tickers: [Ticker]?)
    func didFailWithError()
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
    func fetchCurrencyExchangeRates() {
        networkService.fetchRates(currencies: availableCurrencies) { [weak self] result in
            switch result {
            case .success(let response):
                print(response)
                self?.processResponse(exchangeRates: response)
                self?.output?.didFetchRates(tickers: self?.tickers)
            case .failure(let error):
                print(error)
                self?.output?.didFailWithError()
            }
        }
    }
    
    func fetchAvailableCurrencies() {
        networkService.fetchAvailableCurrencies { [weak self] result in
            switch result {
            case .success(let response):
                print(response)
                self?.processResponse(availableCurrencies: response)
            case .failure(let error):
                print(error)
                self?.output?.didFailWithError()
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
    
    func processResponse(availableCurrencies response: [String]) {
        availableCurrencies = response.compactMap { Currency(rawValue: $0) }
        fetchCurrencyExchangeRates()
    }
}
