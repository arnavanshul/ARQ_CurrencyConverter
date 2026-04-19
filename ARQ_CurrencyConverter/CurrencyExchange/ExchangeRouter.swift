//
//  ExchangeRouter.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/16/26.
//

import Foundation
import UIKit

protocol ExchangeRouterProtocol: AnyObject {
    static func createModule(networkService: NetworkServiceProtocol) -> UIViewController
    static func createModule() -> UIViewController
    func navigateToDetails(from view: CurrencyExchangeViewProtocol?)
    func presentCurrencyPicker(from view: CurrencyExchangeViewProtocol,
                               tickers: [Ticker],
                               currentCode: String,
                               presenter: ExchangePresenterProtocol)
}

class ExchangeRouter {
    static func createModule() -> UIViewController {
        let view = CurrencyExchangeViewController()
        
        let presenter = ExchangePresenter()
        let interactor = ExchangeInteractor()
        let router = ExchangeRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        
        interactor.output = presenter
        
        return view
    }
    
    static func createModule(networkService: NetworkServiceProtocol) -> UIViewController {
        let view = CurrencyExchangeViewController()
        
        let presenter = ExchangePresenter()
        let interactor = ExchangeInteractor(networkService: networkService)
        let router = ExchangeRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        
        interactor.output = presenter
        
        return view
    }
    
    init() {}
}

extension ExchangeRouter: ExchangeRouterProtocol {
    func presentCurrencyPicker(from view: CurrencyExchangeViewProtocol,
                               tickers: [Ticker],
                               currentCode: String,
                               presenter: ExchangePresenterProtocol) {
        
        let picker = CurrencyPickerViewController()
        picker.currencies = tickers
        picker.selectedCurrencyCode = currentCode
        picker.onCurrencySelected = { [weak presenter] selectedTicker in
            presenter?.didSelectCurrency(ticker: selectedTicker)
        }
        
        // Wrap in NavigationController for the title/close button
        let nav = UINavigationController(rootViewController: picker)
        
        if let sheet = nav.sheetPresentationController {
            // This makes it stay at the bottom half like the screenshot
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        (view as? UIViewController)?.present(nav, animated: true)
    }
    
    func navigateToDetails(from view: (any CurrencyExchangeViewProtocol)?) {
        
    }
}

