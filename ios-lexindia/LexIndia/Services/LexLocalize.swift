//
//  LexLocalize.swift
//  LexIndia
//
//  Hindi display layer for DATA-DRIVEN content: Act names, categories,
//  situations, topics, documents, updates and BNS chapter headings.
//  Statutory body text is NEVER translated — Act and chapter names use
//  the official Hindi titles as enacted (the 2023 codes are bilingual).
//  UI chrome strings live in LexStrings; this file covers content names.
//

import Foundation

nonisolated enum LexLocalize {
    // MARK: - Acts (official Hindi titles)

    private static let actNames: [String: String] = [
        "bns": "भारतीय न्याय संहिता, 2023",
        "bnss": "भारतीय नागरिक सुरक्षा संहिता, 2023",
        "bsa": "भारतीय साक्ष्य अधिनियम, 2023",
        "constitution": "भारत का संविधान",
        "contract-act": "भारतीय संविदा अधिनियम, 1872",
        "cpa-2019": "उपभोक्ता संरक्षण अधिनियम, 2019",
        "tpa-1882": "संपत्ति अंतरण अधिनियम, 1882",
        "hma-1955": "हिन्दू विवाह अधिनियम, 1955",
        "ida-1947": "औद्योगिक विवाद अधिनियम, 1947",
        "ita-1961": "आय-कर अधिनियम, 1961",
        "it-act-2000": "सूचना प्रौद्योगिकी अधिनियम, 2000",
        "copyright-1957": "कॉपीराइट अधिनियम, 1957"
    ]

    private static let actSummaries: [String: String] = [
        "bns": "भारत की प्रमुख आपराधिक संहिता, जिसने भारतीय दंड संहिता, 1860 की जगह ली। यह चोरी और छल से लेकर हत्या तक अपराधों को परिभाषित करती है और उनके दंड निर्धारित करती है।",
        "bnss": "आपराधिक प्रक्रिया की संहिता — अपराध कैसे दर्ज, जाँचे, विचारित और अपीलित होते हैं। दंड प्रक्रिया संहिता, 1973 की जगह।",
        "bsa": "साक्ष्य का कानून — अदालत में क्या, कैसे और किसके द्वारा साबित किया जा सकता है। भारतीय साक्ष्य अधिनियम, 1872 की जगह।",
        "constitution": "भारत का सर्वोच्च कानून: मौलिक अधिकार और कर्तव्य, नीति-निदेशक तत्व, और संघ व राज्यों का ढांचा।",
        "contract-act": "समझौते कब संविदा बनते हैं, सहमति कब स्वतंत्र होती है, और भंग होने पर क्या प्रतिकर मिलता है।",
        "cpa-2019": "उपभोक्ता अधिकार, अनुचित व्यापार प्रथाएँ, उत्पाद दायित्व और उपभोक्ता आयोग प्रणाली।",
        "tpa-1882": "जीवित व्यक्तियों के बीच संपत्ति का विक्रय, बंधक, पट्टा, विनिमय और दान।",
        "hma-1955": "वैध विवाह की शर्तें, दांपत्य अधिकारों की पुनर्स्थापना, न्यायिक पृथक्करण और विवाह-विच्छेद।",
        "ida-1947": "औद्योगिक विवादों, छँटनी और कामबंदी की जाँच और निपटारे की व्यवस्था।",
        "ita-1961": "आयकर का प्रभार, संगणना, निर्धारण और संग्रहण।",
        "it-act-2000": "इलेक्ट्रॉनिक रिकॉर्ड और हस्ताक्षर, मध्यवर्ती, और अधिकांश ऑनलाइन-धोखाधड़ी के पीछे के साइबर अपराध।",
        "copyright-1957": "साहित्यिक, नाट्य, संगीत और कलात्मक कृतियों, फिल्मों और रिकॉर्डिंग पर रचनाकारों के अधिकार।"
    ]

    private static let actExtents: [String: String] = [
        "bns": "358 धाराएँ · 20 अध्याय",
        "bnss": "531 धाराएँ",
        "bsa": "170 धाराएँ",
        "constitution": "यथा-अधिनियमित 395 अनुच्छेद · 22 भाग",
        "contract-act": "238 धाराएँ",
        "cpa-2019": "107 धाराएँ",
        "tpa-1882": "137 धाराएँ",
        "hma-1955": "30 धाराएँ",
        "ida-1947": "40 धाराएँ",
        "ita-1961": "298 धाराएँ",
        "it-act-2000": "94 धाराएँ · 13 अध्याय",
        "copyright-1957": "79 धाराएँ"
    ]

    private static let actEffectives: [String: String] = [
        "bns": "1 जुलाई 2024 से लागू",
        "bnss": "1 जुलाई 2024 से लागू",
        "bsa": "1 जुलाई 2024 से लागू",
        "constitution": "26 जनवरी 1950 से लागू",
        "contract-act": "1 सितंबर 1872 से लागू",
        "cpa-2019": "20 जुलाई 2020 से लागू",
        "tpa-1882": "1 जुलाई 1882 से लागू",
        "hma-1955": "18 मई 1955 से लागू",
        "ida-1947": "1 अप्रैल 1947 से लागू",
        "ita-1961": "1 अप्रैल 1962 से लागू",
        "it-act-2000": "17 अक्टूबर 2000 से लागू",
        "copyright-1957": "21 जनवरी 1958 से लागू"
    ]

    private static let actSources: [String: String] = [
        "bns": "2023 का अधिनियम सं. 45",
        "bnss": "2023 का अधिनियम सं. 46",
        "bsa": "2023 का अधिनियम सं. 47",
        "constitution": "26 नवंबर 1949 को अंगीकृत",
        "contract-act": "1872 का अधिनियम सं. 9",
        "cpa-2019": "2019 का अधिनियम सं. 35",
        "tpa-1882": "1882 का अधिनियम सं. 4",
        "hma-1955": "1955 का अधिनियम सं. 25",
        "ida-1947": "1947 का अधिनियम सं. 14",
        "ita-1961": "1961 का अधिनियम सं. 43",
        "it-act-2000": "2000 का अधिनियम सं. 21",
        "copyright-1957": "1957 का अधिनियम सं. 14"
    ]

    static func actName(_ act: LegalAct, _ language: AppLanguage) -> String {
        language == .hindi ? (actNames[act.id] ?? act.name) : act.name
    }

    static func actName(id: String, fallback: String, _ language: AppLanguage) -> String {
        language == .hindi ? (actNames[id] ?? fallback) : fallback
    }

    static func actSummary(_ act: LegalAct, _ language: AppLanguage) -> String {
        language == .hindi ? (actSummaries[act.id] ?? act.summary) : act.summary
    }

    static func actExtent(_ act: LegalAct, _ language: AppLanguage) -> String {
        language == .hindi ? (actExtents[act.id] ?? act.extentLabel) : act.extentLabel
    }

    static func actEffective(_ act: LegalAct, _ language: AppLanguage) -> String {
        language == .hindi ? (actEffectives[act.id] ?? act.effectiveLabel) : act.effectiveLabel
    }

    static func actSource(_ act: LegalAct, _ language: AppLanguage) -> String {
        language == .hindi ? (actSources[act.id] ?? act.sourceLabel) : act.sourceLabel
    }

    // MARK: - BNS chapters (official Hindi headings)

    private static let bnsChapters: [String: String] = [
        "I": "प्रारंभिक",
        "II": "दण्डों के विषय में",
        "III": "साधारण अपवाद",
        "IV": "दुष्प्रेरण, आपराधिक षड्यंत्र और प्रयत्न के विषय में",
        "V": "स्त्री और बालक के विरुद्ध अपराधों के विषय में",
        "VI": "मानव शरीर पर प्रभाव डालने वाले अपराधों के विषय में",
        "VII": "राज्य के विरुद्ध अपराधों के विषय में",
        "VIII": "सेना, नौसेना और वायुसेना से संबंधित अपराधों के विषय में",
        "IX": "निर्वाचनों से संबंधित अपराधों के विषय में",
        "X": "सिक्कों, करेंसी नोटों, बैंक नोटों और सरकारी स्टाम्पों से संबंधित अपराधों के विषय में",
        "XI": "लोक प्रशांति के विरुद्ध अपराधों के विषय में",
        "XII": "लोक सेवकों द्वारा या उनसे संबंधित अपराधों के विषय में",
        "XIII": "लोक सेवकों के विधिपूर्ण प्राधिकार के अवमान के विषय में",
        "XIV": "मिथ्या साक्ष्य और लोक न्याय के विरुद्ध अपराधों के विषय में",
        "XV": "लोक स्वास्थ्य, क्षेम, सुविधा, शिष्टता और सदाचार पर प्रभाव डालने वाले अपराधों के विषय में",
        "XVI": "धर्म से संबंधित अपराधों के विषय में",
        "XVII": "संपत्ति के विरुद्ध अपराधों के विषय में",
        "XVIII": "दस्तावेजों और संपत्ति चिह्नों से संबंधित अपराधों के विषय में",
        "XIX": "आपराधिक अभित्रास, अपमान और क्षोभ के विषय में",
        "XX": "निरसन और व्यावृत्ति"
    ]

    /// Chapter heading, using the official Hindi title for BNS chapters.
    static func chapterTitle(numeral: String, fallback: String, actId: String, _ language: AppLanguage) -> String {
        guard language == .hindi, actId == "bns", let hindi = bnsChapters[numeral] else { return fallback }
        return hindi
    }

    /// "Chapter XVII · Of Offences Against Property" / "अध्याय XVII · संपत्ति के विरुद्ध…"
    static func chapterLine(numeral: String, title: String, actId: String, _ language: AppLanguage) -> String {
        let word = LexStrings.t("reader.chapter", language)
        return "\(word) \(numeral) · \(chapterTitle(numeral: numeral, fallback: title, actId: actId, language))"
    }

    // MARK: - Categories

    private static let categoryNames: [String: String] = [
        "criminal": "आपराधिक कानून",
        "constitutional": "संवैधानिक कानून",
        "civil": "सिविल और वाणिज्यिक",
        "property": "संपत्ति",
        "family": "परिवार और व्यक्तिगत",
        "labour": "श्रम",
        "taxation": "कराधान",
        "ip-tech": "IP और प्रौद्योगिकी"
    ]

    private static let categoryTaglines: [String: String] = [
        "criminal": "अपराध, प्रक्रिया और साक्ष्य",
        "constitutional": "गणराज्य का ढांचा",
        "civil": "संविदा, उपभोक्ता और व्यापार",
        "property": "स्वामित्व, अंतरण और किरायेदारी",
        "family": "विवाह, अलगाव और संरक्षण",
        "labour": "काम, वेतन और औद्योगिक विवाद",
        "taxation": "आयकर और शुल्क",
        "ip-tech": "डिजिटल कानून और बौद्धिक संपदा"
    ]

    private static let categoryExtents: [String: String] = [
        "criminal": "3 संहिताएँ · 1,059 धाराएँ",
        "constitutional": "संविधान · 395 अनुच्छेद",
        "civil": "2 अधिनियम · 345 धाराएँ",
        "property": "1 अधिनियम · 137 धाराएँ",
        "family": "1 अधिनियम · 30 धाराएँ",
        "labour": "1 अधिनियम · 40 धाराएँ",
        "taxation": "1 अधिनियम · 298 धाराएँ",
        "ip-tech": "2 अधिनियम · 173 धाराएँ"
    ]

    static func categoryName(_ category: LegalCategory, _ language: AppLanguage) -> String {
        language == .hindi ? (categoryNames[category.id] ?? category.name) : category.name
    }

    static func categoryTagline(_ category: LegalCategory, _ language: AppLanguage) -> String {
        language == .hindi ? (categoryTaglines[category.id] ?? category.tagline) : category.tagline
    }

    static func categoryExtent(_ category: LegalCategory, _ language: AppLanguage) -> String {
        language == .hindi ? (categoryExtents[category.id] ?? category.extentLabel) : category.extentLabel
    }

    // MARK: - Situations

    private static let situationTitles: [String: String] = [
        "sit-road": "सड़क दुर्घटना",
        "sit-money": "पैसों का विवाद",
        "sit-cyber": "ऑनलाइन और साइबर मामला",
        "sit-property": "संपत्ति की समस्या",
        "sit-family": "पारिवारिक मामला",
        "sit-work": "कार्यस्थल का मामला"
    ]

    private static let situationBlurbs: [String: String] = [
        "sit-road": "चोट, लापरवाह ड्राइविंग और पुलिस प्रक्रिया",
        "sit-money": "न लौटाए गए कर्ज़, टूटे वादे और सीधी धोखाधड़ी",
        "sit-cyber": "UPI धोखाधड़ी, पहचान की चोरी और ऑनलाइन प्रतिरूपण",
        "sit-property": "अतिचार, नुकसान, कब्ज़ा और धमकी",
        "sit-family": "क्रूरता, दहेज और विवाह में संरक्षण",
        "sit-work": "उत्पीड़न, धमकियाँ और बकाया वेतन"
    ]

    static func situationTitle(_ situation: Situation, _ language: AppLanguage) -> String {
        language == .hindi ? (situationTitles[situation.id] ?? situation.title) : situation.title
    }

    static func situationBlurb(_ situation: Situation, _ language: AppLanguage) -> String {
        language == .hindi ? (situationBlurbs[situation.id] ?? situation.blurb) : situation.blurb
    }

    // MARK: - Topics

    private static let topicNames: [String: String] = [
        "t-cheating": "धोखाधड़ी और छल",
        "t-theft": "चोरी और लूट",
        "t-defamation": "मानहानि",
        "t-hurt": "चोट और हमला",
        "t-marriage": "विवाह और क्रूरता",
        "t-cyber": "साइबर अपराध",
        "t-contracts": "संविदाएँ",
        "t-homicide": "मानव वध",
        "t-defence": "निजी प्रतिरक्षा",
        "t-new-crimes": "BNS में नया",
        "t-public-order": "लोक व्यवस्था",
        "t-kidnapping": "अपहरण"
    ]

    static func topicName(_ topic: LegalTopic, _ language: AppLanguage) -> String {
        language == .hindi ? (topicNames[topic.id] ?? topic.name) : topic.name
    }

    // MARK: - Documents

    private static let docTitles: [String: String] = [
        "doc-ba-bns": "भारतीय न्याय संहिता, 2023",
        "doc-ba-bnss": "भारतीय नागरिक सुरक्षा संहिता, 2023",
        "doc-ba-bsa": "भारतीय साक्ष्य अधिनियम, 2023",
        "doc-cf-vakalatnama": "वकालतनामा",
        "doc-cf-bail": "जमानत आवेदन (BNSS)",
        "doc-cf-affidavit": "सामान्य शपथपत्र",
        "doc-cf-rti": "RTI आवेदन",
        "doc-cf-legal-notice": "कानूनी नोटिस",
        "doc-en-bns-map": "BNS एक नज़र में — सभी 20 अध्याय",
        "doc-en-ipc-bns": "IPC → BNS त्वरित चार्ट",
        "doc-en-maxims": "कानूनी सूक्तियाँ — आवश्यक सेट",
        "doc-en-cases": "प्रमुख निर्णयों का सार",
        "doc-pp-judiciary": "न्यायिक सेवा — BNS अभ्यास पेपर I",
        "doc-pp-clat": "CLAT PG — आपराधिक कानून अभ्यास सेट",
        "doc-rv-body": "त्वरित रिवीज़न — मानव शरीर के विरुद्ध अपराध",
        "doc-rv-property": "त्वरित रिवीज़न — संपत्ति के विरुद्ध अपराध",
        "doc-rv-women": "त्वरित रिवीज़न — महिलाओं और बच्चों के विरुद्ध अपराध"
    ]

    private static let docSummaries: [String: String] = [
        "doc-ba-bns": "भारत की दंड संहिता — सभी 358 धाराएँ, LexIndia गाइड, IPC संदर्भ और प्रमुख निर्णयों के साथ।",
        "doc-ba-bnss": "CrPC की जगह लेने वाली प्रक्रिया संहिता — गिरफ्तारी, जमानत, जाँच और विचारण।",
        "doc-ba-bsa": "साक्ष्य अधिनियम की जगह लेने वाली साक्ष्य संहिता — प्रमाण, गवाह और इलेक्ट्रॉनिक रिकॉर्ड।",
        "doc-cf-vakalatnama": "मुवक्किल की ओर से पेश होने और कार्य करने हेतु अधिवक्ता नियुक्त करने का मानक फॉर्म।",
        "doc-cf-bail": "भारतीय नागरिक सुरक्षा संहिता, 2023 के अंतर्गत नियमित जमानत का मूल आवेदन ढांचा।",
        "doc-cf-affidavit": "अदालती और प्रशासनिक फाइलिंग के लिए सामान्य-उद्देश्य शपथपत्र प्रारूप।",
        "doc-cf-rti": "सूचना का अधिकार अधिनियम, 2005 की धारा 6(1) के अंतर्गत सूचना माँगने का आवेदन।",
        "doc-cf-legal-notice": "कार्यवाही शुरू करने से पहले भेजे जाने वाले कानूनी नोटिस की मानक संरचना।",
        "doc-en-bns-map": "भारतीय न्याय संहिता का एक-पृष्ठ नक्शा: हर अध्याय अपनी धारा-सीमा के साथ।",
        "doc-en-ipc-bns": "पुनर्संख्यांकन के वे जोड़े जो हर छात्र और वकील को कंठस्थ होने चाहिए।",
        "doc-en-maxims": "न्यायपालिका और CLAT पेपरों में पूछी जाने वाली लैटिन सूक्तियाँ, सरल अर्थ सहित।",
        "doc-en-cases": "हर पेपर में अपेक्षित आपराधिक-कानून के केस, हरेक तीन पंक्तियों में।",
        "doc-pp-judiciary": "नई दंड संहिता पर प्रीलिम्स-शैली का अभ्यास सेट, उत्तर कुंजी सहित। डेमो पेपर।",
        "doc-pp-clat": "CLAT PG पैटर्न में गद्यांश-आधारित अभ्यास प्रश्न। डेमो पेपर।",
        "doc-rv-body": "अध्याय VI (धारा 100–146) अंतिम दोहराव चार्ट में संक्षिप्त।",
        "doc-rv-property": "अध्याय XVII (धारा 303–334) अंतिम दोहराव चार्ट में संक्षिप्त।",
        "doc-rv-women": "अध्याय V (धारा 63–99) अंतिम दोहराव चार्ट में संक्षिप्त।"
    ]

    private static let docMetas: [String: String] = [
        "doc-ba-bns": "358 धाराएँ · 1 जुलाई 2024 से लागू",
        "doc-ba-bnss": "531 धाराएँ · LexIndia के लिए तैयार हो रहा है",
        "doc-ba-bsa": "170 धाराएँ · LexIndia के लिए तैयार हो रहा है",
        "doc-cf-vakalatnama": "1 पृष्ठ · संदर्भ प्रारूप",
        "doc-cf-bail": "2 पृष्ठ · संदर्भ प्रारूप",
        "doc-cf-affidavit": "1 पृष्ठ · संदर्भ प्रारूप",
        "doc-cf-rti": "1 पृष्ठ · संदर्भ प्रारूप",
        "doc-cf-legal-notice": "1 पृष्ठ · संदर्भ प्रारूप",
        "doc-en-bns-map": "2 पृष्ठ · अगस्त 2026 में अपडेट",
        "doc-en-ipc-bns": "2 पृष्ठ · अगस्त 2026 में अपडेट",
        "doc-en-maxims": "2 पृष्ठ · जुलाई 2026 में अपडेट",
        "doc-en-cases": "2 पृष्ठ · जुलाई 2026 में अपडेट",
        "doc-pp-judiciary": "3 पृष्ठ · अभ्यास सेट (डेमो)",
        "doc-pp-clat": "2 पृष्ठ · अभ्यास सेट (डेमो)",
        "doc-rv-body": "1 पृष्ठ · अगस्त 2026 में अपडेट",
        "doc-rv-property": "1 पृष्ठ · अगस्त 2026 में अपडेट",
        "doc-rv-women": "1 पृष्ठ · अगस्त 2026 में अपडेट"
    ]

    static func docTitle(_ document: LexDocument, _ language: AppLanguage) -> String {
        language == .hindi ? (docTitles[document.id] ?? document.title) : document.title
    }

    static func docSummary(_ document: LexDocument, _ language: AppLanguage) -> String {
        language == .hindi ? (docSummaries[document.id] ?? document.summary) : document.summary
    }

    static func docMeta(_ document: LexDocument, _ language: AppLanguage) -> String {
        language == .hindi ? (docMetas[document.id] ?? document.meta) : document.meta
    }

    // MARK: - Legal Updates

    private static let updateTitles: [String: String] = [
        "u-2026-bail-timelines": "पहले जमानत, बाद में जेल: नई प्रक्रिया संहिता की समय-सीमाएँ फिर रेखांकित",
        "u-2026-digital-arrest": "'डिजिटल अरेस्ट' ठगी सीधी धोखाधड़ी और प्रतिरूपण है, अदालतों ने पुष्टि की",
        "u-2026-organised-crime": "'छोटा संगठित अपराध' क्या है? हाईकोर्ट सीमाएँ स्पष्ट कर रहे हैं",
        "u-2026-codes-anniversary": "2023 की संहिताओं के दो वर्ष: क्या स्थिर हुआ, क्या अब भी खुला है",
        "u-2026-cyber-amendment": "ऑनलाइन धोखे की परिभाषाएँ और स्पष्ट करने वाला मसौदा संशोधन",
        "u-2026-efiling": "ई-फाइलिंग का विस्तार: और ज़िलों में मानक कोर्ट फॉर्म डिजिटल स्वीकार",
        "u-2026-snatching": "झपटमारी अब स्वतंत्र अपराध: नए समर्पित प्रावधान का व्यवहार में उपयोग",
        "u-2026-community-service": "सज़ा में सामुदायिक सेवा की शुरुआत: शुरुआती रुझान"
    ]

    private static let updateSnippets: [String: String] = [
        "u-2026-bail-timelines": "ट्रायल कोर्ट को याद दिलाया गया कि जमानत आवेदन 2023 की प्रक्रिया संहिता की समय-सीमाओं के भीतर तय हों।",
        "u-2026-digital-arrest": "वीडियो-कॉल धमकी वाले घोटालों पर BNS के तहत छल, प्रतिरूपण द्वारा छल और उद्दापन के आरोप लग रहे हैं।",
        "u-2026-organised-crime": "BNS के संगठित-अपराध प्रावधानों के लिए समूह, पैटर्न और आम जन में भय ज़रूरी माना जा रहा है।",
        "u-2026-codes-anniversary": "BNS, BNSS और BSA को लागू हुए दो वर्ष पूरे। ट्रांज़िशन के सवाल अब कुछ ही विषयों तक सिमट रहे हैं।",
        "u-2026-cyber-amendment": "परामर्श मसौदे में सिंथेटिक मीडिया से प्रतिरूपण को छल के ढांचे में स्पष्ट भाषा देने का प्रस्ताव है।",
        "u-2026-efiling": "अब और ज़िला अदालतें वकालतनामा, जमानत आवेदन और शपथपत्र ई-फाइलिंग पोर्टल से स्वीकार कर रही हैं।",
        "u-2026-snatching": "चेन- और फोन-झपटमारी के मामले अब साधारण चोरी नहीं, BNS के समर्पित झपटमारी प्रावधान में दर्ज हो रहे हैं।",
        "u-2026-community-service": "BNS ने कुछ छोटे अपराधों के लिए सामुदायिक सेवा को औपचारिक दण्ड बनाया। अदालतें इसका उपयोग करने लगी हैं।"
    ]

    private static let updateDates: [String: String] = [
        "u-2026-bail-timelines": "14 अगस्त 2026",
        "u-2026-digital-arrest": "11 अगस्त 2026",
        "u-2026-organised-crime": "6 अगस्त 2026",
        "u-2026-codes-anniversary": "1 जुलाई 2026",
        "u-2026-cyber-amendment": "22 जुलाई 2026",
        "u-2026-efiling": "18 जुलाई 2026",
        "u-2026-snatching": "9 जुलाई 2026",
        "u-2026-community-service": "28 जून 2026"
    ]

    static func updateTitle(_ update: LegalUpdate, _ language: AppLanguage) -> String {
        language == .hindi ? (updateTitles[update.id] ?? update.title) : update.title
    }

    static func updateSnippet(_ update: LegalUpdate, _ language: AppLanguage) -> String {
        language == .hindi ? (updateSnippets[update.id] ?? update.snippet) : update.snippet
    }

    static func updateDate(_ update: LegalUpdate, _ language: AppLanguage) -> String {
        language == .hindi ? (updateDates[update.id] ?? update.dateLabel) : update.dateLabel
    }

    static func updateSource(_ update: LegalUpdate, _ language: AppLanguage) -> String {
        language == .hindi ? "LexIndia डेस्क · डेमो सारांश" : update.source
    }

    // MARK: - E-Vakeel suggestions

    private static let suggestionsHindi: [String] = [
        "मकान मालिक मेरी सिक्योरिटी डिपॉज़िट नहीं लौटा रहा — क्या करूँ?",
        "मैंने ऑनलाइन पैसे दिए और विक्रेता गायब हो गया। ठगी की रिपोर्ट कैसे करूँ?",
        "मुझे मिला चेक बाउंस हो गया। मेरे पास क्या विकल्प हैं?",
        "एफआईआर कैसे दर्ज करें, और उसके बाद क्या होता है?",
        "मुझे कानूनी नोटिस मिला है। अब क्या करूँ?",
        "मेरे नियोक्ता ने दो महीने से सैलरी नहीं दी।",
        "कोई पैसों को लेकर मुझे धमकी दे रहा है। मेरे अधिकार क्या हैं?",
        "क्या धारा 420 अब भी लागू है?"
    ]

    static func suggestions(_ english: [String], _ language: AppLanguage) -> [String] {
        language == .hindi ? suggestionsHindi : english
    }

    // MARK: - Trial reminders

    private static let reminderTitles: [String: String] = [
        "r-12h": "आपके मुफ़्त दिन का आधा सफ़र पूरा",
        "r-18h": "ट्रायल में 6 घंटे शेष",
        "r-20h": "ट्रायल में 4 घंटे शेष",
        "r-22h": "ट्रायल में 2 घंटे शेष",
        "r-23h": "ट्रायल में 1 घंटा शेष",
        "r-23h30": "ट्रायल में 30 मिनट शेष",
        "r-23h45": "ट्रायल में 15 मिनट शेष",
        "r-23h55": "ट्रायल में 5 मिनट शेष",
        "r-23h58": "आपका ट्रायल समाप्त होने वाला है"
    ]

    static func reminderTitle(id: String, fallback: String, _ language: AppLanguage) -> String {
        language == .hindi ? (reminderTitles[id] ?? fallback) : fallback
    }

    // MARK: - Dates, durations & numbers

    /// Locale-aware medium date, e.g. "21 Aug 2027" / "21 अगस्त 2027".
    static func date(_ date: Date, _ language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .hindi ? "hi_IN" : "en_IN")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Locale-aware date with time, e.g. "21 Aug 2027, 4:03 PM".
    static func dateTime(_ date: Date, _ language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .hindi ? "hi_IN" : "en_IN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// "21h 34m" / "21 घं 34 मि", "58m" / "58 मिनट", "under a minute" / "एक मिनट से कम".
    static func remaining(_ interval: TimeInterval, _ language: AppLanguage) -> String {
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if language == .hindi {
            if hours > 0 { return "\(hours) घं \(minutes) मि" }
            if minutes > 0 { return "\(minutes) मिनट" }
            return "एक मिनट से कम"
        }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "under a minute"
    }

    /// "12 months" / "12 माह".
    static func planDuration(months: Int, _ language: AppLanguage) -> String {
        if language == .hindi { return months == 1 ? "1 माह" : "\(months) माह" }
        return months == 1 ? "1 month" : "\(months) months"
    }

    /// "≈ ₹49/month" / "≈ ₹49/माह".
    static func perMonth(_ plan: SubscriptionPlan, _ language: AppLanguage) -> String {
        let perMonth = Int((Double(plan.priceINR) / Double(plan.months)).rounded())
        return language == .hindi ? "≈ ₹\(perMonth)/माह" : "≈ ₹\(perMonth)/month"
    }
}

// MARK: - Localized model helpers

extension LexStrings {
    /// Format-string variant — the key's value carries %d / %@ placeholders.
    static func f(_ key: String, _ language: AppLanguage, _ args: CVarArg...) -> String {
        String(format: t(key, language), arguments: args)
    }
}

extension UpdateCategory {
    /// Localized editorial category label.
    func label(_ language: AppLanguage) -> String {
        LexStrings.t("updates.cat.\(rawValue)", language)
    }
}

extension DocumentKind {
    /// Localized group heading.
    func groupTitle(_ language: AppLanguage) -> String {
        LexStrings.t("docs.kind.\(rawValue)", language)
    }

    /// Localized group description.
    func groupBlurb(_ language: AppLanguage) -> String {
        LexStrings.t("docs.kind.\(rawValue).blurb", language)
    }

    /// Localized row badge — "PDF" stays universal.
    func badgeLabel(_ language: AppLanguage) -> String {
        isDownloadable ? "PDF" : LexStrings.t("docs.badge.readInApp", language)
    }
}

extension QuizTopic {
    /// Localized topic label for quiz setup and results.
    func label(_ language: AppLanguage) -> String {
        LexStrings.t("quiz.topic.\(rawValue)", language)
    }
}
