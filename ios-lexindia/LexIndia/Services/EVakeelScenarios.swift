//
//  EVakeelScenarios.swift
//  LexIndia
//
//  Curated everyday-situation answers for the mock E-Vakeel provider —
//  realistic, step-by-step guidance for the questions people actually ask
//  (deposits, online fraud, cheque bounce, FIRs, notices…). Each answer is
//  general legal information grounded in the bundled dataset where
//  provisions exist, and honest about when a real advocate is needed.
//  A production AI provider replaces this bank without any UI changes.
//

import Foundation

nonisolated struct EVakeelScenario {
    let id: String
    /// Lowercased trigger phrases. Hindi keywords are included so
    /// suggestions tapped in Hindi mode match the same scenario.
    let phrases: [String]
    let body: String
    /// Real dataset section ids shown as openable provisions.
    let sectionIds: [String]
    /// Forces the consult-an-advocate advisory on the reply.
    let serious: Bool
}

nonisolated enum EVakeelScenarioBank {

    /// Best-matching scenario for a question, or nil to fall back to
    /// dataset retrieval. The longest matched phrase wins, so specific
    /// phrases beat generic single keywords.
    static func match(_ question: String) -> EVakeelScenario? {
        let questionTokens = tokens(question)
        guard !questionTokens.isEmpty else { return nil }
        var best: (scenario: EVakeelScenario, score: Int)?
        for scenario in all {
            for phrase in scenario.phrases {
                let phraseTokens = tokens(phrase)
                guard containsPhrase(questionTokens, phrase: phraseTokens) else { continue }
                let score = phraseTokens.count * 100 + phrase.count
                if score > (best?.score ?? -1) {
                    best = (scenario, score)
                }
            }
        }
        return best?.scenario
    }

    /// Word-level tokens, so "fir" never matches inside "first".
    private static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    private static func containsPhrase(_ haystack: [String], phrase: [String]) -> Bool {
        guard !phrase.isEmpty, haystack.count >= phrase.count else { return false }
        for start in 0...(haystack.count - phrase.count) where Array(haystack[start..<(start + phrase.count)]) == phrase {
            return true
        }
        return false
    }

    // MARK: - Bank

    static let all: [EVakeelScenario] = [

        EVakeelScenario(
            id: "rent-deposit",
            phrases: ["security deposit", "deposit back", "return my deposit", "returning my deposit", "landlord", "rent agreement", "tenant", "evict", "eviction", "डिपॉज़िट", "मकान मालिक", "किरायेदार"],
            body: """
Rental disputes — including a landlord holding back the security deposit — are governed by your rent agreement and your state's rent laws. If the agreement says the deposit is refundable after you hand over the keys, the landlord must return it, minus only genuine, provable deductions (unpaid rent or real damage — not normal wear and tear).

What you can do next:
1. Ask for the refund in writing (message or email counts) with a clear date — a written trail matters most.
2. Keep rent receipts, moving-out photos and meter readings to counter inflated deductions.
3. If they still refuse, send a formal demand notice; many landlords settle at this stage.
4. As a last step, a civil suit for recovery (or your state's rent authority, where one exists) can order the refund, often with interest.

Unjustified retention of your money after the agreement ends is a breach of contract — the compensation rule is in Section 73 of the Indian Contract Act, linked below.
""",
            sectionIds: ["ic-73", "ic-10"],
            serious: false
        ),

        EVakeelScenario(
            id: "online-fraud",
            phrases: ["online fraud", "cyber fraud", "upi fraud", "scam", "scammed", "phishing", "otp fraud", "money online", "paid online", "online payment", "fake website", "fraud online", "hacked", "ऑनलाइन ठगी", "ठगी", "साइबर", "यूपीआई"],
            body: """
Online payment and shopping frauds are cybercrimes. Cheating by personation using a computer (fake seller profiles, phishing pages, OTP tricks) is punishable under Section 66D of the IT Act, identity theft under Section 66C, and cheating generally under Section 318 of the BNS.

Act fast — with money transfers, speed matters more than anything:
1. Call the national cyber helpline 1930 immediately, or report at cybercrime.gov.in. Early reporting lets banks freeze the money before it is withdrawn.
2. Inform your bank or UPI app the same day so the transaction is flagged and your account secured.
3. Preserve everything: screenshots, transaction IDs, the fraudster's number or UPI ID, chats and emails.
4. File an FIR at any police station — a Zero FIR can be registered anywhere, wherever the fraud "happened" online.

If a large amount is involved or the bank refuses to help, an advocate can escalate through the banking ombudsman or the consumer commission.
""",
            sectionIds: ["it-66d", "it-66c", "bns-318"],
            serious: false
        ),

        EVakeelScenario(
            id: "cheque-bounce",
            phrases: ["cheque", "check bounced", "dishonoured", "dishonored", "चेक"],
            body: """
A bounced cheque is a criminal offence under Section 138 of the Negotiable Instruments Act when the cheque was given for a debt or liability and fails for insufficient funds. The law is strict about timelines, so note your dates carefully.

The standard route:
1. Collect the bank's return memo stating why the cheque was dishonoured.
2. Send a written demand notice to the drawer within 30 days of the return memo.
3. The drawer then has 15 days to pay.
4. If they still don't pay, a complaint must be filed before the Magistrate within the next month.

Punishment can extend to two years' imprisonment or a fine up to twice the cheque amount, or both. If the cheque was part of a deception from the start, cheating under Section 318 of the BNS may also apply.

Because the deadlines are unforgiving and the notice wording matters, have an advocate draft and send the demand notice.
""",
            sectionIds: ["bns-318"],
            serious: true
        ),

        EVakeelScenario(
            id: "fir-police",
            phrases: ["file an fir", "file a fir", "fir", "police complaint", "police station refused", "police refused", "zero fir", "complaint to police", "एफआईआर", "पुलिस शिकायत"],
            body: """
An FIR (First Information Report) formally starts a criminal investigation for cognizable offences — cases where police can act without a court's permission, like theft, snatching or assault.

How it works under the BNSS:
1. Go to any police station — a Zero FIR can be registered anywhere, regardless of where the offence happened, and is transferred to the right station later.
2. Information can also be given electronically (e-FIR), but it must be signed within 3 days.
3. You are entitled to a free copy of the FIR immediately.
4. If the police refuse to register it, send your complaint in writing to the Superintendent of Police; if that also fails, a Magistrate can direct registration.

After the FIR, police investigate — statements, evidence, possibly arrests — and file either a chargesheet before the court or a closure report, which you can contest.

If you are the one named in an FIR, or the police call you for questioning, speak to an advocate before giving any statement.
""",
            sectionIds: [],
            serious: false
        ),

        EVakeelScenario(
            id: "consumer",
            phrases: ["consumer complaint", "consumer court", "defective", "refund", "replacement", "warranty", "wrong product", "not delivered", "seller refuses", "e commerce", "उपभोक्ता", "रिफंड", "खराब सामान"],
            body: """
Consumer disputes — defective products, services not delivered, refund refusals, unfair charges — are covered by the Consumer Protection Act, 2019. You do not need a lawyer to file a consumer complaint, and the fees are small.

What you can do next:
1. Complain to the seller or brand in writing first, with a clear deadline — keep the invoice and photos.
2. Escalate through the National Consumer Helpline 1915 or consumerhelpline.gov.in — many companies resolve cases at this stage.
3. File before the District Consumer Commission (online via the e-Daakhil portal). You can claim the amount, compensation and litigation costs.
4. For online purchases, the marketplace platform can often be made a party alongside the seller.

If the amount at stake is large or the other side brings lawyers, an advocate strengthens your case — but individuals argue consumer matters themselves every day.
""",
            sectionIds: ["ic-73"],
            serious: false
        ),

        EVakeelScenario(
            id: "salary",
            phrases: ["salary", "unpaid wages", "employer not paying", "notice period", "terminated", "fired", "full and final", "wrongful termination", "सैलरी", "वेतन", "नौकरी से निकाल"],
            body: """
Unpaid salary and wrongful termination are contract and labour-law matters. Your appointment letter sets the pay, notice period and full-and-final terms — breaching it entitles you to compensation under Section 73 of the Indian Contract Act. Consent obtained under pressure is not free consent (Section 14).

What you can do next:
1. Raise the dues in writing with HR or the employer and ask for a settlement date; keep payslips, the contract and every reply.
2. Send a formal demand notice for the exact amount due.
3. For "workman"-category roles, the Labour Commissioner offers free conciliation that is often effective.
4. Otherwise, a civil suit for recovery — or the labour court or industrial tribunal, depending on your role — is the formal route.

If significant money is stuck, or you are being made to sign papers under pressure, take an advocate's help before signing anything further.
""",
            sectionIds: ["ic-73", "ic-14"],
            serious: false
        ),

        EVakeelScenario(
            id: "traffic",
            phrases: ["challan", "traffic police", "traffic fine", "vehicle seized", "licence suspended", "license suspended", "drunk driving", "accident", "hit my car", "hit and run", "चालान", "दुर्घटना"],
            body: """
Traffic and vehicle matters are governed by the Motor Vehicles Act. The two common situations:

Challans — check pending e-challans on the official Parivahan or state portal. You can pay online, or contest a wrong challan before the traffic or virtual court named on it. Carry your licence, RC and insurance.

Accidents —
1. Don't leave the spot; call 112 if anyone is hurt. Helping an injured person is legally protected, while hit-and-run is punished far more severely.
2. Photograph the vehicles and positions, exchange insurance details, and report to the police and your insurer within the policy's time limit.
3. For injury or major damage, the Motor Accident Claims Tribunal (MACT) awards compensation, paid by the insurer of the vehicle at fault.

Rash or negligent driving causing hurt is also an offence under the BNS. For anything involving injury, arrest or a seized vehicle, consult an advocate promptly.
""",
            sectionIds: [],
            serious: false
        ),

        EVakeelScenario(
            id: "legal-notice",
            phrases: ["legal notice", "notice from a lawyer", "notice from lawyer", "received a notice", "reply to a notice", "reply to the notice", "court notice", "summons", "कानूनी नोटिस", "नोटिस"],
            body: """
A legal notice is a formal warning that the sender may go to court — it is not a court order, and receiving one does not make you guilty of anything. The one real mistake is ignoring it: silence lets the other side tell the court you never responded.

What you can do next:
1. Read it fully — who sent it, under which law, what exactly is demanded, and the deadline (usually 15–30 days).
2. Gather every paper connected to the matter: agreements, receipts, chats, emails.
3. Don't call to argue and don't admit anything in writing — statements can be used later.
4. Reply within the deadline through an advocate; a well-drafted reply often ends the matter or opens settlement.
5. If what you received is a court summons rather than a notice, appearing on the date is mandatory.

Because the reply's wording can decide a future case, this is one document genuinely worth an advocate's time.
""",
            sectionIds: [],
            serious: true
        ),

        EVakeelScenario(
            id: "family",
            phrases: ["divorce", "maintenance", "alimony", "custody", "dowry", "498a", "domestic violence", "husband", "wife", "तलाक", "गुज़ारा भत्ता", "दहेज", "घरेलू हिंसा"],
            body: """
Family matters — divorce, maintenance, custody, domestic violence, dowry — are decided by personal laws (such as the Hindu Marriage Act or Special Marriage Act) together with protective criminal provisions.

The general landscape:
1. Divorce is either by mutual consent (fastest, when both sides agree on terms) or contested on grounds like cruelty or desertion.
2. A spouse who cannot maintain themselves can claim monthly maintenance; custody is decided on the child's welfare, not the parents' wishes.
3. Cruelty by a husband or his relatives is a criminal offence — Section 85 of the BNS, the successor to IPC 498A; dowry death is Section 80.
4. For immediate protection, the Protection of Women from Domestic Violence Act gives fast protection and residence orders. In danger, call 112 or the women's helpline 181.

These cases turn entirely on personal facts and documents, so please consult a family-law advocate before filing or responding to anything — E-Vakeel can only explain the law in general.
""",
            sectionIds: ["bns-85", "bns-80"],
            serious: true
        ),

        EVakeelScenario(
            id: "threats",
            phrases: ["threatening", "threatened me", "threatening me", "blackmail", "blackmailing", "extortion", "recovery agent", "recovery agents", "loan recovery", "धमकी", "ब्लैकमेल", "वसूली"],
            body: """
Threats and blackmail are crimes — even when the person claims you owe them money. Criminal intimidation (threatening harm to your body, reputation or property to force you to act) is Section 351 of the BNS; extracting money or valuables through fear is extortion under Section 308.

What you can do next:
1. Stop engaging. Don't pay "to make it go away" — it rarely stops there.
2. Preserve proof: recordings, call logs, chats and numbers. Delete nothing.
3. File a police complaint or FIR — these are cognizable offences. For online blackmail, also report at cybercrime.gov.in or call 1930.
4. Recovery agents have no power to threaten you, enter your home or seize belongings — RBI rules bind the banks they work for; complain to the bank and the RBI ombudsman.

If any threat mentions immediate violence, call 112 now. Given the personal risk, have an advocate guide the complaint.
""",
            sectionIds: ["bns-351", "bns-308"],
            serious: true
        )
    ]
}
