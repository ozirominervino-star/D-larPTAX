import Foundation

struct PtaxResponse: Decodable {
    let value: [PtaxQuoteDTO]
}

struct PtaxQuoteDTO: Decodable {
    let cotacaoCompra: Decimal
    let cotacaoVenda: Decimal
    let dataHoraCotacao: String
}

protocol PtaxClientProtocol {
    func fetchDollarQuote(date: Date, requestedDate: Date) async throws -> [ExchangeRateQuote]
}

final class PtaxClient: PtaxClientProtocol {
    private let baseURL = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
    private let session: URLSession
    private let calendar: Calendar

    init(session: URLSession = .shared, calendar: Calendar = .current) {
        self.session = session
        self.calendar = calendar
    }

    func fetchDollarQuote(date: Date, requestedDate: Date) async throws -> [ExchangeRateQuote] {
        let dateString = Self.apiDateFormatter.string(from: date)

        var components = URLComponents(string: "\(baseURL)/CotacaoDolarDia(dataCotacao=@dataCotacao)")
        components?.queryItems = [
            URLQueryItem(name: "@dataCotacao", value: "'\(dateString)'"),
            URLQueryItem(name: "$format", value: "json")
        ]

        guard let url = components?.url else {
            throw QuoteError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw QuoteError.invalidResponse
            }

            let decoder = JSONDecoder()
            let ptaxResponse = try decoder.decode(PtaxResponse.self, from: data)

            return ptaxResponse.value.compactMap { dto in
                guard let effectiveDate = Self.responseDateFormatter.date(from: dto.dataHoraCotacao) else {
                    return nil
                }

                return ExchangeRateQuote(
                    currencyCode: "USD",
                    requestedDate: requestedDate,
                    effectiveDateTime: effectiveDate,
                    buyRate: dto.cotacaoCompra,
                    sellRate: dto.cotacaoVenda,
                    source: .bancoCentralPtax
                )
            }
        } catch let error as QuoteError {
            throw error
        } catch is DecodingError {
            throw QuoteError.decodingFailed
        } catch {
            throw QuoteError.networkUnavailable
        }
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()

    private static let responseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
