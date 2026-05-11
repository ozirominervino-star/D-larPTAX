import SwiftUI

struct PtaxQuoteView: View {
    @StateObject private var viewModel = PtaxQuoteViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Data da cotação",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                Button {
                    Task {
                        await viewModel.consultQuote()
                    }
                } label: {
                    Text("Consultar PTAX")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                content

                Spacer()
            }
            .padding()
            .navigationTitle("Dólar PTAX")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("Selecione uma data e consulte a cotação oficial PTAX.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

        case .loading:
            ProgressView("Consultando Banco Central...")

        case .success(let quote):
            quoteCard(quote)

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func quoteCard(_ quote: ExchangeRateQuote) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("USD/BRL")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if quote.source == .localCache {
                    Text("Cache")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Compra")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatDecimal(quote.buyRate))
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Venda")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatDecimal(quote.sellRate))
                        .font(.title)
                        .fontWeight(.bold)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Data efetiva: \(formatDateTime(quote.effectiveDateTime))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !Calendar.current.isDate(quote.requestedDate, inSameDayAs: quote.effectiveDateTime) {
                    Text("A data escolhida não tinha cotação. Foi usada a última cotação disponível anterior.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter.string(from: number) ?? "R$ --"
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    PtaxQuoteView()
}
