//
//  ContentCatalog.swift
//  LexIndia
//
//  Demo catalogs for Legal Updates and Documents. These stand in for the
//  production editorial system (Source → Review → LexIndia summary →
//  Publish) and the production document store. Nothing here is scraped —
//  updates are original demo summaries, clearly marked in the UI.
//

import Foundation

// MARK: - Legal Updates (demo editorial content)

nonisolated enum LegalUpdatesCatalog {
    static func update(_ id: String) -> LegalUpdate? {
        updates.first { $0.id == id }
    }

    static func updates(in category: UpdateCategory?) -> [LegalUpdate] {
        guard let category else { return updates }
        return updates.filter { $0.category == category }
    }

    static let updates: [LegalUpdate] = [
        LegalUpdate(
            id: "u-2026-bail-timelines",
            category: .supremeCourt,
            title: "Bail first, jail after: timelines under the new procedure code re-emphasised",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "14 Aug 2026",
            snippet: "Trial courts reminded that bail applications should be decided within the timelines the 2023 procedure code envisages.",
            body: [
                "The Supreme Court has again underlined that bail is the rule and jail the exception, urging trial courts to decide bail applications promptly rather than letting them linger through repeated adjournments.",
                "Under the Bharatiya Nagarik Suraksha Sanhita, 2023, bail provisions were consolidated with an emphasis on time-bound decisions, especially for first-time and undertrial prisoners who have served substantial portions of the maximum sentence.",
                "For practitioners, the practical takeaway is documentation: applications that clearly set out the offence, the custody period and the accused's roots in society travel faster through the system."
            ],
            relatedSectionIds: []
        ),
        LegalUpdate(
            id: "u-2026-digital-arrest",
            category: .judgment,
            title: "'Digital arrest' scams are plain cheating and impersonation, courts confirm",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "11 Aug 2026",
            snippet: "Video-call intimidation scams are being charged as cheating, cheating by personation and extortion under the BNS.",
            body: [
                "Courts across the country are treating so-called 'digital arrest' frauds — where callers pose as police or customs officers on video calls and extract money — as offences of cheating and cheating by personation under the Bharatiya Nyaya Sanhita.",
                "Charges typically combine Section 318 (cheating), Section 319 (cheating by personation) and, where threats of arrest are used to extract payment, extortion provisions.",
                "The pattern matters for victims: transferring money under fear of a fake 'arrest warrant' does not make the transfer voluntary, and prompt reporting through cybercrime portals materially improves recovery chances."
            ],
            relatedSectionIds: ["bns-318", "bns-319"]
        ),
        LegalUpdate(
            id: "u-2026-organised-crime",
            category: .highCourt,
            title: "What counts as 'petty organised crime'? High Courts sketch the boundaries",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "6 Aug 2026",
            snippet: "The new organised-crime provisions of the BNS are being read to require a group, a pattern, and general public alarm.",
            body: [
                "The BNS brought organised crime into the general penal code for the first time — Section 111 for organised crime and Section 112 for petty organised crime committed by groups or gangs.",
                "High Courts have begun clarifying that a single offence by a single person is not 'organised' crime: the provisions contemplate continuing unlawful activity by groups, with snatching, theft and ticket-black-marketing rackets as typical examples.",
                "The distinction has real sentencing consequences, so charge-framing under these sections is being examined closely at the trial stage."
            ],
            relatedSectionIds: ["bns-111", "bns-112"]
        ),
        LegalUpdate(
            id: "u-2026-codes-anniversary",
            category: .newLaw,
            title: "Two years of the 2023 codes: what has settled, what is still open",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "1 Jul 2026",
            snippet: "The BNS, BNSS and BSA complete two years in force. Transition questions are narrowing to a few recurring themes.",
            body: [
                "Since 1 July 2024, the Bharatiya Nyaya Sanhita, the Bharatiya Nagarik Suraksha Sanhita and the Bharatiya Sakshya Adhiniyam have replaced the IPC, CrPC and Evidence Act for new offences.",
                "The most litigated transition question — which code applies to offences committed before the switchover but reported after — has largely settled: the date of the offence governs the substantive law, while procedure follows the new code.",
                "Renumbering remains the biggest everyday friction. Courts, police and practitioners still work with dual citations, which is why IPC → BNS mapping tables are now a standard annexure in charge sheets.",
                "LexIndia's converter covers the commonly used mappings, and every BNS section page shows its old IPC reference where a reliable correspondence exists."
            ],
            relatedSectionIds: ["bns-103", "bns-318", "bns-303"]
        ),
        LegalUpdate(
            id: "u-2026-cyber-amendment",
            category: .amendment,
            title: "Draft amendment floats sharper definitions for online deception",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "22 Jul 2026",
            snippet: "A consultation draft proposes explicit language for impersonation through synthetic media within the cheating framework.",
            body: [
                "A consultation draft circulated for public comment proposes clarifying that impersonation by means of synthetic or AI-generated media falls squarely within cheating by personation.",
                "The draft does not create a new offence; it clarifies the existing Section 318–319 framework so that investigating officers need not stretch definitions when deepfakes are used to induce payments.",
                "Stakeholder comments are open. If adopted, the change would flow into charge sheets without altering the section numbering LexIndia readers already know."
            ],
            relatedSectionIds: ["bns-318"]
        ),
        LegalUpdate(
            id: "u-2026-efiling",
            category: .notification,
            title: "E-filing expands: standard court forms accepted digitally in more districts",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "18 Jul 2026",
            snippet: "More district courts now accept vakalatnamas, bail applications and affidavits filed through the e-filing portal.",
            body: [
                "Court administration notifications continue extending e-filing to district courts, with standard formats — vakalatnama, bail application, affidavits — accepted digitally alongside physical filing.",
                "Formats remain unchanged: the same documents you print and file across the counter are uploaded as PDFs, with e-signatures accepted for an increasing set of filings.",
                "LexIndia's Documents area carries printable versions of the common formats so a working draft is never more than a download away."
            ],
            relatedSectionIds: []
        ),
        LegalUpdate(
            id: "u-2026-snatching",
            category: .judgment,
            title: "Snatching stands on its own: the new dedicated offence in practice",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "9 Jul 2026",
            snippet: "Chain- and phone-snatching cases are now charged under the BNS's dedicated snatching provision rather than as simple theft.",
            body: [
                "The BNS carved snatching out of ordinary theft: Section 304 defines it as theft by sudden or quick or forcible seizure from a person's body or possession.",
                "Trial courts are applying the distinction consistently — a pickpocketing remains theft under Section 303, while a drive-by phone grab is snatching, which carries its own punishment scale.",
                "For readers coming from the IPC, this is one of the genuinely new offences with no direct predecessor section."
            ],
            relatedSectionIds: ["bns-304", "bns-303"]
        ),
        LegalUpdate(
            id: "u-2026-community-service",
            category: .supremeCourt,
            title: "Community service arrives in sentencing: early trends",
            source: "LexIndia Desk · Demo summary",
            dateLabel: "28 Jun 2026",
            snippet: "The BNS made community service a formal punishment for a set of minor offences. Courts are beginning to use it.",
            body: [
                "Community service entered the general punishment scale with the BNS — a first for Indian criminal law, available for a small set of minor offences such as petty defamation and certain public nuisances.",
                "Early sentencing data suggests magistrates favour it for first-time offenders where a short jail term would be disproportionate, pairing it with reporting requirements.",
                "The provision list is short but the signal is larger: proportionality is now written into the code's punishment options."
            ],
            relatedSectionIds: ["bns-226"]
        )
    ]
}

// MARK: - Documents (Bare Acts + downloadable formats)

nonisolated enum DocumentCatalog {
    static func document(_ id: String) -> LexDocument? {
        documents.first { $0.id == id }
    }

    static func documents(of kind: DocumentKind) -> [LexDocument] {
        documents.filter { $0.kind == kind }
    }

    static let documents: [LexDocument] = bareActs + courtForms + examNotes + previousPapers + revision

    // MARK: Bare Acts — read inside LexIndia, never downloadable

    static let bareActs: [LexDocument] = [
        LexDocument(
            id: "doc-ba-bns",
            kind: .bareAct,
            title: "Bharatiya Nyaya Sanhita, 2023",
            summary: "India's penal code — all 358 sections with LexIndia guides, IPC references and landmark cases.",
            meta: "358 sections · In force since 1 July 2024",
            actId: "bns",
            body: []
        ),
        LexDocument(
            id: "doc-ba-bnss",
            kind: .bareAct,
            title: "Bharatiya Nagarik Suraksha Sanhita, 2023",
            summary: "The procedure code that replaced the CrPC — arrest, bail, investigation and trial.",
            meta: "531 sections · Being prepared for LexIndia",
            actId: "bnss",
            body: []
        ),
        LexDocument(
            id: "doc-ba-bsa",
            kind: .bareAct,
            title: "Bharatiya Sakshya Adhiniyam, 2023",
            summary: "The evidence code that replaced the Evidence Act — proof, witnesses and electronic records.",
            meta: "170 sections · Being prepared for LexIndia",
            actId: "bsa",
            body: []
        )
    ]

    // MARK: Court forms — practical, printable formats

    static let courtForms: [LexDocument] = [
        LexDocument(
            id: "doc-cf-vakalatnama",
            kind: .courtForm,
            title: "Vakalatnama",
            summary: "The standard form appointing an advocate to appear and act on a client's behalf.",
            meta: "1 page · Format for reference",
            actId: nil,
            body: [
                "IN THE COURT OF ____________________________ AT ____________________________",
                "Case / Suit No. __________ of 20____",
                "IN THE MATTER OF:  ____________________________ (Plaintiff / Petitioner / Complainant)  VERSUS  ____________________________ (Defendant / Respondent / Accused)",
                "KNOW ALL to whom these presents shall come that I / We, ____________________________, the above-named, do hereby appoint and retain Advocate ____________________________ (Enrolment No. __________) to appear, plead and act on my / our behalf in the above matter and in all proceedings arising from it.",
                "I / We authorise the Advocate to sign, verify and file pleadings, applications and documents; to withdraw or compromise the matter on my / our written instructions; to deposit and withdraw money on my / our behalf; and to engage any other Advocate at my / our cost if required.",
                "IN WITNESS WHEREOF, I / We have signed this Vakalatnama at ______________ on this ____ day of ______________ 20____.",
                "Signature of Client: ____________________     Accepted by: Advocate ____________________ (Chamber address and contact)"
            ]
        ),
        LexDocument(
            id: "doc-cf-bail",
            kind: .courtForm,
            title: "Bail application (BNSS)",
            summary: "Skeleton application for regular bail under the Bharatiya Nagarik Suraksha Sanhita, 2023.",
            meta: "2 pages · Format for reference",
            actId: nil,
            body: [
                "IN THE COURT OF THE ____________________________ (Sessions Judge / Judicial Magistrate) AT ______________",
                "Bail Application No. __________ of 20____  ·  FIR No. __________, Police Station ______________",
                "APPLICATION FOR BAIL UNDER SECTION 480 / 483 OF THE BHARATIYA NAGARIK SURAKSHA SANHITA, 2023",
                "MOST RESPECTFULLY SHOWETH:",
                "1. That the applicant was arrested on __________ in connection with FIR No. __________ registered for offences under Sections __________ of the Bharatiya Nyaya Sanhita, 2023.",
                "2. That the applicant is innocent and has been falsely implicated in the present case; nothing incriminating has been recovered from the applicant.",
                "3. That the applicant is a permanent resident of ______________ with deep roots in society, and there is no likelihood of the applicant absconding or tampering with evidence.",
                "4. That the investigation is complete / the applicant is no longer required for custodial interrogation, and continued detention would serve no purpose.",
                "5. That the applicant undertakes to abide by every condition this Hon'ble Court may impose.",
                "PRAYER: It is therefore most respectfully prayed that this Hon'ble Court may kindly release the applicant on bail in connection with FIR No. __________, Police Station ______________. Any other order deemed fit in the interest of justice may also be passed.",
                "Place: __________   Date: __________                    Advocate for the Applicant"
            ]
        ),
        LexDocument(
            id: "doc-cf-affidavit",
            kind: .courtForm,
            title: "General affidavit",
            summary: "General-purpose affidavit format for court and administrative filings.",
            meta: "1 page · Format for reference",
            actId: nil,
            body: [
                "AFFIDAVIT",
                "I, ____________________________, son / daughter / spouse of ____________________________, aged ____ years, resident of ____________________________, do hereby solemnly affirm and declare as under:",
                "1. That I am the deponent herein and am fully conversant with the facts of the present matter.",
                "2. That ________________________________________________________________________.",
                "3. That ________________________________________________________________________.",
                "4. That the contents of this affidavit are true and correct to my knowledge, no part of it is false and nothing material has been concealed.",
                "DEPONENT",
                "VERIFICATION: Verified at ______________ on this ____ day of ______________ 20____ that the contents of the above affidavit are true and correct to my knowledge and belief.",
                "DEPONENT"
            ]
        ),
        LexDocument(
            id: "doc-cf-rti",
            kind: .courtForm,
            title: "RTI application",
            summary: "Application seeking information under Section 6(1) of the Right to Information Act, 2005.",
            meta: "1 page · Format for reference",
            actId: nil,
            body: [
                "To: The Public Information Officer, ____________________________ (Name and address of the Public Authority)",
                "Subject: Application under Section 6(1) of the Right to Information Act, 2005",
                "1. Name of the applicant: ____________________________",
                "2. Address for correspondence: ____________________________",
                "3. Particulars of the information sought: (a) Subject matter: ______________ (b) Period to which it relates: ______________ (c) Specific details: ________________________________________.",
                "4. I state that the information sought does not, to my knowledge, fall within the exemptions of Sections 8 and 9 of the Act and pertains to your office.",
                "5. The application fee of ₹10/- has been deposited vide receipt / Indian Postal Order No. __________ dated __________.",
                "Place: __________   Date: __________                    Signature of the Applicant"
            ]
        ),
        LexDocument(
            id: "doc-cf-legal-notice",
            kind: .courtForm,
            title: "Legal notice",
            summary: "Standard structure of a legal notice sent before initiating proceedings.",
            meta: "1 page · Format for reference",
            actId: nil,
            body: [
                "LEGAL NOTICE  (Under instructions from and on behalf of my client)",
                "To: ____________________________ (Name and address of the noticee)",
                "Under instructions from and on behalf of my client, ____________________________, resident of ____________________________, I hereby serve upon you the following notice:",
                "1. That ________________________________________________________________________ (state the facts giving rise to the claim, in numbered paragraphs).",
                "2. That by the acts stated above you have ________________________________________ (state the legal wrong and the provision relied upon).",
                "3. That my client calls upon you to ______________________________________________ within ____ days of receipt of this notice, failing which my client shall be constrained to initiate appropriate civil and / or criminal proceedings against you, entirely at your risk as to costs and consequences.",
                "A copy of this notice is retained in my office for record and further action.",
                "Place: __________   Date: __________                    Advocate for the Noticing Party"
            ]
        )
    ]

    // MARK: Exam notes — LexIndia's own study notes

    static let examNotes: [LexDocument] = [
        LexDocument(
            id: "doc-en-bns-map",
            kind: .examNote,
            title: "BNS at a glance — all 20 chapters",
            summary: "One-page map of the Bharatiya Nyaya Sanhita: every chapter with its section range.",
            meta: "2 pages · Updated Aug 2026",
            actId: nil,
            body: [
                "The Bharatiya Nyaya Sanhita, 2023 contains 358 sections across 20 chapters. This map is the fastest way to place any section number in its context.",
                "Ch I — Preliminary (ss. 1–3): title, application, general explanations. Ch II — Punishments (ss. 4–13): the punishment scale, now including community service. Ch III — General Exceptions (ss. 14–44): mistake, accident, necessity, insanity, intoxication, consent, and the right of private defence (ss. 34–44).",
                "Ch IV — Abetment, Conspiracy and Attempt (ss. 45–62). Ch V — Offences Against Woman and Child (ss. 63–99): rape (63–64), dowry death (80), cruelty (85–86), kidnapping-related offences against children.",
                "Ch VI — Offences Affecting the Human Body (ss. 100–146): culpable homicide (100), murder (101, punishment 103), negligence (106), hurt (114–125), wrongful restraint and confinement (126–127), force and assault (128–136), kidnapping and abduction (137–146).",
                "Ch VII — State (ss. 147–158). Ch VIII — Army, Navy and Air Force (ss. 159–168). Ch IX — Elections (ss. 169–177). Ch X — Coin, Currency and Government Stamps (ss. 178–188). Ch XI — Public Tranquillity (ss. 189–197): unlawful assembly, rioting, promoting enmity.",
                "Ch XII — Public Servants (ss. 198–205). Ch XIII — Contempt of Lawful Authority of Public Servants (ss. 206–226). Ch XIV — False Evidence and Offences Against Public Justice (ss. 227–269).",
                "Ch XV — Public Health, Safety, Convenience, Decency and Morals (ss. 270–297). Ch XVI — Religion (ss. 298–302). Ch XVII — Offences Against Property (ss. 303–334): theft (303), snatching (304), robbery and dacoity (309–313), criminal breach of trust (316), cheating (318), mischief, criminal trespass.",
                "Ch XVIII — Documents and Property Marks (ss. 335–350): forgery and counterfeiting. Ch XIX — Criminal Intimidation, Insult, Annoyance and Defamation (ss. 351–357). Ch XX — Repeal and Savings (s. 358).",
                "Exam tip: examiners love chapter boundaries. Remember that 303 opens Property (theft) and 100 opens Human Body (culpable homicide) — most numbering questions hang off these anchors."
            ]
        ),
        LexDocument(
            id: "doc-en-ipc-bns",
            kind: .examNote,
            title: "IPC → BNS quick chart",
            summary: "The renumbering pairs every student and practitioner must know cold.",
            meta: "2 pages · Updated Aug 2026",
            actId: nil,
            body: [
                "The pairs below cover the overwhelming majority of everyday citations. Where a provision was reworked rather than renumbered, the note says so — equivalence is not claimed.",
                "Homicide: IPC 302 (murder) → BNS 103 · IPC 304 (culpable homicide) → BNS 105 · IPC 304A (death by negligence) → BNS 106 · IPC 304B (dowry death) → BNS 80.",
                "Property: IPC 379 (theft) → BNS 303(2) · IPC 392 (robbery) → BNS 309 · IPC 395 (dacoity) → BNS 310 · IPC 406 (criminal breach of trust) → BNS 316 · IPC 420 (cheating) → BNS 318(4). New: snatching is BNS 304, with no IPC predecessor.",
                "Women and children: IPC 375/376 (rape) → BNS 63/64 · IPC 354 (outraging modesty) → BNS 74 · IPC 498A (cruelty) → BNS 85 · IPC 363 (kidnapping) → BNS 137.",
                "Public order and state: IPC 124A (sedition) → reworked as BNS 152 (acts endangering sovereignty, unity and integrity) · IPC 141–149 (unlawful assembly, rioting) → BNS 189–191 · IPC 153A → BNS 196.",
                "Miscellaneous: IPC 506 (criminal intimidation) → BNS 351 · IPC 499/500 (defamation) → BNS 356 · IPC 511 (attempt) → BNS 62 · IPC 309 (attempt to suicide) → no direct equivalent; see BNS 226 for attempt to compel a public servant.",
                "Always verify against the official correspondence tables before citing in court — this chart is a memory aid, not an authority."
            ]
        ),
        LexDocument(
            id: "doc-en-maxims",
            kind: .examNote,
            title: "Legal maxims — the essential set",
            summary: "High-frequency Latin maxims with plain meanings, as asked in judiciary and CLAT papers.",
            meta: "2 pages · Updated Jul 2026",
            actId: nil,
            body: [
                "Actus non facit reum nisi mens sit rea — an act does not make one guilty unless the mind is also guilty. The foundation of mens rea in criminal law.",
                "Actus reus — the guilty act; the physical element of a crime, paired with mens rea.",
                "Audi alteram partem — hear the other side. No one should be condemned unheard; a pillar of natural justice.",
                "Nemo judex in causa sua — no one should be a judge in their own cause; the rule against bias.",
                "Ignorantia juris non excusat — ignorance of the law is no excuse; but ignorantia facti excusat — ignorance of fact can excuse.",
                "Ei incumbit probatio qui dicit — the burden of proof lies on the one who asserts, not on the one who denies; the presumption of innocence.",
                "Nemo tenetur seipsum accusare — no one is bound to accuse themselves; the right against self-incrimination (Article 20(3)).",
                "Res ipsa loquitur — the thing speaks for itself; negligence inferred from the very nature of the accident.",
                "Volenti non fit injuria — no injury is done to one who consents; the consent defence in torts.",
                "Nullum crimen sine lege, nulla poena sine lege — no crime and no punishment without a pre-existing law; the bar on ex post facto criminal laws.",
                "Locus standi — the standing to bring an action before a court.",
                "Res judicata — a matter already judged cannot be re-litigated between the same parties.",
                "Doli incapax — incapable of criminal intent; the presumption protecting young children (BNS ss. 20–21).",
                "In pari delicto — where both parties are equally at fault, the defendant's position is the stronger."
            ]
        ),
        LexDocument(
            id: "doc-en-cases",
            kind: .examNote,
            title: "Landmark cases digest",
            summary: "The criminal-law cases every paper expects, each in three lines.",
            meta: "2 pages · Updated Jul 2026",
            actId: nil,
            body: [
                "K.M. Nanavati v. State of Maharashtra (1962) — the naval officer case. Defined the limits of 'grave and sudden provocation': the provocation must be sudden, and premeditated acts after cooling time fall outside it. Effectively ended jury trials in India.",
                "State of A.P. v. R. Punnayya (1976) — the classic exposition of the line between culpable homicide and murder: 'culpable homicide is the genus, murder its species'. The three-degree analysis is still the standard exam answer.",
                "Bachan Singh v. State of Punjab (1980) — upheld the constitutionality of the death penalty but confined it to the 'rarest of rare' cases where the alternative of life imprisonment is unquestionably foreclosed.",
                "Machhi Singh v. State of Punjab (1983) — operationalised 'rarest of rare' with five categories: manner, motive, magnitude, anti-social nature of the crime, and personality of the victim.",
                "Kedar Nath Singh v. State of Bihar (1962) — read down sedition: only acts with the tendency or intention to incite violence or public disorder are punishable. Central to understanding BNS 152's reworked language.",
                "Gian Kaur v. State of Punjab (1996) — held that the right to life does not include a right to die, overruling P. Rathinam; context for the modern treatment of attempted suicide and the Mental Healthcare Act, 2017.",
                "Study tip: pair each case with its BNS section in LexIndia — every relevant section page lists its landmark cases in the bottom drawer."
            ]
        )
    ]

    // MARK: Previous year papers (practice sets, demo)

    static let previousPapers: [LexDocument] = [
        LexDocument(
            id: "doc-pp-judiciary",
            kind: .previousPaper,
            title: "Judicial services — BNS practice paper I",
            summary: "A prelims-style practice set on the new penal code, with answer key. Demo paper.",
            meta: "3 pages · Practice set (demo)",
            actId: nil,
            body: [
                "Instructions: 10 questions, one mark each. Answers at the end. This is a LexIndia practice set in the prelims pattern — not an actual past paper.",
                "Q1. Under the Bharatiya Nyaya Sanhita, 2023, culpable homicide is defined in — (a) Section 100 (b) Section 101 (c) Section 103 (d) Section 105.",
                "Q2. The offence formerly cited as IPC 420 now corresponds to — (a) BNS 316 (b) BNS 318(4) (c) BNS 319 (d) BNS 303(2).",
                "Q3. Snatching is a distinct offence under — (a) BNS 302 (b) BNS 303 (c) BNS 304 (d) BNS 309.",
                "Q4. Community service as a punishment was introduced by — (a) the CrPC, 1973 (b) the BNSS, 2023 (c) the BNS, 2023 (d) the BSA, 2023.",
                "Q5. The right of private defence appears in the BNS at — (a) ss. 14–33 (b) ss. 34–44 (c) ss. 45–62 (d) ss. 96–106.",
                "Q6. Dowry death is punishable under — (a) BNS 79 (b) BNS 80 (c) BNS 85 (d) BNS 86.",
                "Q7. 'Organised crime' is dealt with in — (a) BNS 109 (b) BNS 111 (c) BNS 113 (d) BNS 152.",
                "Q8. The BNS chapter on offences against property begins with — (a) Section 300 (b) Section 303 (c) Section 305 (d) Section 310.",
                "Q9. Attempt to commit an offence (old IPC 511) is now — (a) BNS 60 (b) BNS 61 (c) BNS 62 (d) BNS 63.",
                "Q10. Defamation is punishable under — (a) BNS 351 (b) BNS 353 (c) BNS 356 (d) BNS 358.",
                "Answer key: 1(a) · 2(b) · 3(c) · 4(c) · 5(b) · 6(b) · 7(b) · 8(b) · 9(c) · 10(c)."
            ]
        ),
        LexDocument(
            id: "doc-pp-clat",
            kind: .previousPaper,
            title: "CLAT PG — criminal law practice set",
            summary: "Passage-based practice questions in the CLAT PG pattern. Demo paper.",
            meta: "2 pages · Practice set (demo)",
            actId: nil,
            body: [
                "Instructions: read the passage, then answer the questions. This is a LexIndia practice set in the CLAT PG pattern — not an actual past paper.",
                "Passage: The distinction between culpable homicide and murder has been called the most technical in Indian criminal law. Section 100 of the BNS defines culpable homicide; Section 101 states when culpable homicide amounts to murder, and its exceptions state when it does not — including grave and sudden provocation, private defence exceeded in good faith, and sudden fight.",
                "Q1. A, intending to kill B, poisons B's food. B dies. A's act is — (a) culpable homicide not amounting to murder (b) murder (c) death by negligence (d) no offence.",
                "Q2. In a sudden quarrel with no premeditation, A strikes B once with a stick; B dies of the injury. The most defensible classification is — (a) murder (b) culpable homicide not amounting to murder (c) hurt (d) grievous hurt.",
                "Q3. The 'genus and species' description of the homicide provisions comes from — (a) Bachan Singh (b) R. Punnayya (c) Nanavati (d) Machhi Singh.",
                "Q4. Under the BNS, the punishment for murder is found in — (a) Section 101 (b) Section 102 (c) Section 103 (d) Section 105.",
                "Answer key: 1(b) · 2(b) · 3(b) · 4(c)."
            ]
        )
    ]

    // MARK: Revision material

    static let revision: [LexDocument] = [
        LexDocument(
            id: "doc-rv-body",
            kind: .revision,
            title: "Quick revision — offences against the human body",
            summary: "Chapter VI (ss. 100–146) compressed into a final-read chart.",
            meta: "1 page · Updated Aug 2026",
            actId: nil,
            body: [
                "Homicide ladder: 100 culpable homicide (definition) → 101 murder (when CH amounts to murder + exceptions) → 103 punishment for murder → 105 punishment for CH not amounting to murder → 106 death by negligence.",
                "Exceptions to murder (s. 101): grave and sudden provocation · exceeding private defence in good faith · public servant exceeding duty · sudden fight without premeditation · consent of a person above 18.",
                "Hurt: 114 hurt (definition) → 115 voluntarily causing hurt → 116 grievous hurt (eight kinds — remember emasculation, permanent disfigurement, fracture, 15-day incapacity) → 117 voluntarily causing grievous hurt · acid attacks 124.",
                "Restraint and confinement: 126 wrongful restraint (blocking a path) vs 127 wrongful confinement (boundaries) — the classic one-mark distinction.",
                "Force and assault: 128 force → 129 criminal force → 130 assault (gesture creating apprehension; no contact needed).",
                "Kidnapping and abduction: 137 kidnapping (from India / from lawful guardianship — age-based, consent irrelevant) vs 138 abduction (force or deceit, any age; an act, not an offence by itself)."
            ]
        ),
        LexDocument(
            id: "doc-rv-property",
            kind: .revision,
            title: "Quick revision — offences against property",
            summary: "Chapter XVII (ss. 303–334) compressed into a final-read chart.",
            meta: "1 page · Updated Aug 2026",
            actId: nil,
            body: [
                "The theft family: 303 theft (dishonest taking of movable property without consent) → 304 snatching (sudden, quick, forcible seizure — NEW, no IPC ancestor) → 305 theft in a dwelling, transport or place of worship.",
                "Escalation: theft + force or fear = 309 robbery · robbery by five or more = 310 dacoity. Remember the counting rule: five persons commit or attempt.",
                "Extortion (308): consent obtained by putting a person in fear of injury — distinguish from robbery, where the taking is without consent.",
                "Trust and deception: 316 criminal breach of trust (property lawfully entrusted, then dishonestly misappropriated) vs 318 cheating (dishonest inducement from the start; 318(4) is the old 420 — property delivered).",
                "Mischief (324): destruction or damage causing wrongful loss — think intention or knowledge of causing loss, not gain.",
                "Criminal trespass (329): entry into property in another's possession with intent to commit an offence or to intimidate, insult or annoy — house-trespass and house-breaking build on it."
            ]
        ),
        LexDocument(
            id: "doc-rv-women",
            kind: .revision,
            title: "Quick revision — offences against women & children",
            summary: "Chapter V (ss. 63–99) compressed into a final-read chart.",
            meta: "1 page · Updated Aug 2026",
            actId: nil,
            body: [
                "Structure shift: the BNS moved women- and child-related offences to the front of the code (Chapter V) — a deliberate reordering from the IPC, where they were scattered.",
                "Sexual offences: 63 rape (definition, consent-centred) → 64 punishment → aggravated forms and gang rape follow · 74 assault or criminal force to woman with intent to outrage modesty · 75 sexual harassment · 77 voyeurism · 78 stalking.",
                "Marriage-linked: 80 dowry death (death within 7 years + soon-before cruelty for dowry → presumption) · 82 bigamy · 85–86 cruelty by husband or relatives (the old 498A).",
                "Children: 93 exposure and abandonment of a child under 12 · 95 hiring or employing a child to commit an offence · kidnapping-related protections cross-reference Chapter VI (s. 137).",
                "Exam anchor: dowry death (80) + cruelty (85) + the evidentiary presumption travel together — cite all three for full marks."
            ]
        )
    ]
}
