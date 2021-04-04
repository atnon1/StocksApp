//
//  StocksAppApp.swift
//  StocksApp
//
//  Created by Anton Makeev on 28.03.2021.
//

import SwiftUI

@main
struct StocksAppApp: App {
    var body: some Scene {
        WindowGroup {
            TrendingStocksView()
                .environmentObject(TrendingStockViewModel())
        }
    }
}
