//
//  SymbolCurrentState.swift
//  StocksApp
//
//  Created by Anton Makeev on 01.04.2021.
//

import Foundation

struct SymbolCurrentState: Codable {
    var openPrice: Double
    var highPrice: Double
    var lowPrice: Double
    var currentPrice: Double
    var previousPrice: Double
    
    var change: Double {
        if previousPrice != 0 {
            return (currentPrice - previousPrice) / previousPrice
        } else {
            return 0
        }
    }
    
    var changePercent: Double {
        if previousPrice != 0 {
            return change / previousPrice
        } else {
            return 0
        }
    }
    
    // State with initial values zero
    static let zero = SymbolCurrentState(openPrice: 0, highPrice: 0, lowPrice: 0, currentPrice: 0, previousPrice: 0)
}
