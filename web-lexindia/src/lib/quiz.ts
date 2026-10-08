/**
 * The quiz system for Students Corner. Questions are generated from the
 * real bundled dataset (BNS sections, IPC → BNS mappings, definitions,
 * landmark cases) plus curated banks for procedure, evidence,
 * constitutional and contract law. Ported from QuizEngine on iOS.
 */

import quizBanksData from "@/data/quizBanks.json";
import { legalData } from "./legalData";
import { QUIZ_TOPICS, type QuizQuestion, type QuizTopic } from "./models";

interface Seed {
  prompt: string;
  correct: string;
  wrong: string[];
}

const banks = quizBanksData as Record<"bnss" | "evidence" | "constitution" | "contract", Seed[]>;

const shuffle = <T>(items: T[]): T[] => {
  const copy = [...items];
  for (let index = copy.length - 1; index > 0; index -= 1) {
    const swap = Math.floor(Math.random() * (index + 1));
    [copy[index], copy[swap]] = [copy[swap], copy[index]];
  }
  return copy;
};

/** Builds 4 unique options containing the correct answer. */
function distinctOptions(correct: string, all: string[]): { options: string[]; answerIndex: number } {
  const wrong = shuffle([...new Set(all.filter((item) => item !== correct))]).slice(0, 3);
  while (wrong.length < 3) wrong.push("None of the above");
  const index = Math.floor(Math.random() * (wrong.length + 1));
  const options = [...wrong];
  options.splice(index, 0, correct);
  return { options, answerIndex: index };
}

function bnsQuestions(): QuizQuestion[] {
  const sections = legalData.sectionsInAct("bns").filter((s) => s.title.length >= 4 && s.title.length <= 64);
  if (sections.length < 8) return [];
  const titles = sections.map((section) => section.title);
  const numbers = sections.map((section) => `Section ${section.number}`);
  const result: QuizQuestion[] = [];
  for (const section of sections) {
    const numberOptions = distinctOptions(`Section ${section.number}`, numbers);
    result.push({
      id: `bns-n-${section.id}`,
      topic: "bns",
      prompt: `Which section of the BNS deals with \u201C${section.title}\u201D?`,
      options: numberOptions.options,
      answerIndex: numberOptions.answerIndex,
    });
    const titleOptions = distinctOptions(section.title, titles);
    result.push({
      id: `bns-t-${section.id}`,
      topic: "bns",
      prompt: `Section ${section.number} of the BNS relates to —`,
      options: titleOptions.options,
      answerIndex: titleOptions.answerIndex,
    });
  }
  return result;
}

function ipcQuestions(): QuizQuestion[] {
  const mappings = legalData.core.ipcMappings;
  if (mappings.length < 6) return [];
  const bnsLabels = mappings.map((mapping) => `BNS ${mapping.bnsLabel}`);
  const ipcLabels = mappings.map((mapping) => `IPC ${mapping.ipc}`);
  const result: QuizQuestion[] = [];
  for (const mapping of mappings) {
    const forward = distinctOptions(`BNS ${mapping.bnsLabel}`, bnsLabels);
    result.push({
      id: `ipc-f-${mapping.id}`,
      topic: "ipcBns",
      prompt: `The offence earlier cited as IPC ${mapping.ipc} (${mapping.ipcTitle}) is now —`,
      options: forward.options,
      answerIndex: forward.answerIndex,
    });
    const reverse = distinctOptions(`IPC ${mapping.ipc}`, ipcLabels);
    result.push({
      id: `ipc-r-${mapping.id}`,
      topic: "ipcBns",
      prompt: `BNS ${mapping.bnsLabel} (${mapping.ipcTitle}) corresponds to which earlier provision?`,
      options: reverse.options,
      answerIndex: reverse.answerIndex,
    });
  }
  return result;
}

function definitionQuestions(): QuizQuestion[] {
  const definitions = legalData.core.definitions;
  if (definitions.length < 4) return [];
  const terms = definitions.map((definition) => definition.term);
  return definitions.map((definition) => {
    const options = distinctOptions(definition.term, terms);
    return {
      id: `def-${definition.id}`,
      topic: "definitions" as QuizTopic,
      prompt: `Which legal term does this describe: \u201C${definition.meaning.slice(0, 150)}\u2026\u201D`,
      options: options.options,
      answerIndex: options.answerIndex,
    };
  });
}

function caseQuestions(): QuizQuestion[] {
  const cases = legalData.core.caseLaws;
  if (cases.length < 4) return [];
  const titles = cases.map((caseLaw) => caseLaw.title);
  return cases.map((caseLaw) => {
    const options = distinctOptions(caseLaw.title, titles);
    return {
      id: `case-${caseLaw.id}`,
      topic: "cases" as QuizTopic,
      prompt: `Which case is known for: \u201C${caseLaw.principle.slice(0, 150)}\u201D?`,
      options: options.options,
      answerIndex: options.answerIndex,
    };
  });
}

function actSectionQuestions(actId: string, actLabel: string, topic: QuizTopic): QuizQuestion[] {
  const sections = legalData.sectionsInAct(actId).filter((s) => s.title.length >= 4 && s.title.length <= 64);
  if (sections.length < 4) return [];
  const titles = sections.map((section) => section.title);
  return sections.map((section) => {
    const options = distinctOptions(section.title, titles);
    return {
      id: `act-${section.id}`,
      topic,
      prompt: `Section ${section.number} of the ${actLabel} deals with —`,
      options: options.options,
      answerIndex: options.answerIndex,
    };
  });
}

function seeded(topic: QuizTopic, bank: Seed[]): QuizQuestion[] {
  return bank.map((seed, index) => ({
    id: `${topic}-seed-${index}`,
    topic,
    prompt: seed.prompt,
    options: [seed.correct, ...seed.wrong],
    answerIndex: 0,
  }));
}

function questionsFor(topic: QuizTopic): QuizQuestion[] {
  switch (topic) {
    case "bns":
      return bnsQuestions();
    case "ipcBns":
      return ipcQuestions();
    case "definitions":
      return definitionQuestions();
    case "cases":
      return caseQuestions();
    case "bnss":
      return [...seeded("bnss", banks.bnss), ...actSectionQuestions("bnss", "BNSS", "bnss")];
    case "evidence":
      return [...seeded("evidence", banks.evidence), ...actSectionQuestions("bsa", "BSA", "evidence")];
    case "constitution":
      return [
        ...seeded("constitution", banks.constitution),
        ...actSectionQuestions("constitution", "Constitution", "constitution"),
      ];
    case "contract":
      return [...seeded("contract", banks.contract), ...actSectionQuestions("contract-act", "Contract Act", "contract")];
  }
}

export const QuizEngine = {
  /** Every question available for the selected topics. */
  pool(topics: Set<QuizTopic>): QuizQuestion[] {
    const seen = new Set<string>();
    const result: QuizQuestion[] = [];
    for (const topic of QUIZ_TOPICS) {
      if (!topics.has(topic)) continue;
      for (const question of questionsFor(topic)) {
        if (!seen.has(question.id)) {
          seen.add(question.id);
          result.push(question);
        }
      }
    }
    return result;
  },
  /** Only the pool size — cheap for the setup screen's live counter. */
  poolCount(topics: Set<QuizTopic>): number {
    return this.pool(topics).length;
  },
  /** A shuffled quiz of `count` questions with shuffled options. */
  makeQuiz(topics: Set<QuizTopic>, count: number): QuizQuestion[] {
    const selection: QuizQuestion[] = shuffle<QuizQuestion>(this.pool(topics)).slice(0, count);
    return selection.map((question): QuizQuestion => {
      const answer = question.options[question.answerIndex];
      const options = shuffle<string>(question.options);
      return { ...question, options, answerIndex: Math.max(options.indexOf(answer), 0) };
    });
  },
  shuffle: <T>(items: T[]): T[] => shuffle<T>(items),
};
