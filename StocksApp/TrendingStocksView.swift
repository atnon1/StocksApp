//
//  TrendingStocsView.swift
//  StocksApp
//
//  Created by Anton Makeev on 28.03.2021.
//

import SwiftUI

struct TrendingStocksView: View {
    
    @EnvironmentObject var viewModel: TrendingStockViewModel
    
    private var isLoading: Bool {
        viewModel.trending.isEmpty
    }
    
    @State var filterString = ""

    var filteredList: [String] {
        if filterString.isEmpty {
            return viewModel.trending
        } else {
            return viewModel.getStocksFiltered(by: filterString)
        }
    }
    
    var body: some View {
            ZStack {
                Color.white
                    .ignoresSafeArea(.all)
                TabView {
                    NavigationView {
                    Group {
                        if isLoading {
                            Image(systemName: "hourglass")
                                .imageScale(.large)
                                .spinning()
                        } else {
                            List  {
                                ZStack(alignment: .trailing) {
                                    TextField("Search company or ticker", text: $filterString)
                                    if !filterString.isEmpty {
                                        Button(action: { filterString = "" }, label: {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.gray)
                                        })
                                    }
                                }
                                ForEach(filteredList, id: \.self) { symbol in
                                    SymbolRow(symbol: symbol)
                                        .environmentObject(viewModel)
                                        .onAppear { viewModel.loadStockInfo(for: symbol) }
                                        .onDisappear { viewModel.symbolDisappears(symbol)
                                        }
                                }
                            }
                        }
                    }
                    .navigationTitle("S&P 500")
                    }
                    .tabItem { Label("S&P 500", systemImage: "list.dash") }
                    NavigationView {
                    Group {
                        if viewModel.favorites.isEmpty {
                            Text("No favorites added")
                                .foregroundColor(.gray)
                        } else {
                            List  {
                                ForEach(Array(viewModel.favorites).sorted(), id: \.self) { symbol in
                                    SymbolRow(symbol: symbol)
                                        .environmentObject(viewModel)
                                        .onAppear { viewModel.loadStockInfo(for: symbol) }
                                }
                            }
                        }
                    }
                    .navigationTitle("Favorite")
                    }
                    .tabItem { Label("Favorite", systemImage: "star") }
                }
            }
        }
    }


struct FavoriteStar: View {
        
    var isFavorite: Bool
    var body: some View {
        if isFavorite {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)

        } else {
            Image(systemName: "star")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingStocksView()
    }
}
