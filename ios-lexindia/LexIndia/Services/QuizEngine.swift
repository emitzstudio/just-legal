//
//  QuizEngine.swift
//  LexIndia
//
//  The quiz system for Students Corner. Questions are generated from the
//  real bundled dataset (BNS sections, IPC → BNS mappings, definitions,
//  landmark cases) plus curated banks for procedure, evidence,
//  constitutional and contract law. Reward amounts are configurable mock
//  values — production economics are finalized later, never in the UI.
//

import Foundation

// MARK: - Topics

nonisolated enum QuizTopic: String, CaseIterable, Identifiable, Hashable, Codable {
    case bns
    case ipcBns
    case bnss
    case evidence
    case constitution
    case contract
    case definitions
    case cases

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bns: return "Criminal Law — BNS"
        case .ipcBns: return "IPC → BNS"
        case .bnss: return "Procedure — BNSS"
        case .evidence: return "Evidence — BSA"
        case .constitution: return "Constitutional Law"
        case .contract: return "Contract Act"
        case .definitions: return "Legal terms"
        case .cases: return "Landmark cases"
        }
    }

    var symbol: String {
        switch self {
        case .bns: return "shield.lefthalf.filled"
        case .ipcBns: return "arrow.left.arrow.right"
        case .bnss: return "list.clipboard"
        case .evidence: return "doc.text.magnifyingglass"
        case .constitution: return "building.columns"
        case .contract: return "signature"
        case .definitions: return "character.book.closed"
        case .cases: return "text.quote"
        }
    }

    var pastelIndex: Int {
        QuizTopic.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Question & rewards

nonisolated struct QuizQuestion: Identifiable, Hashable {
    let id: String
    let topic: QuizTopic
    let prompt: String
    let options: [String]
    let answerIndex: Int
}

nonisolated struct QuizRewardRule: Identifiable, Hashable {
    let questionCount: Int
    let credits: Int
    var id: Int { questionCount }
}

/// MOCK reward configuration — adjust here, never hard-coded in views.
nonisolated enum QuizConfig {
    static let lengths: [QuizRewardRule] = [
        QuizRewardRule(questionCount: 20, credits: 5),
        QuizRewardRule(questionCount: 50, credits: 10),
        QuizRewardRule(questionCount: 100, credits: 15)
    ]

    /// Consecutive 100% quizzes required to unlock the weekly reward.
    static let streakTarget: Int = 5

    /// Score fraction for the encouraging "Excellent work!" headline.
    static let passThreshold: Double = 0.8

    /// One minute per question: 20 → 20 min, 50 → 50 min, 100 → 100 min.
    static func timeLimit(questionCount: Int) -> Int {
        questionCount * 60
    }

    static func rule(for count: Int) -> QuizRewardRule? {
        lengths.first { $0.questionCount == count }
    }
}

// MARK: - Engine

enum QuizEngine {

    /// Every question available for the selected topics.
    static func pool(for topics: Set<QuizTopic>, data: LegalDataService) -> [QuizQuestion] {
        var seen = Set<String>()
        var result: [QuizQuestion] = []
        for topic in QuizTopic.allCases where topics.contains(topic) {
            for question in questions(for: topic, data: data) where seen.insert(question.id).inserted {
                result.append(question)
            }
        }
        return result
    }

    /// A shuffled quiz of `count` questions with shuffled options.
    static func makeQuiz(topics: Set<QuizTopic>, count: Int, data: LegalDataService) -> [QuizQuestion] {
        let selection = pool(for: topics, data: data).shuffled().prefix(count)
        return selection.map { shuffleOptions($0) }
    }

    private static func shuffleOptions(_ question: QuizQuestion) -> QuizQuestion {
        let answer = question.options[question.answerIndex]
        let shuffled = question.options.shuffled()
        return QuizQuestion(
            id: question.id,
            topic: question.topic,
            prompt: question.prompt,
            options: shuffled,
            answerIndex: shuffled.firstIndex(of: answer) ?? 0
        )
    }

    // MARK: Per-topic generation

    private static func questions(for topic: QuizTopic, data: LegalDataService) -> [QuizQuestion] {
        switch topic {
        case .bns: return bnsQuestions(data: data)
        case .ipcBns: return ipcQuestions(data: data)
        case .definitions: return definitionQuestions(data: data)
        case .cases: return caseQuestions(data: data)
        case .bnss: return seeded(.bnss, bank: bnssBank) + actSectionQuestions(actId: "bnss", actLabel: "BNSS", topic: .bnss, data: data)
        case .evidence: return seeded(.evidence, bank: evidenceBank) + actSectionQuestions(actId: "bsa", actLabel: "BSA", topic: .evidence, data: data)
        case .constitution: return seeded(.constitution, bank: constitutionBank) + actSectionQuestions(actId: "constitution", actLabel: "Constitution", topic: .constitution, data: data)
        case .contract: return seeded(.contract, bank: contractBank) + actSectionQuestions(actId: "contract-act", actLabel: "Contract Act", topic: .contract, data: data)
        }
    }

    /// Questions generated from the real BNS text: number → subject and
    /// subject → number, with distractors from the same code.
    private static func bnsQuestions(data: LegalDataService) -> [QuizQuestion] {
        let sections = data.sections(inAct: "bns").filter { $0.title.count >= 4 && $0.title.count <= 64 }
        guard sections.count >= 8 else { return [] }
        let titles = sections.map(\.title)
        let numbers = sections.map { "Section \($0.number)" }

        var result: [QuizQuestion] = []
        for section in sections {
            let correctNumber = "Section \(section.number)"
            let numberOptions = distinctOptions(correct: correctNumber, from: numbers)
            result.append(QuizQuestion(
                id: "bns-n-\(section.id)",
                topic: .bns,
                prompt: "Which section of the BNS deals with \u{201C}\(section.title)\u{201D}?",
                options: numberOptions.options,
                answerIndex: numberOptions.answerIndex
            ))

            let titleOptions = distinctOptions(correct: section.title, from: titles)
            result.append(QuizQuestion(
                id: "bns-t-\(section.id)",
                topic: .bns,
                prompt: "Section \(section.number) of the BNS relates to —",
                options: titleOptions.options,
                answerIndex: titleOptions.answerIndex
            ))
        }
        return result
    }

    /// Renumbering questions from the real IPC → BNS mapping table.
    private static func ipcQuestions(data: LegalDataService) -> [QuizQuestion] {
        let mappings = data.core.ipcMappings
        guard mappings.count >= 6 else { return [] }
        let bnsLabels = mappings.map { "BNS \($0.bnsLabel)" }
        let ipcLabels = mappings.map { "IPC \($0.ipc)" }

        var result: [QuizQuestion] = []
        for mapping in mappings {
            let forward = distinctOptions(correct: "BNS \(mapping.bnsLabel)", from: bnsLabels)
            result.append(QuizQuestion(
                id: "ipc-f-\(mapping.id)",
                topic: .ipcBns,
                prompt: "The offence earlier cited as IPC \(mapping.ipc) (\(mapping.ipcTitle)) is now —",
                options: forward.options,
                answerIndex: forward.answerIndex
            ))

            let reverse = distinctOptions(correct: "IPC \(mapping.ipc)", from: ipcLabels)
            result.append(QuizQuestion(
                id: "ipc-r-\(mapping.id)",
                topic: .ipcBns,
                prompt: "BNS \(mapping.bnsLabel) (\(mapping.ipcTitle)) corresponds to which earlier provision?",
                options: reverse.options,
                answerIndex: reverse.answerIndex
            ))
        }
        return result
    }

    /// "Which term does this describe" from the definitions glossary.
    private static func definitionQuestions(data: LegalDataService) -> [QuizQuestion] {
        let definitions = data.core.definitions
        guard definitions.count >= 4 else { return [] }
        let terms = definitions.map(\.term)

        return definitions.map { definition in
            let meaning = String(definition.meaning.prefix(150))
            let options = distinctOptions(correct: definition.term, from: terms)
            return QuizQuestion(
                id: "def-\(definition.id)",
                topic: .definitions,
                prompt: "Which legal term does this describe: \u{201C}\(meaning)\u{2026}\u{201D}",
                options: options.options,
                answerIndex: options.answerIndex
            )
        }
    }

    /// "Which case is known for this principle" from the case library.
    private static func caseQuestions(data: LegalDataService) -> [QuizQuestion] {
        let cases = data.core.caseLaws
        guard cases.count >= 4 else { return [] }
        let titles = cases.map(\.title)

        return cases.map { caseLaw in
            let principle = String(caseLaw.principle.prefix(150))
            let options = distinctOptions(correct: caseLaw.title, from: titles)
            return QuizQuestion(
                id: "case-\(caseLaw.id)",
                topic: .cases,
                prompt: "Which case is known for: \u{201C}\(principle)\u{201D}?",
                options: options.options,
                answerIndex: options.answerIndex
            )
        }
    }

    /// Number → subject questions for loaded sections of other Acts.
    private static func actSectionQuestions(actId: String, actLabel: String, topic: QuizTopic, data: LegalDataService) -> [QuizQuestion] {
        let sections = data.sections(inAct: actId).filter { $0.title.count >= 4 && $0.title.count <= 64 }
        guard sections.count >= 4 else { return [] }
        let titles = sections.map(\.title)

        return sections.map { section in
            let options = distinctOptions(correct: section.title, from: titles)
            return QuizQuestion(
                id: "act-\(section.id)",
                topic: topic,
                prompt: "Section \(section.number) of the \(actLabel) deals with —",
                options: options.options,
                answerIndex: options.answerIndex
            )
        }
    }

    /// Builds 4 unique options containing the correct answer.
    private static func distinctOptions(correct: String, from all: [String]) -> (options: [String], answerIndex: Int) {
        var wrong = Array(Set(all.filter { $0 != correct })).shuffled().prefix(3)
        while wrong.count < 3 {
            wrong.append("None of the above")
        }
        var options = Array(wrong)
        let index = Int.random(in: 0...options.count)
        options.insert(correct, at: index)
        return (options, index)
    }

    // MARK: Curated banks

    private nonisolated struct Seed {
        let prompt: String
        let correct: String
        let wrong: [String]
    }

    private static func seeded(_ topic: QuizTopic, bank: [Seed]) -> [QuizQuestion] {
        bank.enumerated().map { index, seed in
            let options = [seed.correct] + seed.wrong
            return QuizQuestion(
                id: "\(topic.rawValue)-seed-\(index)",
                topic: topic,
                prompt: seed.prompt,
                options: options,
                answerIndex: 0
            )
        }
    }

    private static let bnssBank: [Seed] = [
        Seed(prompt: "Under the BNSS, an FIR can be registered at any police station regardless of where the offence occurred. This is called —", correct: "Zero FIR", wrong: ["Open FIR", "General diary entry", "Transit FIR"]),
        Seed(prompt: "The BNSS replaced which earlier law?", correct: "Code of Criminal Procedure, 1973", wrong: ["Indian Penal Code, 1860", "Indian Evidence Act, 1872", "Police Act, 1861"]),
        Seed(prompt: "An arrested person must be produced before a magistrate within —", correct: "24 hours", wrong: ["48 hours", "72 hours", "7 days"]),
        Seed(prompt: "Regular bail applications under the BNSS are commonly moved under —", correct: "Sections 480 and 483", wrong: ["Sections 154 and 156", "Sections 41 and 41A", "Sections 200 and 202"]),
        Seed(prompt: "The BNSS came into force on —", correct: "1 July 2024", wrong: ["26 January 2024", "15 August 2023", "1 January 2025"]),
        Seed(prompt: "A confession, to be admissible, is recorded by —", correct: "A Magistrate", wrong: ["The investigating officer", "The public prosecutor", "A court clerk"]),
        Seed(prompt: "A 'cognizable offence' is one where —", correct: "Police may arrest without a warrant", wrong: ["Bail is always granted", "Only the Sessions Court can try it", "The offence is compoundable"]),
        Seed(prompt: "Anticipatory bail is sought —", correct: "Before arrest, in anticipation of it", wrong: ["After conviction", "Only during trial", "Only after the chargesheet"]),
        Seed(prompt: "The BNSS makes forensic investigation mandatory for offences punishable with —", correct: "Seven years or more", wrong: ["Three years or more", "Ten years or more", "Only capital offences"]),
        Seed(prompt: "The default period for filing a chargesheet after arrest is —", correct: "60 or 90 days, by gravity of offence", wrong: ["30 days in all cases", "120 days in all cases", "180 days in all cases"]),
        Seed(prompt: "Summons cases relate to offences punishable with imprisonment —", correct: "Up to two years", wrong: ["Up to seven years", "Up to three years", "Of any term"]),
        Seed(prompt: "Trial in absentia of proclaimed offenders is —", correct: "Newly allowed under the BNSS", wrong: ["Entirely prohibited", "Only for foreign nationals", "Only in terror cases"])
    ]

    private static let evidenceBank: [Seed] = [
        Seed(prompt: "The Bharatiya Sakshya Adhiniyam replaced —", correct: "Indian Evidence Act, 1872", wrong: ["Code of Criminal Procedure, 1973", "Indian Penal Code, 1860", "Civil Procedure Code, 1908"]),
        Seed(prompt: "The burden of proving a fact generally lies on —", correct: "The person who asserts it", wrong: ["The accused", "The investigating officer", "The court"]),
        Seed(prompt: "Electronic records are admissible under the BSA with a certificate under —", correct: "Section 63", wrong: ["Section 45", "Section 27", "Section 118"]),
        Seed(prompt: "A dying declaration is —", correct: "A statement about the cause of death by the person who died", wrong: ["Always inadmissible", "Valid only before police", "A form of confession"]),
        Seed(prompt: "A confession made to a police officer is —", correct: "Generally inadmissible", wrong: ["Always admissible", "Admissible with two witnesses", "Admissible if written"]),
        Seed(prompt: "'Res gestae' covers facts —", correct: "Forming part of the same transaction", wrong: ["Proved only by experts", "Judicially noticed", "About prior convictions"]),
        Seed(prompt: "Facts a court must accept without proof fall under —", correct: "Judicial notice", wrong: ["Estoppel", "Presumption of guilt", "Hearsay"]),
        Seed(prompt: "Expert opinion is relevant on —", correct: "Science, art, handwriting or foreign law", wrong: ["Any disputed fact", "The character of the accused", "The motive of a witness"]),
        Seed(prompt: "The standard of proof in criminal cases is —", correct: "Beyond reasonable doubt", wrong: ["Preponderance of probabilities", "Prima facie satisfaction", "Absolute certainty"]),
        Seed(prompt: "The standard of proof in civil cases is —", correct: "Preponderance of probabilities", wrong: ["Beyond reasonable doubt", "Moral certainty", "Prima facie only"]),
        Seed(prompt: "Leading questions are generally permitted in —", correct: "Cross-examination", wrong: ["Examination-in-chief", "Re-examination", "No stage of trial"]),
        Seed(prompt: "Hearsay evidence is —", correct: "Generally not admissible", wrong: ["Always admissible", "Admissible if in writing", "Equal to direct evidence"])
    ]

    private static let constitutionBank: [Seed] = [
        Seed(prompt: "Equality before the law is guaranteed by —", correct: "Article 14", wrong: ["Article 19", "Article 21", "Article 32"]),
        Seed(prompt: "The right to constitutional remedies before the Supreme Court is under —", correct: "Article 32", wrong: ["Article 226", "Article 21", "Article 136"]),
        Seed(prompt: "Protection of life and personal liberty is under —", correct: "Article 21", wrong: ["Article 14", "Article 19", "Article 25"]),
        Seed(prompt: "Freedom of speech and expression is guaranteed by —", correct: "Article 19(1)(a)", wrong: ["Article 21", "Article 14", "Article 25(1)"]),
        Seed(prompt: "The writ commanding an authority to perform its legal duty is —", correct: "Mandamus", wrong: ["Habeas corpus", "Certiorari", "Quo warranto"]),
        Seed(prompt: "The writ of habeas corpus protects against —", correct: "Unlawful detention", wrong: ["Defamation", "Double jeopardy", "Self-incrimination"]),
        Seed(prompt: "Protection against self-incrimination is under —", correct: "Article 20(3)", wrong: ["Article 21", "Article 22", "Article 19(2)"]),
        Seed(prompt: "Directive Principles of State Policy are contained in —", correct: "Part IV", wrong: ["Part III", "Part V", "Part II"]),
        Seed(prompt: "Fundamental Duties were added by —", correct: "The 42nd Amendment (1976)", wrong: ["The 44th Amendment", "The 73rd Amendment", "The 86th Amendment"]),
        Seed(prompt: "The 'basic structure' doctrine was laid down in —", correct: "Kesavananda Bharati v. State of Kerala (1973)", wrong: ["Golaknath v. State of Punjab", "Maneka Gandhi v. Union of India", "Minerva Mills v. Union of India"]),
        Seed(prompt: "High Courts issue writs under —", correct: "Article 226", wrong: ["Article 32", "Article 141", "Article 136"]),
        Seed(prompt: "Untouchability is abolished by —", correct: "Article 17", wrong: ["Article 15", "Article 16", "Article 23"]),
        Seed(prompt: "Free and compulsory education for children aged 6–14 is under —", correct: "Article 21A", wrong: ["Article 45", "Article 19", "Article 29"]),
        Seed(prompt: "Law declared by the Supreme Court binds all courts under —", correct: "Article 141", wrong: ["Article 142", "Article 136", "Article 32"])
    ]

    private static let contractBank: [Seed] = [
        Seed(prompt: "An agreement enforceable by law is a —", correct: "Contract", wrong: ["Promise", "Proposal", "Consideration"]),
        Seed(prompt: "The Indian Contract Act was enacted in —", correct: "1872", wrong: ["1860", "1930", "1947"]),
        Seed(prompt: "An agreement with a minor is —", correct: "Void ab initio", wrong: ["Voidable", "Valid", "Enforceable on attaining majority"]),
        Seed(prompt: "Consideration means —", correct: "Something in return", wrong: ["Written consent", "A court fee", "A witness signature"]),
        Seed(prompt: "A contract caused by coercion is —", correct: "Voidable at the option of the aggrieved party", wrong: ["Void in all cases", "Fully valid", "Criminal by itself"]),
        Seed(prompt: "'Quantum meruit' means —", correct: "As much as is earned or deserved", wrong: ["A void agreement", "Full liquidated damages", "Specific performance"]),
        Seed(prompt: "An acceptance with modifications amounts to —", correct: "A counter-offer", wrong: ["A valid acceptance", "A completed contract", "An invitation to offer"]),
        Seed(prompt: "Agreements in restraint of trade are —", correct: "Void, subject to limited exceptions", wrong: ["Always valid", "Criminal offences", "Voidable at either side's option"]),
        Seed(prompt: "Compensation for breach of contract is dealt with under —", correct: "Section 73", wrong: ["Section 10", "Section 2(h)", "Section 25"]),
        Seed(prompt: "A contingent contract depends on —", correct: "A collateral uncertain event", wrong: ["Mutual consent alone", "Written form", "Registration"]),
        Seed(prompt: "Goods displayed in a shop window are —", correct: "An invitation to offer", wrong: ["An offer", "An acceptance", "A concluded contract"]),
        Seed(prompt: "An agreement without consideration is generally —", correct: "Void", wrong: ["Valid", "Voidable", "Illegal"])
    ]
}
