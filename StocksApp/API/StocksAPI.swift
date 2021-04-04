//
//  StocksAPI.swift
//  StocksApp
//
//  Created by Anton Makeev on 28.03.2021.
//

import SwiftUI
import Combine

class StocksAPI: ObservableObject {
    
    @Published var trendingStocks = [String]()
    @Published var companyProfiles = [String:CompanyProfile]()
    @Published var companyLogos = [String: UIImage]()
    @Published var currentState = [String: SymbolCurrentState]()
    @Published var companyNames = [String: String]()
    //var cancellable: AnyCancellable?
    //var trandingCache = NSCache<NSURL:NSString>()
    private var webSocketTask: URLSessionWebSocketTask!
    private let finnHubToken = "c1gn3gn48v6v8dn0cjbg"
    private let mboumToken = "demo"
    
    private var fetchTrandingCancellable: AnyCancellable?
    
    // Returns a list of S&P500
    func getTrendingStocks() {
        
        guard let url = URL(string: "https://finnhub.io/api/v1/index/constituents?symbol=%5EGSPC&token=\(finnHubToken)") else {
            return
        }
        // TODO: Remove print
        print("Loading trending list")
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { [weak self] (data, response, error) in
            var stocks = [String]()
            if error != nil {
                print(error!.localizedDescription)
                _ = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { [weak self] _ in self?.getTrendingStocks() }
                )
            } else {
                do {
                    let dictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String : Any]
                    if let quotesStocks = dictionary?["constituents"] as? [String] {
                        stocks = quotesStocks
                    }
                    DispatchQueue.main.async {
                        self?.trendingStocks =  stocks.sorted { (!Array($0)[0].isNumber && Array($1)[0].isNumber) ||
                            (!Array($0)[0].isNumber && !Array($1)[0].isNumber && $0 < $1) || (Array($0)[0].isNumber && Array($1)[0].isNumber && $0 < $1)  }
                        self?.loadCompanyNames()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }
    
    // Для каждой компании деалется 1 запрос
    func loadCompanyProfile(of symbol: String) {
        if companyProfiles[symbol] != nil { return }
        guard let url = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(symbol)&token=\(finnHubToken)") else {
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            if (error != nil) {
                print(error!.localizedDescription)
                print(symbol)
            } else {
                do {
                    let profile = try JSONDecoder().decode(CompanyProfile.self, from: data!)
                    DispatchQueue.main.async {
                        self?.companyProfiles[symbol] = profile
                        self?.loadLogo(for: symbol)
                        self?.loadInitialState(of: symbol)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        })
        dataTask.resume()
    }
    
    // Подписка на обновление значений цены для конкретного идентификатора
    func subscribeToState(of symbol: String) {
        guard let url = URL(string: "wss://ws.finnhub.io?token=\(finnHubToken)") else { return }
        let session = URLSession(configuration: .default)
        if webSocketTask == nil {
            webSocketTask = session.webSocketTask(with: url)
        }
        let message = URLSessionWebSocketTask.Message.string("{\"type\":\"subscribe\",\"symbol\":\"\(symbol)\"}")
        webSocketTask.send(message) { error in
            if error != nil {
                print(error!.localizedDescription)
            }
        }
        receiveStatData()
        webSocketTask.resume()
    }
    
    // TODO: Считывать раз в минуту
    @objc func receiveStatData() {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text message: \(text)")
                    let json = try? JSONSerialization.jsonObject(with: text.data(using: .utf8)!, options: .mutableContainers) as? [String : Any]
                    if let stats = json!["data"] as? [[String : Any]] {
                        let stat = stats[0]
                        var prevStat = self.currentState[stat["s"] as! String]!
                        prevStat.currentPrice = stat["p"] as! Double
                        self.currentState[stat["s"] as! String] = prevStat
                    }
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    fatalError()
                }
            }
            Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.receiveStatData), userInfo: nil, repeats: false)
            self.webSocketTask.resume()
        }
    }
    
    // Загрузка начального заполнения цен по идентификатору
    func loadInitialState(of symbol: String) {
        if currentState[symbol] != nil { return }
        guard let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(finnHubToken)") else {
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) {
            [weak self] (data, response, error) in
            if (error != nil) {
                print(error!.localizedDescription)
                print(symbol)
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String : Double] {
                        let symbolCurrentStat = SymbolCurrentState(openPrice: json["o"]!, highPrice: json["h"]!, lowPrice: json["l"]!, currentPrice: json["c"]!, previousPrice: json["pc"]!)
                        DispatchQueue.main.async {
                            self?.currentState[symbol] =  symbolCurrentStat
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }
    
    // Запрос наименований для рынка США. Одним запросом можно получить сразу все
    func loadCompanyNames() {
        guard let url = URL(string: "https://finnhub.io/api/v1/stock/symbol?exchange=US&token=\(finnHubToken)") else {
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) {
            [weak self] (data, response, error) in
            if (error != nil) {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String : String]] {
                            let symbolList = self?.trendingStocks.map({ $0.lowercased() })
                            let symbols = json.filter {element in
                                if let symbol = element["displaySymbol"] {
                                    let check = symbolList?.contains(symbol.lowercased()) ?? false
                                    return check
                                }
                                return false
                            }
                        var dict = [String: String]()
                        for symbol in symbols {
                            if let displaySymbol = symbol["displaySymbol"], let name = symbol["description"] {
                                dict[displaySymbol] = name
                            }
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.companyNames = dict
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }

    
    func unsubscribe(from symbol: String) {
        guard let url = URL(string: "wss://ws.finnhub.io?token=\(finnHubToken)") else { return }
        let session = URLSession(configuration: .default)
        if webSocketTask == nil {
            webSocketTask = session.webSocketTask(with: url)
        }
        let message = URLSessionWebSocketTask.Message.string("{\"type\":\"unsubscribe\",\"symbol\":\"\(symbol)\"}")
        webSocketTask.send(message) { error in
            if error != nil {
                print(error!.localizedDescription)
            }
        }
        webSocketTask.resume()
    }
    
    func loadLogo(for symbol: String) {
        guard let string = companyProfiles[symbol]?.logo, let url = URL(string: string) else { return }
        _ = ImageLoader.shared.loadImage(from: url).sink {
            [weak self] image in
            self?.companyLogos[symbol] = image
        }
    }
}
