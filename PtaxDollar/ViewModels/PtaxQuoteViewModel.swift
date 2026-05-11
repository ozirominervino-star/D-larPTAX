import Foundation

@MainActor
final class PtaxQuoteViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var state: QuoteViewState = .idle

    private let service: ExchangeRateServiceProtocol
    private let cache: QuoteCache

    init(
        service: ExchangeRateServiceProtocol = ExchangeRateService(),
        cache: QuoteCache = UserDefaultsQuoteCache()
    ) {
        self.service = service
        self.cache = cache
        loadLastQuote()
    }

    func loadLastQuote() {
        if let lastQuote = cache.loadLastQuote() {
            state = .success(
                ExchangeRateQuote(
                    currencyCode: lastQuote.currencyCode,
                    requestedDate: lastQuote.requestedDate,
                    effectiveDateTime: lastQuote.effectiveDateTime,
                    buyRate: lastQuote.buyRate,
                    sellRate: lastQuote.sellRate,
                    source: .localCache
                )
            )
        }
    }

    func consultQuote() async {
        state = .loading

        do {
            let quote = try await service.getLatestAvailableUsdQuote(for: selectedDate)
            state = .success(quote)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
