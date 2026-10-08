/**
 * E-Vakeel's brain, behind a provider seam. The mock provider grounds
 * answers in the curated scenario bank and the bundled dataset; a real AI
 * provider can implement the same contract later without UI changes.
 * Ported from AskEngine, EVakeelEngine and EVakeelScenarios on iOS.
 */

import scenariosData from "@/data/scenarios.json";
import { legalData } from "./legalData";
import { EVakeelPricing, type EVakeelScenario } from "./models";
import { search } from "./search";

const scenarios = scenariosData as EVakeelScenario[];

const tokens = (text: string): string[] => text.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter(Boolean);

const containsPhrase = (haystack: string[], phrase: string[]): boolean => {
  if (phrase.length === 0 || haystack.length < phrase.length) return false;
  for (let start = 0; start <= haystack.length - phrase.length; start += 1) {
    let matches = true;
    for (let offset = 0; offset < phrase.length; offset += 1) {
      if (haystack[start + offset] !== phrase[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
};

/**
 * Best-matching scenario for a question, or null to fall back to dataset
 * retrieval. The longest matched phrase wins.
 */
export function matchScenario(question: string): EVakeelScenario | null {
  const questionTokens = tokens(question);
  if (questionTokens.length === 0) return null;
  let best: { scenario: EVakeelScenario; score: number } | null = null;
  for (const scenario of scenarios) {
    for (const phrase of scenario.phrases) {
      const phraseTokens = tokens(phrase);
      if (!containsPhrase(questionTokens, phraseTokens)) continue;
      const score = phraseTokens.length * 100 + phrase.length;
      if (best === null || score > best.score) best = { scenario, score };
    }
  }
  return best?.scenario ?? null;
}

// MARK: - Dataset retrieval

export interface AskAnswer {
  matched: boolean;
  lead: string;
  body: string;
  example: string | null;
  mappingNote: string | null;
  sectionIds: string[];
  definitionIds: string[];
}

export function answerFor(rawQuery: string): AskAnswer {
  const query = rawQuery.trim();
  const lead = "Based on the legal information in LexIndia:";
  if (!query) {
    return { matched: false, lead, body: "", example: null, mappingNote: null, sectionIds: [], definitionIds: [] };
  }

  const results = search(query);

  let mappingNote: string | null = null;
  const numericOnly = tokens(query).filter((token) => /^\d/.test(token));
  const mapping = results.mappings[0];
  if (mapping && numericOnly.some((token) => mapping.ipc.toLowerCase().includes(token))) {
    mappingNote = `IPC ${mapping.ipc} — ${mapping.ipcTitle} — is now Section ${mapping.bnsLabel} of the Bharatiya Nyaya Sanhita, 2023.`;
  }

  const queryLower = query.toLowerCase();
  const asksForMeaning =
    queryLower.startsWith("what is") ||
    queryLower.startsWith("what does") ||
    queryLower.includes("meaning of") ||
    queryLower.startsWith("define");
  const firstDefinition = results.definitions[0];
  if (
    asksForMeaning &&
    firstDefinition &&
    (queryLower.includes(firstDefinition.term.toLowerCase().slice(0, 6)) || results.sections.length === 0)
  ) {
    return {
      matched: true,
      lead,
      body: firstDefinition.meaning,
      example: null,
      mappingNote,
      sectionIds: firstDefinition.relatedSectionIds.slice(0, 2),
      definitionIds: [firstDefinition.id],
    };
  }

  const topHits = results.sections.slice(0, 3);
  const best = topHits.find((hit) => hit.section.curated === true)?.section ?? results.sections[0]?.section;
  if (best) {
    const provisionIds: string[] = [best.id];
    for (const related of best.relatedSectionIds) {
      if (provisionIds.length >= 3) break;
      if (results.sections.some((hit) => hit.section.id === related && hit.section.id !== best.id)) {
        provisionIds.push(related);
      }
    }
    if (provisionIds.length === 1) {
      const second = results.sections.find((hit) => hit.section.id !== best.id)?.section;
      if (second) provisionIds.push(second.id);
    }
    const hasGuide = best.curated === true;
    const actName = legalData.act(best.actId);
    const body = hasGuide
      ? best.explanation
      : `Section ${best.number} of ${actName ? (actName.shortName ?? actName.name) : "the law"} — ${best.title} — covers this. Its full official text is available in the reader below; the plain-language LexIndia guide for it is being prepared.`;
    return {
      matched: true,
      lead,
      body,
      example: hasGuide ? (best.example ?? null) : null,
      mappingNote,
      sectionIds: provisionIds,
      definitionIds: best.definitionIds.slice(0, 2),
    };
  }

  if (firstDefinition) {
    return {
      matched: true,
      lead,
      body: firstDefinition.meaning,
      example: null,
      mappingNote,
      sectionIds: firstDefinition.relatedSectionIds.slice(0, 2),
      definitionIds: [firstDefinition.id],
    };
  }

  return {
    matched: false,
    lead,
    body: "I couldn't find this in the legal information currently available in LexIndia. Try asking with a section number (like 318), a legal term (like cheating), or browse the Library.",
    example: null,
    mappingNote,
    sectionIds: [],
    definitionIds: [],
  };
}

// MARK: - Provider

export interface EVakeelReply {
  lead: string | null;
  text: string;
  mappingNote: string | null;
  sectionIds: string[];
  matched: boolean;
  cost: number;
  needsAdvocate: boolean;
}

/** Heuristic escalation — serious personal matters get an advocate advisory. */
export function soundsSerious(question: string): boolean {
  const lower = question.toLowerCase();
  const signals = [
    "arrest",
    "arrested",
    "custody",
    "fir against",
    "against me",
    "summon",
    "court date",
    "hearing tomorrow",
    "police called",
    "threatened",
    "jail",
    "divorce",
    "dowry case",
    "bail hearing",
    "chargesheet",
    "convicted",
    "notice received",
  ];
  return signals.some((signal) => lower.includes(signal));
}

const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Local mock provider: curated scenarios first, then dataset retrieval. */
export async function mockReply(question: string): Promise<EVakeelReply> {
  await sleep(900);

  const scenario = matchScenario(question);
  if (scenario) {
    return {
      lead: "Based on the legal information in LexIndia:",
      text: scenario.body,
      mappingNote: null,
      sectionIds: scenario.sectionIds,
      matched: true,
      cost: EVakeelPricing.estimatedCost(question),
      needsAdvocate: scenario.serious || soundsSerious(question),
    };
  }

  const answer = answerFor(question);
  return {
    lead: answer.matched ? answer.lead : null,
    text: answer.body,
    mappingNote: answer.mappingNote,
    sectionIds: answer.sectionIds,
    matched: answer.matched,
    cost: answer.matched ? EVakeelPricing.estimatedCost(question) : 0,
    needsAdvocate: soundsSerious(question),
  };
}
