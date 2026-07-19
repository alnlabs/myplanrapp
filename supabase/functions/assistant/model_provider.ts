// Model provider abstraction. The rest of the function only depends on the
// `extractReceipt` shape, so a self-hosted/fine-tuned model can be swapped in
// later without touching the orchestration or the app.

export interface RawReceiptItem {
  name?: string;
  rawText?: string;
  qty?: number;
  unit?: string;
  unitPrice?: number;
  lineTotal?: number;
}

export interface RawReceipt {
  merchant?: string;
  purchasedAt?: string; // ISO date
  total?: number;
  currency?: string;
  categoryHint?: string;
  items: RawReceiptItem[];
}

export interface ModelProvider {
  extractReceipt(imageBase64: string, mimeType: string): Promise<RawReceipt>;
}

const EXTRACTION_PROMPT = `You are a receipt parser for a household budgeting app.
Read the receipt image and return ONLY a JSON object (no markdown) with this shape:
{
  "merchant": string,              // store/vendor name
  "purchasedAt": string,           // purchase date in ISO format YYYY-MM-DD
  "total": number,                 // grand total actually paid
  "currency": string,              // ISO code if visible, else best guess
  "categoryHint": string,          // one of: Groceries, Utilities, Rent, Transport, Medical, Entertainment, Other
  "items": [
    {
      "name": string,              // clean, human-readable product name (expand abbreviations)
      "rawText": string,           // the raw text as printed
      "qty": number,               // quantity if present, else 1
      "unit": string,              // one of: pcs, kg, g, L, ml, pack (best guess)
      "unitPrice": number,         // price per unit if derivable
      "lineTotal": number          // line total price
    }
  ]
}
Rules:
- Only include real purchased products in "items"; skip subtotals, taxes, discounts, loyalty lines, and payment lines.
- If a value is unknown, omit the field. Never invent totals.
- Numbers must be plain numbers (no currency symbols).`;

/// Google Gemini vision implementation.
export class GeminiModelProvider implements ModelProvider {
  // Ordered candidates. The `-latest` alias tracks the current Flash-Lite (so
  // retirements don't break us); the explicit stable is the fallback if the
  // alias 404s for this key. Google retires model ids periodically, hence the
  // list. A caller-supplied model (ASSISTANT_MODEL) takes priority.
  private readonly candidates: string[];

  constructor(
    private readonly apiKey: string,
    model?: string,
  ) {
    this.candidates = model
      ? [model]
      : ["gemini-flash-lite-latest", "gemini-3.1-flash-lite", "gemini-flash-latest"];
  }

  async extractReceipt(
    imageBase64: string,
    mimeType: string,
  ): Promise<RawReceipt> {
    let lastError: Error | null = null;

    for (const model of this.candidates) {
      const res = await this._generate(model, imageBase64, mimeType);
      if (res.ok) {
        const data = await res.json();
        const text: string | undefined =
          data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) throw new Error("Gemini returned no content");
        const parsed = JSON.parse(text);
        return {
          merchant: parsed.merchant,
          purchasedAt: parsed.purchasedAt,
          total: typeof parsed.total === "number" ? parsed.total : undefined,
          currency: parsed.currency,
          categoryHint: parsed.categoryHint,
          items: Array.isArray(parsed.items) ? parsed.items : [],
        };
      }

      const detail = await res.text();
      lastError = new Error(`Gemini request failed (${res.status}): ${detail}`);
      // Only fall through to the next candidate when the model is missing;
      // for other errors (quota, auth) retrying another model won't help.
      if (res.status !== 404) break;
    }

    throw lastError ?? new Error("Gemini request failed");
  }

  private _generate(
    model: string,
    imageBase64: string,
    mimeType: string,
  ): Promise<Response> {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.apiKey}`;
    return fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: EXTRACTION_PROMPT },
              { inline_data: { mime_type: mimeType, data: imageBase64 } },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          maxOutputTokens: 2048,
        },
      }),
    });
  }
}
