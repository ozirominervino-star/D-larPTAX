# Dólar PTAX — Simulador React

Simulador web da tela simples do app iPhone para consulta da cotação do dólar PTAX.

Esta versão foi feita para ser fácil de subir no GitHub e executar localmente com Vite.

## O que inclui

- Tela simples de consulta USD/BRL
- Busca retroativa de até 10 dias
- Dados simulados para funcionar offline
- Opção de tentar consultar a API real do Banco Central
- Testes básicos visíveis na própria tela
- Sem `lucide-react`
- Sem `framer-motion`
- Sem `shadcn/ui`

## Como executar

```bash
npm install
npm run dev
```

Depois abra a URL exibida pelo Vite, normalmente:

```text
http://localhost:5173
```

## Como testar

1. Abra o app.
2. Use a data `2026-05-10`.
3. Clique em **Consultar PTAX**.
4. O app deve buscar datas anteriores e encontrar a cotação simulada de `2026-05-08`.

## Consulta real ao Banco Central

Marque **Tentar API real do Banco Central** para consultar:

```text
https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/
```

Em alguns ambientes web a chamada pode falhar por política de rede/CORS. Nesse caso, o app cai para os dados simulados.

## Próximo passo para iPhone

Este projeto é um simulador web. Para app iPhone real, a mesma regra de negócio pode ser portada para SwiftUI usando `URLSession`.
