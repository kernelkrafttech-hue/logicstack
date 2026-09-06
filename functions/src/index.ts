/**
 * Cloud Functions for MaintenanceOS.
 *
 * The OpenAI API key is held server-side as a Firebase Functions secret
 * (`OPENAI_API_KEY`) and never reaches the Flutter client.
 *
 * Configure once with:
 *   firebase functions:secrets:set OPENAI_API_KEY
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions/v2";
import OpenAI from "openai";

export {
  notifyOnRequestCreated,
  notifyOnRequestUpdated,
  notifyOnCommentCreated,
} from "./notifications";

export {
  seedFreeTrialOnUserCreated,
  createStripeCheckoutSession,
  createStripeCustomerPortalSession,
  stripeWebhook,
} from "./billing";

export {deleteAccount} from "./account";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

const VALID_CATEGORIES = [
  "plumbing",
  "electrical",
  "hvac",
  "appliance",
  "pest",
  "structural",
  "other",
] as const;

const VALID_URGENCIES = ["low", "medium", "high", "emergency"] as const;
type ValidUrgency = (typeof VALID_URGENCIES)[number];

interface AnalyzeRequestData {
  title?: unknown;
  description?: unknown;
  category?: unknown;
  urgency?: unknown;
}

interface AnalyzeResponse {
  aiSummary: string;
  likelyTrade: string;
  urgencySuggestion: ValidUrgency;
  contractorMessage: string;
}

const SYSTEM_PROMPT =
  "You are a property maintenance expert helping a small landlord triage " +
  "incoming repair requests submitted by tenants.\n\n" +
  "Given a tenant's report, return a JSON object with exactly these fields:\n" +
  "- aiSummary: 1-2 plain-language sentences summarising the issue for the " +
  "landlord.\n" +
  "- likelyTrade: the most likely trade or specialty needed " +
  "(e.g. \"Licensed plumber\", \"HVAC technician\", \"General handyman\").\n" +
  "- urgencySuggestion: one of \"low\" | \"medium\" | \"high\" | " +
  "\"emergency\". Choose \"emergency\" when life-safety or major property " +
  "damage is at risk (gas leak, fire, flooding, electrical hazard, no heat " +
  "in winter).\n" +
  "- contractorMessage: 2-4 short, professional sentences the landlord can " +
  "paste when reaching out to a contractor. Use the placeholder " +
  "\"[ADDRESS]\" instead of inventing an address. Do not invent details " +
  "the tenant did not provide.\n\n" +
  "Return ONLY a JSON object. No commentary, no markdown.";

function asNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return trimmed;
}

function asAllowed<T extends readonly string[]>(
  value: unknown,
  allowed: T,
  field: string,
): T[number] {
  if (typeof value !== "string" || !allowed.includes(value as T[number])) {
    throw new HttpsError(
      "invalid-argument",
      `${field} must be one of: ${allowed.join(", ")}.`,
    );
  }
  return value as T[number];
}

export const analyzeMaintenanceRequest = onCall<AnalyzeRequestData>(
  {
    secrets: [openaiApiKey],
    region: "us-central1",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request): Promise<AnalyzeResponse> => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Sign in to analyze a request.",
      );
    }

    const data = request.data ?? {};
    const title = asNonEmptyString(data.title, "title");
    const description = asNonEmptyString(data.description, "description");
    const category = asAllowed(data.category, VALID_CATEGORIES, "category");
    const urgency = asAllowed(data.urgency, VALID_URGENCIES, "urgency");

    const client = new OpenAI({apiKey: openaiApiKey.value()});

    const userPrompt =
      `Tenant-reported issue:\n` +
      `Title: ${title}\n` +
      `Category: ${category}\n` +
      `Tenant urgency: ${urgency}\n` +
      `Description: ${description}`;

    let parsed: Partial<AnalyzeResponse>;
    try {
      const completion = await client.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.3,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "maintenance_analysis",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              required: [
                "aiSummary",
                "likelyTrade",
                "urgencySuggestion",
                "contractorMessage",
              ],
              properties: {
                aiSummary: {type: "string"},
                likelyTrade: {type: "string"},
                urgencySuggestion: {
                  type: "string",
                  enum: [...VALID_URGENCIES],
                },
                contractorMessage: {type: "string"},
              },
            },
          },
        },
        messages: [
          {role: "system", content: SYSTEM_PROMPT},
          {role: "user", content: userPrompt},
        ],
      });

      const content = completion.choices[0]?.message?.content ?? "{}";
      parsed = JSON.parse(content) as Partial<AnalyzeResponse>;
    } catch (err) {
      logger.error("OpenAI analysis failed", err);
      throw new HttpsError(
        "internal",
        "AI analysis failed. Please try again.",
      );
    }

    const fallbackUrgency: ValidUrgency = urgency;
    const suggestedUrgency =
      typeof parsed.urgencySuggestion === "string" &&
      (VALID_URGENCIES as readonly string[]).includes(parsed.urgencySuggestion)
        ? (parsed.urgencySuggestion as ValidUrgency)
        : fallbackUrgency;

    return {
      aiSummary:
        typeof parsed.aiSummary === "string" ? parsed.aiSummary.trim() : "",
      likelyTrade:
        typeof parsed.likelyTrade === "string" ? parsed.likelyTrade.trim() : "",
      urgencySuggestion: suggestedUrgency,
      contractorMessage:
        typeof parsed.contractorMessage === "string"
          ? parsed.contractorMessage.trim()
          : "",
    };
  },
);
