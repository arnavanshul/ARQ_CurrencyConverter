//
//  DataModels.swift
//  ARQ_CurrencyConverter
//
//  Created by Arnav Anshul on 4/18/26.
//

import Foundation

struct Ticker: Decodable {
    let ask: String
    let bid: String
    let book: String
    let date: String
    
    // Logic helper: Convert the ask string to a Double
    var rateValue: Double {
        Double(ask) ?? 0.0
    }
    
    var currency: Currency? {
        let components = book.lowercased().components(separatedBy: "_")
        guard let currencyCode = components.last?.uppercased() else { return nil }
        return Currency(rawValue: currencyCode)
    }
}

enum Currency: String {
    case MXN
    case ARS
    case COP
    case BRL
    case USDc
    case EURc
    
    // Returns the Emoji flag
    var flag: String {
        switch self {
        case .MXN: return "🇲🇽"
        case .ARS: return "🇦🇷"
        case .COP: return "🇨🇴"
        case .BRL: return "🇧🇷"
        case .USDc: return "🇺🇸"
        case .EURc: return "🇪🇺"
        }
    }
    
    // Returns the full display name
    var countryFullName: String {
        switch self {
        case .MXN: return "Mexico"
        case .ARS: return "Argentina"
        case .COP: return "Colombia"
        case .BRL: return "Brazil"
        case .USDc: return "United States"
        case .EURc: return "Europe"
        }
    }
    
    // Optional: Returns the currency name
    var currencyName: String {
        switch self {
        case .MXN: return "Mexican Peso"
        case .ARS: return "Argentine Peso"
        case .COP: return "Colombian Peso"
        case .BRL: return "Brazilian Real"
        case .USDc: return "United States Dollar Coin"
        case .EURc: return "Euro Coin"
        }
    }
    
    var currencySymbol: String {
        switch self {
        case .EURc:
            return "€"
        default:
            return "$"
        }
    }
}

