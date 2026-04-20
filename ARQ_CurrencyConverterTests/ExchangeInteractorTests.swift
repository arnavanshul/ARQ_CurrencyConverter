//
//  ExchangeInteractorTests.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/20/26.
//

import XCTest
@testable import ARQ_CurrencyConverter

final class ExchangeInteractorTests: XCTestCase {
    var sut: ExchangeInteractor!
    var mockOutput: MockPresenter!

    override func setUp() {
        super.setUp()
        sut = ExchangeInteractor(networkService: MockNetworkService())
        mockOutput = MockPresenter()
        sut.output = mockOutput
        
        let jsonString = """
        [
            {
                "ask": "17.3100000000",
                "bid": "17.3072000000",
                "book": "usdc_mxn",
                "date": "2026-04-20T18:21:32.195775440"
            }
        ]
        """
        
        if let data = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(TickerResponse.self, from: data) {
                sut.processResponse(exchangeRates: response)
            }
        }
    }

    func testCalculateConversion_BuyingMXN_UsesBidPrice() {
        // Given: User has 99 USDc and wants to get MXN
        let amount = 99.0
        
        // When: isBuyingQuote is true
        sut.calculateConversion(amount: amount, sourceCurrency: .USDc, targetCurrency: .MXN, baseCurrency: .USDc, isBuyingQuote: true)
        
        // Then: 99 * 17.3072 = 1713.4128
        let expectedResult = 1713.4128
        XCTAssertEqual(mockOutput.capturedResult, expectedResult, accuracy: 0.0001)
        XCTAssertTrue(mockOutput.capturedIsSourceBase)
    }

    func testCalculateConversion_Inverse_BuyingBase_UsesBidPrice() {
        // Given: User wants exactly 1000 MXN, starting from USDc
        let amount = 1000.0
        
        // When: source is MXN (Quote), so we expect division by Bid
        sut.calculateConversion(amount: amount, sourceCurrency: .MXN, targetCurrency: .USDc, baseCurrency: .USDc, isBuyingQuote: true)
        
        // Then: 1000 / 17.3072 = 57.77942...
        let expectedResult = 1000.0 / 17.3072
        XCTAssertEqual(mockOutput.capturedResult, expectedResult, accuracy: 0.0001)
        XCTAssertFalse(mockOutput.capturedIsSourceBase)
    }

    // MARK: - Selling Quote Tests (Uses Ask: 17.3100)

    func testCalculateConversion_SellingMXN_UsesAskPrice() {
        // Given: 99 USDc anchor, but we want the "Sell" rate
        let amount = 99.0
        
        // When: isBuyingQuote is false
        sut.calculateConversion(amount: amount, sourceCurrency: .USDc, targetCurrency: .MXN, baseCurrency: .USDc, isBuyingQuote: false)
        
        // Then: 99 * 17.3100 = 1713.69
        let expectedResult = 1713.69
        XCTAssertEqual(mockOutput.capturedResult, expectedResult, accuracy: 0.0001)
    }

    // MARK: - Edge Cases

    func testCalculateConversion_ZeroAmount_ReturnsZero() {
        sut.calculateConversion(amount: 0.0, sourceCurrency: .USDc, targetCurrency: .MXN, baseCurrency: .USDc, isBuyingQuote: true)
        XCTAssertEqual(mockOutput.capturedResult, 0.0)
    }
}

// MARK: - Mocks
class MockPresenter: ExchangeInteractorOutputProtocol {
    var capturedResult: Double = 0
    var capturedIsSourceBase: Bool = false

    func didCalculateConversion(result: Double, sourceAmount: Double, ticker: Ticker, isSourceBase: Bool) {
        capturedResult = result
        capturedIsSourceBase = isSourceBase
    }

    func didFetchRates(tickers: [Ticker]?) {}
    func didFetchAvailableCurrencies(currencies: [Currency]) {}
    func didFailToFetchData(error: NetworkError, context: FetchContext) {}
}

class MockNetworkService: NetworkServiceProtocol {
    func fetchRates(currencies: [Currency], completion: @escaping (Result<TickerResponse, NetworkError>) -> Void) {}
    func fetchAvailableCurrencies(completion: @escaping (Result<[String], NetworkError>) -> Void) {}
}
