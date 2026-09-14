//
//  LegalPagesView.swift
//  LexIndia
//
//  Privacy, terms and the legal disclaimer — fully bilingual.
//

import SwiftUI

struct LegalPageView: View {
    @Environment(UserDataStore.self) private var store

    let kind: LegalPageKind

    private var title: String {
        switch kind {
        case .privacy: return LexStrings.t("account.privacy", store.language)
        case .terms: return LexStrings.t("account.terms", store.language)
        case .disclaimer: return LexStrings.t("account.disclaimer", store.language)
        }
    }

    private var paragraphs: [String] {
        store.language == .hindi ? hindiParagraphs : englishParagraphs
    }

    private var englishParagraphs: [String] {
        switch kind {
        case .privacy:
            return [
                "LexIndia stores your data on your device. Your notes, saved sections, reading history, search history and E-Vakeel conversations never leave your phone in this version.",
                "No account is required, no analytics identifiers are collected, and no personal information is transmitted to any server.",
                "Deleting the app deletes your locally stored data."
            ]
        case .terms:
            return [
                "LexIndia is an informational legal reference for Indian law. By using the app you agree that it is provided for general information and education.",
                "The app presents statutory text, plain-language explanations, examples and case-law summaries. While care is taken to keep content faithful to official sources, the official Gazette of India and certified court records remain the authoritative versions.",
                "Subscriptions and credit purchases in this version are demonstrations; no payment is collected.",
                "Do not rely on LexIndia as a substitute for professional advice about a specific matter."
            ]
        case .disclaimer:
            return [
                "LexIndia is not a lawyer, a law firm, or a source of legal representation, and it does not provide personalised legal advice.",
                "Plain-language explanations, examples and key points are editorial aids to understanding. They simplify — and simplification always loses nuance. The official statutory text prevails over any explanation.",
                "Situations and topics help you discover relevant legal information; they do not assess your case.",
                "If you face a real legal issue, consult a qualified advocate. If you are in immediate danger, contact the police on 112."
            ]
        }
    }

    private var hindiParagraphs: [String] {
        switch kind {
        case .privacy:
            return [
                "LexIndia आपका डेटा आपके डिवाइस पर रखता है। आपके नोट्स, सेव किए सेक्शन, रीडिंग हिस्ट्री, खोज इतिहास और ई-वकील बातचीत इस संस्करण में कभी आपके फोन से बाहर नहीं जाते।",
                "कोई खाता आवश्यक नहीं, कोई एनालिटिक्स पहचानकर्ता एकत्र नहीं होते, और कोई व्यक्तिगत जानकारी किसी सर्वर को नहीं भेजी जाती।",
                "ऐप हटाने पर आपका स्थानीय डेटा भी हट जाता है।"
            ]
        case .terms:
            return [
                "LexIndia भारतीय कानून का सूचनापरक संदर्भ है। ऐप का उपयोग कर आप सहमत हैं कि यह सामान्य जानकारी और शिक्षा के लिए है।",
                "ऐप कानूनी पाठ, सरल-भाषा व्याख्याएँ, उदाहरण और केस-सारांश प्रस्तुत करता है। सामग्री को आधिकारिक स्रोतों के प्रति निष्ठावान रखने की सावधानी बरती जाती है, फिर भी भारत का राजपत्र और प्रमाणित न्यायालय अभिलेख ही प्रामाणिक संस्करण हैं।",
                "इस संस्करण में सदस्यता और क्रेडिट खरीद प्रदर्शन मात्र हैं; कोई भुगतान नहीं लिया जाता।",
                "किसी विशिष्ट मामले में पेशेवर सलाह के विकल्प के रूप में LexIndia पर निर्भर न रहें।"
            ]
        case .disclaimer:
            return [
                "LexIndia कोई वकील, लॉ फर्म या कानूनी प्रतिनिधित्व का स्रोत नहीं है, और यह व्यक्तिगत कानूनी सलाह नहीं देता।",
                "सरल-भाषा व्याख्याएँ, उदाहरण और मुख्य बिंदु समझ में मदद के संपादकीय साधन हैं। सरलीकरण में बारीकियाँ छूटती हैं। किसी भी व्याख्या पर आधिकारिक कानूनी पाठ ही मान्य है।",
                "स्थितियाँ और विषय आपको प्रासंगिक कानूनी जानकारी खोजने में मदद करते हैं; वे आपके मामले का आकलन नहीं करते।",
                "वास्तविक कानूनी समस्या हो तो योग्य वकील से परामर्श करें। तत्काल खतरे में हों तो 112 पर पुलिस से संपर्क करें।"
            ]
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(LexFont.display(28, .bold))
                    .foregroundStyle(LexColor.ink)
                    .padding(.top, 8)

                BenchDivider()
                    .padding(.vertical, 18)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(LexFont.sans(15))
                            .foregroundStyle(LexColor.ink)
                            .lineSpacing(6)
                    }
                }

                TrustFootnote()
                    .padding(.top, 30)
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
