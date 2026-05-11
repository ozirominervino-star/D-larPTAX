# PtaxDollar

App iOS simples em SwiftUI para consultar a cotação oficial do dólar PTAX usando a API pública do Banco Central do Brasil.

## Funcionalidades do MVP

- Consulta USD/BRL por data
- Exibe cotação de compra e venda
- Busca automaticamente a última cotação disponível anterior quando a data escolhida não tem PTAX
- Cache local da última cotação consultada
- Sem login
- Sem backend próprio

## Requisitos

- macOS com Xcode instalado
- iOS 17 ou superior recomendado
- iPhone físico ou simulador
- Apple ID configurado no Xcode para rodar em dispositivo físico

## Como abrir no Xcode

1. Descompacte este projeto.
2. Abra `PtaxDollar.xcodeproj`.
3. Selecione um simulador ou iPhone físico.
4. Clique em **Run** ou pressione `Cmd + R`.

## Observação importante

Este projeto inclui um arquivo `.xcodeproj` básico. Caso o Xcode não abra corretamente por diferenças de versão, crie um projeto novo no Xcode com:

- iOS > App
- Product Name: `PtaxDollar`
- Interface: `SwiftUI`
- Language: `Swift`

Depois copie a pasta `PtaxDollar` deste repositório para dentro do novo projeto.

## Fonte dos dados

API pública PTAX/OData do Banco Central do Brasil:

```text
https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/
```

Endpoint usado no MVP:

```text
CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='MM-dd-yyyy'&$format=json
```

## Estrutura

```text
PtaxDollar/
  PtaxDollarApp.swift
  Models/
    ExchangeRateQuote.swift
    QuoteViewState.swift
  Services/
    PtaxClient.swift
    ExchangeRateService.swift
    QuoteCache.swift
  ViewModels/
    PtaxQuoteViewModel.swift
  Views/
    PtaxQuoteView.swift
  Resources/
    Assets.xcassets
```

## Próximos passos sugeridos

- Adicionar testes unitários para `ExchangeRateService`
- Adicionar histórico local
- Adicionar suporte futuro a outras moedas usando `CotacaoMoedaDia`
- Publicar internamente via TestFlight, se necessário
