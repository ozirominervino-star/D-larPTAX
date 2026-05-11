import Foundation

protocol QuoteCache {
    func save(_ quote: ExchangeRateQuote)
    func loadLastQuote() -> ExchangeRateQuote?
}

final class UserDefaultsQuoteCache: QuoteCache {
    private let key = "last_exchange_rate_quote"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ quote: ExchangeRateQuote) {
        guard let data = try? JSONEncoder().encode(quote) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }

    func loadLastQuote() -> ExchangeRateQuote? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(ExchangeRateQuote.self, from: data)
    }
}
