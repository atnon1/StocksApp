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
    var trendingCache = Cache<String, [String]>()
    var profilesCache = Cache<String, CompanyProfile>(maximumEntryCount: 500)
    var namesCache = Cache<String, [String : String]>()
    
    var favoriteStocks = Set<String>() {
        didSet {
            publish()
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

    var companyNames: [String: String] {
        namesCache["names"] ?? [:]
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
        if let cache = try? trendingCache.loadFromDisk(named: "trending"), let trending = cache["trending"], !trending.isEmpty {
            trendingCache = cache
        }
        api.getTrendingStocks()
        if let cache = try? profilesCache.loadFromDisk(named: "profiles")  {
            profilesCache = cache
        }
        if let cache = try? namesCache.loadFromDisk(named: "names") {
            namesCache = cache
        }
        cancellable = api.$trendingStocks.sink(receiveValue: {
            [weak self] stocks in
            guard !stocks.isEmpty else { return }
            self?.trendingCache["trending"] = stocks
            do {
                try self?.trendingCache.saveToDisk(withName: "trending")
            } catch {
                print(error.localizedDescription)
            }
        })
//        cancellable1 = api.$companyLogos.sink(receiveValue: { [weak self] logos in self?.companyLogos = logos })
        cancellable2 = api.$currentState.sink(receiveValue: { [weak self] currentState in self?.currentState = currentState
        })
        cancellable3 = api.$companyProfiles.sink(receiveValue: { [weak self] profiles in
            for profile in profiles {
                self?.profilesCache[profile.key] = profile.value
                if self?.companyLogos[profile.key] == nil {
                    self?.loadLogo(for: profile.key)
                }
            }
            do {
                try self?.profilesCache.saveToDisk(withName: "profiles")
            } catch {
                print(error.localizedDescription)
            }
            self?.publish()
        })
        cancellable4 = api.$companyNames.sink(receiveValue: { [weak self] names in
            guard !names.isEmpty else { return }
            self?.namesCache["names"] = names
            do {
                try self?.namesCache.saveToDisk(withName: "names")
            } catch {
                print(error.localizedDescription)
            }
        })
        if let favorite = UserDefaults.standard.object(forKey: "favorite") as? [String] {
            favoriteStocks = Set(favorite)
        }
    }
    
    func loadStockInfo(for symbol: String) {
        if profilesCache[symbol] == nil {
            api.loadCompanyProfile(of: symbol)
        } else {
            if  api.currentState[symbol]  == nil {
                api.loadInitialState(of: symbol)
            }
            if companyLogos[symbol] == nil {
                loadLogo(for: symbol)
            }
        }
        api.loadInitialState(of: symbol)
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
    
    func getFiltered(by prefix: String) -> [String] {
        let prefix = prefix.lowercased()
        let keysAndNames = Array(companyNames.filter { $0.value.lowercased().hasPrefix(prefix) || $0.key.lowercased().hasPrefix(prefix) }.keys)
        return Array(keysAndNames).sorted()
    }
    
    func unsubscribe(from symbol: String) {
        api.unsubscribe(from: symbol)
    }
    
    func loadLogo(for symbol: String) {
        guard let string = profilesCache[symbol]?.logo, let url = URL(string: string) else { return }
        _ = ImageLoader.shared.loadImage(from: url).sink {
            [weak self] image in
            self?.companyLogos[symbol] = image
        }
    }
    
}
