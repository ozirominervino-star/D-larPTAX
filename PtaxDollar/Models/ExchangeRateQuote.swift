import Foundation

struct ExchangeRateQuote: Codable, Equatable {
    let currencyCode: String
    let requestedDate: Date
    let effectiveDateTime: Date
    let buyRate: Decimal
    let sellRate: Decimal
    let source: QuoteSource
}

enum QuoteSource: String, Codable {
    case bancoCentralPtax
    case localCache
}

enum QuoteError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound
    case decodingFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida para consulta da PTAX."
        case .invalidResponse:
            return "Resposta inválida do Banco Central."
        case .notFound:
            return "Cotação não encontrada para a data selecionada ou dias anteriores."
        case .decodingFailed:
            return "Não foi possível ler a resposta da cotação."
        case .networkUnavailable:
            return "Não foi possível conectar ao Banco Central."
        }
    }
}
