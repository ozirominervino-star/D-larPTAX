import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function formatDateForInput(date) {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    throw new Error("Data inválida.");
  }

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatDateForBcb(dateString) {
  const parts = String(dateString).split("-");
  if (parts.length !== 3) {
    throw new Error("Data deve estar no formato yyyy-MM-dd.");
  }

  const [yyyy, mm, dd] = parts;
  return `${mm}-${dd}-${yyyy}`;
}

function parseInputDateAtNoon(dateString) {
  const parts = String(dateString).split("-").map(Number);
  if (parts.length !== 3 || parts.some(Number.isNaN)) {
    throw new Error("Data inválida.");
  }

  const [year, month, day] = parts;
  return new Date(year, month - 1, day, 12, 0, 0, 0);
}

function subtractDays(dateString, days) {
  const date = parseInputDateAtNoon(dateString);
  date.setDate(date.getDate() - days);
  return formatDateForInput(date);
}

function brl(value) {
  return Number(value).toLocaleString("pt-BR", {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  });
}

const MOCK_QUOTES = {
  "2026-05-08": {
    cotacaoCompra: 5.3012,
    cotacaoVenda: 5.3018,
    dataHoraCotacao: "2026-05-08 13:10:00.000",
  },
  "2026-05-07": {
    cotacaoCompra: 5.2855,
    cotacaoVenda: 5.2861,
    dataHoraCotacao: "2026-05-07 13:10:00.000",
  },
  "2026-05-06": {
    cotacaoCompra: 5.2744,
    cotacaoVenda: 5.275,
    dataHoraCotacao: "2026-05-06 13:10:00.000",
  },
};

async function fetchBcbQuote(dateString) {
  const bcbDate = formatDateForBcb(dateString);
  const encodedDate = encodeURIComponent(`'${bcbDate}'`);
  const url = `https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao=${encodedDate}&$format=json`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error("Resposta inválida do Banco Central.");
  }

  const json = await response.json();
  return Array.isArray(json.value) && json.value.length > 0 ? json.value[0] : null;
}

async function findLatestQuote(selectedDate, options = {}) {
  const { useRealApi = false, maxAttempts = 10 } = options;
  const attempts = [];

  for (let i = 0; i < maxAttempts; i += 1) {
    const currentDate = subtractDays(selectedDate, i);
    attempts.push(currentDate);

    const quote = useRealApi
      ? await fetchBcbQuote(currentDate)
      : MOCK_QUOTES[currentDate] ?? null;

    if (quote) {
      return {
        requestedDate: selectedDate,
        effectiveDate: currentDate,
        buyRate: quote.cotacaoCompra,
        sellRate: quote.cotacaoVenda,
        dataHoraCotacao: quote.dataHoraCotacao,
        attempts,
        source: useRealApi ? "Banco Central" : "Simulação local",
      };
    }
  }

  throw new Error("Cotação não encontrada nos últimos 10 dias.");
}

function runSelfTests() {
  const tests = [];

  function test(name, fn) {
    try {
      fn();
      tests.push({ name, status: "ok" });
    } catch (error) {
      tests.push({ name, status: "fail", message: error.message });
    }
  }

  test("formatDateForBcb converte yyyy-MM-dd para MM-dd-yyyy", () => {
    const result = formatDateForBcb("2026-05-08");
    if (result !== "05-08-2026") {
      throw new Error(`Esperado 05-08-2026, recebido ${result}`);
    }
  });

  test("subtractDays volta um dia corretamente", () => {
    const result = subtractDays("2026-05-10", 1);
    if (result !== "2026-05-09") {
      throw new Error(`Esperado 2026-05-09, recebido ${result}`);
    }
  });

  test("subtractDays atravessa mês corretamente", () => {
    const result = subtractDays("2026-06-01", 1);
    if (result !== "2026-05-31") {
      throw new Error(`Esperado 2026-05-31, recebido ${result}`);
    }
  });

  test("brl formata com quatro casas decimais", () => {
    const result = brl(5.3);
    if (result !== "5,3000") {
      throw new Error(`Esperado 5,3000, recebido ${result}`);
    }
  });

  return tests;
}

function App() {
  const today = useMemo(() => "2026-05-10", []);
  const selfTests = useMemo(() => runSelfTests(), []);
  const hasFailingTests = selfTests.some((item) => item.status === "fail");

  const [selectedDate, setSelectedDate] = useState(today);
  const [useRealApi, setUseRealApi] = useState(false);
  const [state, setState] = useState({ type: "idle" });

  async function consult() {
    setState({ type: "loading" });

    try {
      const result = await findLatestQuote(selectedDate, { useRealApi });
      setState({ type: "success", result });
    } catch (error) {
      if (useRealApi) {
        try {
          const fallback = await findLatestQuote(selectedDate, { useRealApi: false });
          setState({
            type: "success",
            result: {
              ...fallback,
              source: "Simulação local após falha da consulta real",
              warning:
                "A consulta real pode ter sido bloqueada pelo ambiente de pré-visualização. No app iOS, a chamada HTTPS deve funcionar normalmente.",
            },
          });
          return;
        } catch {
          setState({ type: "error", message: error.message });
          return;
        }
      }

      setState({ type: "error", message: error.message });
    }
  }

  return (
    <main className="page">
      <section className="card">
        <header>
          <h1>Dólar PTAX</h1>
          <p>Simulação da tela simples do app iPhone.</p>
        </header>

        <div className="field">
          <label htmlFor="date">📅 Data da cotação</label>
          <input
            id="date"
            type="date"
            value={selectedDate}
            onChange={(event) => setSelectedDate(event.target.value)}
          />
        </div>

        <label className="switch-row">
          <span>Tentar API real do Banco Central</span>
          <input
            type="checkbox"
            checked={useRealApi}
            onChange={(event) => setUseRealApi(event.target.checked)}
          />
        </label>

        <button onClick={consult} disabled={state.type === "loading"}>
          {state.type === "loading" ? "↻ Consultando..." : "Consultar PTAX"}
        </button>

        {state.type === "idle" && (
          <div className="empty">
            Escolha uma data e consulte. O simulador busca até 10 dias anteriores.
          </div>
        )}

        {state.type === "error" && <div className="message error">⚠️ {state.message}</div>}

        {state.type === "success" && (
          <div className="quote">
            <div className="quote-header">
              <div>
                <small>Moeda</small>
                <strong>USD/BRL</strong>
              </div>
              <span>{state.result.source}</span>
            </div>

            <div className="rates">
              <div>
                <small>Compra</small>
                <strong>R$ {brl(state.result.buyRate)}</strong>
              </div>
              <div>
                <small>Venda</small>
                <strong>R$ {brl(state.result.sellRate)}</strong>
              </div>
            </div>

            <div className="details">
              <p>
                Data solicitada: <strong>{state.result.requestedDate}</strong>
              </p>
              <p>
                Data efetiva: <strong>{state.result.effectiveDate}</strong>
              </p>
              <p>
                Data/hora PTAX: <strong>{state.result.dataHoraCotacao}</strong>
              </p>
            </div>

            {state.result.requestedDate !== state.result.effectiveDate && (
              <p className="message">
                Não havia cotação na data solicitada. Foi usada a última data disponível anterior.
              </p>
            )}

            {state.result.warning && <p className="hint">{state.result.warning}</p>}

            <div>
              <small>Datas testadas</small>
              <div className="attempts">
                {state.result.attempts.map((attempt) => (
                  <span key={attempt}>{attempt}</span>
                ))}
              </div>
            </div>
          </div>
        )}

        <section className="tests">
          <div className="tests-header">
            <strong>Testes da lógica</strong>
            <span>{hasFailingTests ? "Falhou" : "OK"}</span>
          </div>
          {selfTests.map((test) => (
            <p key={test.name} className={test.status === "ok" ? "test-ok" : "test-fail"}>
              {test.status === "ok" ? "✓" : "✕"} {test.name}
              {test.message ? ` — ${test.message}` : ""}
            </p>
          ))}
        </section>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
