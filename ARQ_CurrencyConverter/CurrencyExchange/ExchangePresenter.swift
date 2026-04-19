//
//  ExchangePresenter.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation
import UIKit

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
    func didTapCurrency(updatedField: UpdatedField)
    func didSelectCurrency(ticker: Ticker)
}

class ExchangePresenter {
    weak var view: CurrencyExchangeViewProtocol?
    var interactor: ExchangeInteractorInputProtocol?
    var router: ExchangeRouterProtocol?
    
    let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter
    }()
    
    var exchangeRates: [Currency : Ticker] = [:]
    
    private var exchangeViewState: ExchangeViewState? = nil
    
    init(view: CurrencyExchangeViewProtocol? = nil, interactor: ExchangeInteractorInputProtocol? = nil, router: ExchangeRouterProtocol? = nil) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }
    
    func setupViewListeners() {
        view?.exchangeView.topCurrencyField.onCurrencyPressed = { [weak self] in
            self?.didTapCurrency(updatedField: .top)
        }
        
        view?.exchangeView.topCurrencyField.onAmountChanged = { [weak self] text in
            self?.didChangeAmount(updatedField: .top, newText: text)
        }
        
        view?.exchangeView.bottomCurrencyField.onCurrencyPressed = { [weak self] in
            self?.didTapCurrency(updatedField: .bottom)
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
                self.updateExchangeView(with: state, ticker: ticker)
            }
        }
    }
}

extension ExchangePresenter: ExchangePresenterProtocol {
    func viewDidLoad() {
        view?.showLoading()
        interactor?.fetchInitialData()
    }
    
    func didTapCurrency(updatedField: UpdatedField) {
        switch updatedField {
        case .top:
            guard let view, let state = exchangeViewState, state.topCurrency != state.baseCurrency else { return }
            router?.presentCurrencyPicker(from: view,
                                          tickers: state.tickers,
                                          currentCode: state.topCurrency.rawValue,
                                          presenter: self)
        case .bottom:
            guard let view, let state = exchangeViewState, state.bottomCurrency != state.baseCurrency else { return }
            router?.presentCurrencyPicker(from: view,
                                          tickers: state.tickers,
                                          currentCode: state.bottomCurrency.rawValue,
                                          presenter: self)
        case .none:
            return
        }
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
        guard let ticker = exchangeRates[quoteCurrency] else { return }
        
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
        updateExchangeView(with: state, ticker: ticker)
    }
    
    func didChangeAmount(updatedField: UpdatedField, newText: String) {
        guard var state = exchangeViewState else { return }
        let sanitizedText = newText.replacingOccurrences(of: ",", with: "")
        let updatedValue = amountFormatter.number(from: sanitizedText)?.doubleValue ?? 0.0
        let quoteCurrency = (state.topCurrency == state.baseCurrency) ? state.bottomCurrency : state.topCurrency
        guard let ticker = exchangeRates[quoteCurrency] else { return }
        
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
        updateExchangeView(with: state, ticker: ticker)
    }
}

extension ExchangePresenter {
    private func updateExchangeView(with state: ExchangeViewState, ticker: Ticker) {
        guard let view = view else { return }
        
        view.exchangeView.isHidden = false
        
        let rateStr = state.rateToUse == .buyingQuote ? ticker.ask : ticker.bid
        view.exchangeView.rateLabel.text = "1 \(state.baseCurrency.rawValue) = \(rateStr) \(state.topCurrency == state.baseCurrency ? state.bottomCurrency.rawValue : state.topCurrency.rawValue)"
        
        let rawRateStr = state.rateToUse == .buyingQuote ? ticker.ask : ticker.bid
        var formattedRate = rawRateStr // Fallback to raw string
        if let rateDouble = Double(rawRateStr) {
            formattedRate = format(value: rateDouble, maxPrecision: 6)
        }
        let quoteCurrencyCode = state.topCurrency == state.baseCurrency ? state.bottomCurrency.rawValue : state.topCurrency.rawValue
        view.exchangeView.rateLabel.text = "1 \(state.baseCurrency.rawValue) = \(formattedRate) \(quoteCurrencyCode)"
        
        if !view.exchangeView.topCurrencyField.isChangingAmount {
            view.exchangeView.topCurrencyField.updateFor(flag: state.topCurrency.flag,
                                                         code: state.topCurrency.rawValue,
                                                         value: self.format(value: state.topAmount, maxPrecision: 2),
                                                         symbol: state.topCurrency.currencySymbol,
                                                         showChevron: state.topCurrency != state.baseCurrency)
        }
        
        if !view.exchangeView.bottomCurrencyField.isChangingAmount {
            view.exchangeView.bottomCurrencyField.updateFor(flag: state.bottomCurrency.flag,
                                                            code: state.bottomCurrency.rawValue,
                                                            value: self.format(value: state.bottomAmount, maxPrecision: 2),
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
    
    func didFetchAvailableCurrencies(currencies: [Currency]) {}
    
    func didFailToFetchData(error: NetworkError, context: FetchContext) {
        view?.hideLoading()
        
        let message: String
        switch context {
        case .availableCurrencies:
            message = "Could not load the list of currencies. Try again later. \(error.localizedDescription)"
        case .exchangeRates:
            message = "Could not update the latest prices. Try again later \(error.localizedDescription)"
        }
        
        view?.showErrorMessage(message: message)
    }
}

// MARK: Convenience methods
extension ExchangePresenter {
    func format(value: Double, maxPrecision: Int) -> String {
        let isWholeNumber = value.truncatingRemainder(dividingBy: 1) == 0
        if isWholeNumber {
            self.amountFormatter.minimumFractionDigits = 0
            self.amountFormatter.maximumFractionDigits = maxPrecision
        } else {
            // 2. If it has ANY decimals (e.g., 10.1 or 10.05), show 2 to 6 places
            self.amountFormatter.minimumFractionDigits = 2
            self.amountFormatter.maximumFractionDigits = maxPrecision
        }
        
        self.amountFormatter.maximumFractionDigits = maxPrecision
        return self.amountFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
