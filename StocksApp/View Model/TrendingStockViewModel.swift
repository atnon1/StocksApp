//
//  TrendingStockViewModel.swift
//  StocksApp
//
//  Created by Anton Makeev on 02.04.2021.
//

import SwiftUI
import Combine

class TrendingStockViewModel: ObservableObject {
    
    var model = StocksModel()
    var cancelable: AnyCancellable?
    var favorites: Set<String> {
        model.favoriteStocks
    }

    init() {
        cancelable = model.$publishedVersion.sink { _ in self.objectWillChange.send() }
    }
    
    var trending: [String] {
        model.trending
    }

    func isFavorite(symbol: String) -> Bool {
        model.isFavorityStock(symbol)
    }
    
    func tappedStar(on symbol: String) {
        model.toggleFavorite(symbol)
    }
    
    func loadStockInfo(for symbol: String) {
        model.loadStockInfo(for: symbol)
    }
    
    func companyProfile(for symbol: String) -> CompanyProfile? {
        model.companyProfile(for: symbol)
    }
    
    func getStocksFiltered(by str: String) -> [String] {
        model.getFiltered(by: str)
    }
    
    func companyLogo(for symbol: String) -> UIImage? {
        model.companyLogos[symbol]
    }
    
    func companyName(for symbol: String) -> String {
        model.companyNames[symbol] ?? ""
    }
    
    func currentState(for symbol: String) -> SymbolCurrentState {
        model.currentState[symbol] ?? SymbolCurrentState.zero
    }
    
    func symbolDisappears(_ symbol: String) {
        model.unsubscribe(from: symbol)
    }
    
}
