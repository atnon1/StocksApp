//
//  SymbolRow.swift
//  StocksApp
//
//  Created by Anton Makeev on 03.04.2021.
//

import SwiftUI

struct SymbolRow: View {
    
    @EnvironmentObject var viewModel: TrendingStockViewModel

    
    let symbol: String
    var profile: CompanyProfile? {
        viewModel.companyProfile(for: symbol)
    }
    var currentState: SymbolCurrentState {
        viewModel.currentState(for: symbol)
    }
    var change: Double {
        Double(round(currentState.change * 100)/100)
    }
    var changePercent: Double {
        Double(round(currentState.changePercent * 100)/100)
    }
    
    func logo(for symbol: String) -> some View {
        Group {
            if let logo = viewModel.companyLogo(for: symbol) {
                Image(uiImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
            }
        }
        .frame(width: 48, height: 48, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    var body: some View {
        HStack {
            logo(for: profile?.ticker ?? "")
            VStack(alignment: .leading ) {
                HStack {Text(symbol)
                    .font(.headline)
                    FavoriteStar(isFavorite: viewModel.isFavorite(symbol: symbol))
                        .onTapGesture {
                            viewModel.tappedStar(on: symbol)
                        }
                }
                Text(profile?.name ?? "")
                    .font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(profile?.currencySign ?? "")\(String(format: "%.2f", currentState.currentPrice))")
                    .font(.headline)
                
                Text("\(change > 0 ? "+" : "")\(String(format: "%.2f", change))(\(changePercent > 0 ? "+" : "")\(String(format: "%.2f", changePercent))%)")
                    .foregroundColor( change < 0 ? .red : .green)
                    .font(.caption)
            }
        }
    }
}
