import Foundation

protocol ExchangeRateServiceProtocol {
    func getLatestAvailableUsdQuote(for selectedDate: Date) async throws -> ExchangeRateQuote
}

final class ExchangeRateService: ExchangeRateServiceProtocol {
    private let ptaxClient: PtaxClientProtocol
    private let cache: QuoteCache
    private let calendar: Calendar
    private let maxLookbackDays: Int

    init(
        ptaxClient: PtaxClientProtocol = PtaxClient(),
        cache: QuoteCache = UserDefaultsQuoteCache(),
        calendar: Calendar = .current,
        maxLookbackDays: Int = 10
    ) {
        self.ptaxClient = ptaxClient
        self.cache = cache
        self.calendar = calendar
        self.maxLookbackDays = maxLookbackDays
    }

    func getLatestAvailableUsdQuote(for selectedDate: Date) async throws -> ExchangeRateQuote {
        var currentDate = calendar.startOfDay(for: selectedDate)

        for _ in 0..<maxLookbackDays {
            let quotes = try await ptaxClient.fetchDollarQuote(
                date: currentDate,
                requestedDate: selectedDate
            )

            if let quote = quotes.first {
                cache.save(quote)
                return quote
            }

            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }

            currentDate = previousDate
        }

        throw QuoteError.notFound
    }
}
