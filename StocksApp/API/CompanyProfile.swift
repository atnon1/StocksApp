//
//  CompanyProfile.swift
//  StocksApp
//
//  Created by Anton Makeev on 29.03.2021.
//

import Foundation

struct CompanyProfile: Codable {
    let country: String
    let currency: String
    let exchange: String
    let ipo: String
    let marketCapitalization: Double
    let name: String
    let shareOutstanding: Double
    let ticker: String
    let weburl: String
    let logo: String
    let finnhubIndustry: String
    
    var currencySign: String {
        switch currency.lowercased() {
        case "usd":
            return "$"
        case "eur":
            return "€"
        case "jpy":
            return "¥"
        case "rub":
            return "₽"
        default:
            return currency
        }
    }
    
}

