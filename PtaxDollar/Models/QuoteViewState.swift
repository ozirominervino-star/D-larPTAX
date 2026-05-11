import Foundation

enum QuoteViewState: Equatable {
    case idle
    case loading
    case success(ExchangeRateQuote)
    case error(String)
}
