import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
/// Structured insight produced on-device by Foundation Models.
@Generable
struct RevenueInsight {
    @Guide(description: "A punchy one-line headline about the revenue trend")
    var headline: String
    @Guide(description: "Two to four short, concrete observations — one short sentence each")
    var points: [String]
    @Guide(description: "One actionable recommendation in a single sentence")
    var recommendation: String
}
#endif

/// On-device revenue insights. Uses Apple's Foundation Models for natural-language phrasing
/// when available; otherwise the caller falls back to deterministic rule-based bullets.
/// AI is used only to *phrase* the figures we compute — never to do the math.
@MainActor
struct InsightEngine {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability { return true }
        #endif
        return false
    }

    private static let instructions = """
    You are an analytics assistant for an app developer's ad revenue. Be concise and concrete. \
    Only use the figures provided in the summary — never invent numbers.
    """

    #if canImport(FoundationModels)
    func generate(facts: String) async -> (headline: String, points: [String], recommendation: String)? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let session = LanguageModelSession()
        let prompt = "\(Self.instructions)\n\nRevenue summary:\n\(facts)\n\nProduce an insight."
        do {
            let insight = try await session.respond(to: prompt, generating: RevenueInsight.self).content
            return (insight.headline, insight.points, insight.recommendation)
        } catch {
            return nil
        }
    }

    /// Free-form Q&A over the revenue summary (the "Ask about your revenue" sheet).
    func answer(question: String, facts: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let session = LanguageModelSession()
        do {
            return try await session.respond(to: "\(Self.instructions)\n\nSummary:\n\(facts)\n\nQuestion: \(question)").content
        } catch { return nil }
    }
    #endif
}
