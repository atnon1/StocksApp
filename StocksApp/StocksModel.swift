//
//  StocksModel.swift
//  StocksApp
//
//  Created by Anton Makeev on 03.04.2021.
//

import SwiftUI
import Combine

class StocksModel: ObservableObject {
    
    let api = StocksAPI()
    var trendingCache = Cache<String, [String]>() {
        didSet {
            publish()
            do {
            try trendingCache.saveToDisk(withName: "trending")
            print(trending)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    var profilesCache = Cache<String, CompanyProfile>() {
        didSet {
            try? trendingCache.saveToDisk(withName: "profiles")
            publish()
        }
    }
    
    var favoriteStocks = Set<String>() {
        didSet {
            publishedVersion += 1
            UserDefaults.standard.setValue(Array(favoriteStocks), forKey: "favorite")
        }
    }
    
    func isFavorityStock(_ symbol: String) -> Bool {
        favoriteStocks.contains(symbol)
    }
    
    var trending: [String] {
        trendingCache["trending"] ?? []
    }
    
    private(set) var companyLogos = [String: UIImage]() {
        didSet {
            publish()
        }
    }
    private(set) var currentState = [String: SymbolCurrentState]() {
        didSet {
            publish()
        }
    }
    private(set) var companyProfiles = [String: CompanyProfile]() {
        didSet {
            publish()
        }
    }
    private(set) var companyNames = [String: String] () {
        didSet {
            publish()
        }
    }
    // To get all changes by ViewModel
    @Published var publishedVersion = 0
    
    var cancellable: AnyCancellable?
    var cancellable1: AnyCancellable?
    var cancellable2: AnyCancellable?
    var cancellable3: AnyCancellable?
    var cancellable4: AnyCancellable?
    
    func publish() {
        publishedVersion += 1
    }
    
    init() {
        if let cache = try? trendingCache.loadFromDisk(withName: "trending"), let trending = cache["trending"], !trending.isEmpty {
            trendingCache = cache
        } else {
            api.getTrendingStocks()
        }
        if let cache = try? profilesCache.loadFromDisk(withName: "profiles") {
            profilesCache = cache
        }
        cancellable = api.$trendingStocks.sink(receiveValue: {
                                                [weak self] stocks in self?.trendingCache["trending"] = stocks })
        cancellable1 = api.$companyLogos.sink(receiveValue: { [weak self] logos in self?.companyLogos = logos })
        cancellable2 = api.$currentState.sink(receiveValue: { [weak self] currentState in self?.currentState = currentState })
        cancellable3 = api.$companyProfiles.sink(receiveValue: { [weak self] profiles in
            for profile in profiles {
                self?.profilesCache[profile.key] = profile.value
            }
        })
        cancellable4 = api.$companyNames.sink(receiveValue: { [weak self] names in self?.companyNames = names })
        if let favorite = UserDefaults.standard.object(forKey: "favorite") as? [String] {
            favoriteStocks = Set(favorite)
        }
    }
    
    func loadStockInfo(for symbol: String) {
        if profilesCache[symbol] == nil {
            api.loadCompanyProfile(of: symbol)
        }
        api.subscribeToState(of: symbol)
    }
    
    func companyProfile(for symbol: String) -> CompanyProfile? {
        if let profile = profilesCache[symbol] {
            return profile
        }
        return api.companyProfiles[symbol]
    }
    
    func companyLogo(for symbol: String) -> UIImage? {
        api.companyLogos[symbol]
    }
    
    func currentState(for symbol: String) -> SymbolCurrentState {
        api.currentState[symbol] ?? SymbolCurrentState.zero
    }
    
    func toggleFavorite(_ symbol: String) {
        if isFavorityStock(symbol) {
            favoriteStocks.remove(symbol)
        } else {
            favoriteStocks.insert(symbol)
        }
    }
    
    func unsubscribe(from symbol: String) {
        api.unsubscribe(from: symbol)
    }
    
}
