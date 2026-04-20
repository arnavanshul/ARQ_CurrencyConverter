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
    //  Use `ask` price (almost always more than the bid price)
    case buyingQuote
    
    //  Quote -> Base
    //  Use `bid` price (almost always less than the bid price)
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
}

// MARK: ExchangePresenterProtocol (user interaction handling methods)
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
        
        let baseAmount = state.topCurrency == state.baseCurrency ? state.topAmount : state.bottomAmount
        
        let tempCurrency = state.topCurrency
        state.topCurrency = state.bottomCurrency
        state.bottomCurrency = tempCurrency
        
        state.rateToUse = state.rateToUse == .buyingQuote ? .sellingQuote : .buyingQuote
        
        self.exchangeViewState = state
        
        interactor?.calculateConversion(amount: baseAmount,
                                        sourceCurrency: state.baseCurrency,
                                        targetCurrency: state.topCurrency == state.baseCurrency ? state.bottomCurrency : state.topCurrency,
                                        baseCurrency: state.baseCurrency,
                                        isBuyingQuote: state.rateToUse == .buyingQuote)
    }
    
    func didChangeAmount(updatedField: UpdatedField, newText: String) {
        guard let state = exchangeViewState else { return }
        
        let sanitizedText = newText.replacingOccurrences(of: ",", with: "")
        let updatedValue = amountFormatter.number(from: sanitizedText)?.doubleValue ?? 0.0
        
        let source: Currency
        let target: Currency
        
        let isBuyingQuote = state.topCurrency == state.baseCurrency ? true : false
        
        if updatedField == .top {
            source = state.topCurrency
            target = state.bottomCurrency
        } else {
            source = state.bottomCurrency
            target = state.topCurrency
        }
        
        interactor?.calculateConversion(amount: updatedValue, sourceCurrency: source, targetCurrency: target, baseCurrency: state.baseCurrency, isBuyingQuote: isBuyingQuote)
    }
}

// MARK: View update methods
extension ExchangePresenter {
    func initializeView(for ticker: Ticker, tickers: [Ticker]) {
        guard let currency = ticker.currency else { return }
        let baseAmount: Double
        
        if var state = exchangeViewState {
            if state.topCurrency == state.baseCurrency {
                baseAmount = state.topAmount
                state.bottomCurrency = currency
            } else {
                state.topCurrency = currency
                baseAmount = state.bottomAmount
            }
            state.tickers = tickers
            exchangeViewState = state
        } else {
            baseAmount = 99
            exchangeViewState = ExchangeViewState(baseCurrency: .USDc,
                                                  topCurrency: .USDc,
                                                  topAmount: baseAmount,
                                                  bottomCurrency: currency,
                                                  bottomAmount: 0.0,
                                                  rateToUse: .buyingQuote,
                                                  lastUpdatedField: .none,
                                                  tickers: tickers)
        }
        
        guard let state = exchangeViewState else { return }
        
        interactor?.calculateConversion(amount: baseAmount,
                                        sourceCurrency: state.baseCurrency,
                                        targetCurrency: currency,
                                        baseCurrency: state.baseCurrency,
                                        isBuyingQuote: state.rateToUse == .buyingQuote)
    }
    
    private func updateExchangeView(with state: ExchangeViewState, ticker: Ticker) {
        guard let view = view else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.view?.hideLoading()
            self.view?.hideErrorMessage()
            
            view.exchangeView.isHidden = false
            
            let rawRateStr = state.rateToUse == .buyingQuote ? ticker.bid : ticker.ask
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
}

// MARK: InteractorOutputProtocol methods
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
    
    func didCalculateConversion(result: Double, sourceAmount: Double, ticker: Ticker, isSourceBase: Bool) {
        guard var state = exchangeViewState else { return }
        
        if (isSourceBase && state.topCurrency == state.baseCurrency) ||
            (!isSourceBase && state.topCurrency != state.baseCurrency) {
            state.topAmount = sourceAmount
            state.bottomAmount = result
        } else {
            state.bottomAmount = sourceAmount
            state.topAmount = result
        }
        
        self.exchangeViewState = state
        updateExchangeView(with: state, ticker: ticker)
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
