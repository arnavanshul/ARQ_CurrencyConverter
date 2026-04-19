//
//  ExchangePresenter.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation
import UIKit

enum ExchangeDataAvailabilityState {
    case loading
    case available
    case error
}

enum TransactionType {
    //  Base -> Quote
    //  Use `ask` price
    case buyingQuote
    
    //  Quote -> Base
    //  Use `bid` price
    case sellingQuote
}

enum UpdatedField {
    case top
    case bottom
    case none
}

fileprivate struct ExchangeViewState {
    var baseCurrency: Currency
    
    var topCurrency: Currency
    var topAmount: Double
    
    var bottomCurrency: Currency
    var bottomAmount: Double
    
    var rateToUse: TransactionType
    var lastUpdatedField: UpdatedField
    var tickers: [Ticker]
}

protocol ExchangePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapSwapButton()
    func didChangeAmount(updatedField: UpdatedField, newText: String)
    func didSelectCurrency(ticker: Ticker)
}

class ExchangePresenter {
    weak var view: CurrencyConverterViewProtocol?
    var interactor: ExchangeInteractorInputProtocol?
    var router: ExchangeRouterProtocol?
    
    var exchangeRates: [Currency : Ticker] = [:]
    
    private var exchangeViewState: ExchangeViewState? = nil
    
    init(view: CurrencyConverterViewProtocol? = nil, interactor: ExchangeInteractorInputProtocol? = nil, router: ExchangeRouterProtocol? = nil) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }
    
    func setupViewListeners() {
        view?.exchangeView.topCurrencyField.onCurrencyPressed = { [weak self] in
            self?.didTapTopCurrency()
        }
        
        view?.exchangeView.topCurrencyField.onAmountChanged = { [weak self] text in
            self?.didChangeAmount(updatedField: .top, newText: text)
        }
        
        view?.exchangeView.bottomCurrencyField.onCurrencyPressed = { [weak self] in
            self?.didTapBottomCurrency()
        }
        
        view?.exchangeView.bottomCurrencyField.onAmountChanged = { [weak self] text in
            self?.didChangeAmount(updatedField: .bottom, newText: text)
        }
        
        view?.exchangeView.onSwapButtonPressed = { [weak self] in
            self?.didTapSwapButton()
        }
    }
    
    func initializeView(for ticker: Ticker, tickers: [Ticker]) {
        guard let currency = ticker.currency else { return }
        
        let initialSourceValue = 99.0
        let rate = Double(ticker.bid) ?? 0.0
        
        exchangeViewState = ExchangeViewState(baseCurrency: .USDc,
                                              topCurrency: .USDc,
                                              topAmount: initialSourceValue,
                                              bottomCurrency: currency,
                                              bottomAmount: initialSourceValue * rate,
                                              rateToUse: .sellingQuote,
                                              lastUpdatedField: .none,
                                              tickers: tickers)
        
        DispatchQueue.main.async {
            if let state = self.exchangeViewState {
                self.view?.hideLoading()
                self.view?.hideErrorMessage()
                self.view?.exchangeView.isHidden = false
                self.updateView(with: state, ticker: ticker)
            }
        }
    }
}

extension ExchangePresenter: ExchangePresenterProtocol{
    func viewDidLoad() {
        view?.showLoading()
        interactor?.fetchInitialData()
        setupViewListeners()
    }
    
    func didSelectCurrency(ticker: Ticker) {
        guard let state = exchangeViewState else { return }
        initializeView(for: ticker, tickers: state.tickers)
    }
    
    func didTapSwapButton() {
        guard var state = exchangeViewState else { return }
        
        let baseCurrencyAmount = state.topCurrency == state.baseCurrency ? state.topAmount : state.bottomAmount
        state.rateToUse = (state.rateToUse == .buyingQuote) ? .sellingQuote : .buyingQuote
        
        let quoteCurrency = (state.topCurrency == state.baseCurrency) ? state.bottomCurrency : state.topCurrency
        guard let ticker = state.tickers.first(where: { $0.currency == quoteCurrency }) else { return }
        
        let ask = Double(ticker.ask) ?? 0.0
        let bid = Double(ticker.bid) ?? 0.0
        
        let newQuoteAmount: Double
        let rateToUse = state.rateToUse == .buyingQuote ? ask : bid
        newQuoteAmount = baseCurrencyAmount * rateToUse
        
        let tempCurrency = state.topCurrency
        state.topCurrency = state.bottomCurrency
        state.bottomCurrency = tempCurrency
        
        if state.topCurrency == state.baseCurrency {
            state.topAmount = baseCurrencyAmount
            state.bottomAmount = newQuoteAmount
        } else {
            state.bottomAmount = baseCurrencyAmount
            state.topAmount = newQuoteAmount
        }
        
        self.exchangeViewState = state
        updateView(with: state, ticker: ticker)
    }
    
    func didChangeAmount(updatedField: UpdatedField, newText: String) {
        guard var state = exchangeViewState else { return }
        
        let updatedValue = Double(newText) ?? 0.0
        let quoteCurrency = (state.topCurrency == state.baseCurrency) ? state.bottomCurrency : state.topCurrency
        guard let ticker = state.tickers.first(where: { $0.currency == quoteCurrency }) else { return }
        
        if updatedField == .top {
            state.topAmount = updatedValue
            
            if state.topCurrency == state.baseCurrency {
                state.bottomAmount = updatedValue * (Double(ticker.bid) ?? 0.0)
            } else {
                state.bottomAmount = updatedValue / (Double(ticker.ask) ?? 0.0)
            }
            
        } else if updatedField == .bottom {
            state.bottomAmount = updatedValue
            
            if state.bottomCurrency == state.baseCurrency {
                state.topAmount = updatedValue * (Double(ticker.ask) ?? 0.0)
            } else {
                state.topAmount = updatedValue / (Double(ticker.bid) ?? 0.0)
            }
        }
        exchangeViewState = state
        updateView(with: state, ticker: ticker)
    }
}

extension ExchangePresenter {
    private func updateView(with state: ExchangeViewState, ticker: Ticker) {
        guard let view = view else { return }
        
        let rateStr = state.rateToUse == .buyingQuote ? ticker.ask : ticker.bid
        view.exchangeView.rateLabel.text = "1 \(state.baseCurrency.rawValue) = \(rateStr) \(state.topCurrency == state.baseCurrency ? state.bottomCurrency.rawValue : state.topCurrency.rawValue)"
        
        if !view.exchangeView.topCurrencyField.isChangingAmount {
            view.exchangeView.topCurrencyField.updateFor(flag: state.topCurrency.flag,
                                                         code: state.topCurrency.rawValue,
                                                         value: String(format: "%.2f", state.topAmount),
                                                         symbol: state.topCurrency.currencySymbol,
                                                         showChevron: state.topCurrency != state.baseCurrency)
        }
        
        if !view.exchangeView.bottomCurrencyField.isChangingAmount {
            view.exchangeView.bottomCurrencyField.updateFor(flag: state.bottomCurrency.flag,
                                                            code: state.bottomCurrency.rawValue,
                                                            value: String(format: "%.2f", state.bottomAmount),
                                                            symbol: state.bottomCurrency.currencySymbol,
                                                            showChevron: state.bottomCurrency != state.baseCurrency)
        }
    }
}

extension ExchangePresenter: ExchangeInteractorOutputProtocol {
    func didFetchRates(tickers: [Ticker]?) {
        guard let tickers = tickers,
              let firstTicker = tickers.first else {
            return
        }
        
        for ticker in tickers {
            if let currency = ticker.currency {
                exchangeRates[currency] = ticker
            }
        }
        
        initializeView(for: firstTicker, tickers: tickers)
    }
    
    func didFetchAvailableCurrencies(currencies: [Currency]) {
        
    }
    
    func didFailToFetchData(error: NetworkError, context: FetchContext) {
        view?.hideLoading()
        let message: String
        
        switch context {
        case .availableCurrencies:
            message = "Could not load the list of currencies. \(error.localizedDescription)"
        case .exchangeRates:
            message = "could not update the latest prices. \(error.localizedDescription)"
        }
        
        view?.showErrorMessage(message: message)
    }
    
    func didFinishCalculation() {
        
    }
    
    func didTapTopCurrency() {
        guard let view, let state = exchangeViewState, state.topCurrency != state.baseCurrency else { return }
        router?.presentCurrencyPicker(from: view,
                                      tickers: state.tickers,
                                      currentCode: state.topCurrency.rawValue,
                                      presenter: self)
    }
    
    func didTapBottomCurrency() {
        guard let view, let state = exchangeViewState, state.bottomCurrency != state.baseCurrency else { return }
        router?.presentCurrencyPicker(from: view,
                                      tickers: state.tickers,
                                      currentCode: state.bottomCurrency.rawValue,
                                      presenter: self)
    }
}


