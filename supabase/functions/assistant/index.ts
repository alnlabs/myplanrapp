// Receipt analysis edge function.
//
// Input (POST JSON): { imageBase64, fingerprint, mimeType }
// Auth: caller's Supabase JWT (verify_jwt = true). A user-scoped client is built
// from it so every read honors RLS.
//
// Steps: resolve household -> duplicate check by (household_id, fingerprint) ->
// vision extraction -> match line items to pantry + map category -> return
// proposals. This function performs NO writes; the app persists the receipt and
// applies actions after the user confirms.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { GeminiModelProvider, RawReceiptItem } from "./model_provider.ts";

interface RequestBody {
  imageBase64?: string;
  fingerprint?: string;
  mimeType?: string;
  // When true, skip the "already processed" short-circuit (user chose to add
  // the same receipt again anyway).
  force?: boolean;
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// Very small heuristic matcher: exact normalized match -> high confidence,
// substring overlap -> medium. Ambiguity is resolved by the user in the app.
function matchPantry(
  name: string,
  pantry: { id: string; name: string }[],
): { id: string; name: string; confidence: number } | null {
  const target = normalize(name);
  if (!target) return null;

  let best: { id: string; name: string; confidence: number } | null = null;
  for (const item of pantry) {
    const candidate = normalize(item.name);
    if (!candidate) continue;
    let confidence = 0;
    if (candidate === target) {
      confidence = 1;
    } else if (candidate.includes(target) || target.includes(candidate)) {
      confidence = 0.6;
    }
    if (confidence > 0 && (!best || confidence > best.confidence)) {
      best = { id: item.id, name: item.name, confidence };
    }
  }
  return best && best.confidence >= 0.6 ? best : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "Model provider not configured" }, 500);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { imageBase64, fingerprint, mimeType, force } = body;
  if (!imageBase64 || !fingerprint) {
    return jsonResponse({ error: "imageBase64 and fingerprint are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) {
    return jsonResponse({ error: "Not authenticated" }, 401);
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("active_household_id")
    .eq("id", userData.user.id)
    .maybeSingle();
  const householdId = profile?.active_household_id as string | undefined;
  if (!householdId) {
    return jsonResponse({ error: "No active household" }, 400);
  }

  // 1) Receipt-level duplicate check.
  const { data: existing } = await supabase
    .from("receipts")
    .select("id, status")
    .eq("household_id", householdId)
    .eq("fingerprint", fingerprint)
    .maybeSingle();

  if (existing && existing.status === "processed" && !force) {
    return jsonResponse({
      fingerprint,
      alreadyProcessed: true,
      existingReceiptId: existing.id,
      items: [],
    });
  }

  // 2) Per-household daily rate limit (skips duplicates, which never reach here
  // unless forced). Guards the LLM budget against loops/abuse.
  const dailyLimit = Number(Deno.env.get("ASSISTANT_DAILY_LIMIT") ?? "25");
  const { data: allowed, error: usageError } = await supabase.rpc(
    "bump_assistant_usage",
    { p_household_id: householdId, p_limit: dailyLimit },
  );
  if (usageError) {
    return jsonResponse({ error: `Usage check failed: ${usageError.message}` }, 500);
  }
  if (allowed === false) {
    return jsonResponse({
      error: "daily_limit",
      message:
        `Daily scan limit reached (${dailyLimit}). Please try again tomorrow.`,
    }, 429);
  }

  // 3) Vision extraction.
  let raw;
  try {
    const model = Deno.env.get("ASSISTANT_MODEL") ?? undefined;
    const provider = new GeminiModelProvider(apiKey, model);
    raw = await provider.extractReceipt(imageBase64, mimeType ?? "image/jpeg");
  } catch (e) {
    const detail = String(e);
    let message =
      "Couldn't read this receipt. Try a clearer, well-lit photo — or use " +
      '"Paste from your own AI".';
    let status = 502;
    if (detail.includes("429") || detail.includes("RESOURCE_EXHAUSTED")) {
      message =
        "The receipt AI has hit its usage quota. Please try later, or use " +
        '"Paste from your own AI" (no limit).';
      status = 429;
    } else if (
      detail.includes("(400)") ||
      detail.includes("(403)") ||
      detail.includes("(404)") ||
      detail.includes("API key") ||
      detail.includes("API_KEY")
    ) {
      message =
        "Receipt AI isn't configured correctly. Please try " +
        '"Paste from your own AI" for now.';
    }
    // `detail` carries the raw reason for logs; the app shows `message`.
    return jsonResponse(
      { error: "extraction_failed", message, detail: detail.slice(0, 400) },
      status,
    );
  }

  // 4) Load context for matching (RLS-scoped to this user's household).
  const [{ data: pantryRows }, { data: categoryRows }] = await Promise.all([
    supabase
      .from("pantry_items")
      .select("id, name")
      .eq("household_id", householdId),
    supabase
      .from("expense_categories")
      .select("id, name")
      .is("household_id", null),
  ]);

  const pantry = (pantryRows ?? []) as { id: string; name: string }[];
  const categories = (categoryRows ?? []) as { id: string; name: string }[];

  // Map the model's category hint to a real category id (default Groceries).
  const hint = normalize(raw.categoryHint ?? "");
  let suggestedCategory =
    categories.find((c) => normalize(c.name) === hint) ??
    categories.find((c) => normalize(c.name) === "groceries") ??
    categories[0];

  // 5) Build mapped line items.
  const items = (raw.items ?? []).map((item: RawReceiptItem, index: number) => {
    const name = item.name ?? item.rawText ?? "Item";
    const match = matchPantry(name, pantry);
    return {
      lineIndex: index,
      name,
      rawText: item.rawText ?? null,
      qty: typeof item.qty === "number" ? item.qty : 1,
      unit: item.unit ?? "pcs",
      unitPrice: item.unitPrice ?? null,
      lineTotal: item.lineTotal ?? null,
      destination: "pantry",
      matchedItemId: match?.id ?? null,
      matchedItemName: match?.name ?? null,
      matchConfidence: match?.confidence ?? 0,
    };
  });

  return jsonResponse({
    fingerprint,
    merchant: raw.merchant ?? null,
    purchasedAt: raw.purchasedAt ?? null,
    total: typeof raw.total === "number" ? raw.total : null,
    currency: raw.currency ?? null,
    suggestedCategoryId: suggestedCategory?.id ?? null,
    suggestedCategoryName: suggestedCategory?.name ?? null,
    alreadyProcessed: false,
    existingReceiptId: existing?.id ?? null,
    items,
  });
});
