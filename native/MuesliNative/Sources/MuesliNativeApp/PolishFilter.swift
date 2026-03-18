import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Cleans up dictated text by stripping filler words and fixing whitespace.
/// Uses fast regex matching — no LLM, no guardrails, no refusals.
/// Optionally enhances with Apple Foundation Model for grammar (when it doesn't refuse).
enum PolishFilter {
    /// Filler patterns to strip. Order matters: longer phrases first to avoid partial matches.
    private static let fillerPatterns: [(pattern: String, options: NSRegularExpression.Options)] = [
        // Multi-word fillers (match first)
        (#"\b[Yy]ou know what\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Oo]kay so\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Yy]ou know\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Ii] mean\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Ss]o basically\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Ll]ike basically\b[,.]?\s*"#, [.caseInsensitive]),
        // Single-word fillers
        (#"\b[Uu]m+\b[,.]?\s*"#, []),
        (#"\b[Uu]h+\b[,.]?\s*"#, []),
        (#"\b[Mm]m-hmm\b[,.]?\s*"#, [.caseInsensitive]),
        (#"\b[Mm]m+\b[,.]?\s*"#, []),
        (#"\b[Hh]mm+\b[,.]?\s*"#, []),
        (#"\b[Aa]h+\b[,.]?\s*"#, []),
        (#"\b[Ee]r+\b[,.]?\s*"#, []),
        // "like" only as filler (preceded by comma or start of sentence, not "I like" / "looks like")
        (#"(?<=,\s)[Ll]ike\s+"#, []),
        (#"^[Ll]ike,?\s+"#, [.anchorsMatchLines]),
        // "okay" / "right" / "so" as standalone sentence starters
        (#"^[Oo]kay[,.]?\s+"#, [.anchorsMatchLines]),
        (#"^[Ss]o[,.]?\s+"#, [.anchorsMatchLines]),
        (#"^[Rr]ight[,.]?\s+"#, [.anchorsMatchLines]),
    ]

    /// Compiled regexes (built once).
    private static let fillerRegexes: [(NSRegularExpression, String)] = {
        fillerPatterns.compactMap { pattern, options in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                fputs("[polish] failed to compile regex: \(pattern)\n", stderr)
                return nil
            }
            return (regex, "")
        }
    }()

    /// Strip filler words from text using regex. Always works, zero latency.
    static func stripFillers(_ text: String) -> String {
        var result = text
        for (regex, replacement) in fillerRegexes {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
        }
        // Clean up leftover whitespace artifacts
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " \\.", with: ".", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespaces)

        // Capitalize first letter after cleanup
        if let first = result.first, first.isLowercase {
            result = first.uppercased() + result.dropFirst()
        }

        fputs("[polish] fillers stripped: \(result.prefix(60))...\n", stderr)
        return result
    }

    /// Try Apple Foundation Model for grammar polish. Falls back to input on any failure.
    @available(macOS 26, *)
    static func applyLLM(_ text: String) async -> String {
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else {
            return text
        }
        guard text.count >= 10 else { return text }

        let session = LanguageModelSession(instructions:
            "Proofread the text. Fix punctuation and grammar only. Reply with the corrected text."
        )

        do {
            let response = try await session.respond(to: text)
            let polished = response.content

            // Detect refusals
            let lower = polished.lowercased()
            let refusals = ["i'm sorry", "i cannot", "i can't", "as an ai", "as an llm", "i apologize"]
            if refusals.contains(where: { lower.hasPrefix($0) }) {
                fputs("[polish] LLM refused, skipping grammar pass\n", stderr)
                return text
            }

            // Validate output length ratio
            let ratio = Double(polished.count) / max(Double(text.count), 1.0)
            guard ratio > 0.3 && ratio < 2.0 && !polished.isEmpty else {
                return text
            }

            fputs("[polish] LLM done: \(polished.prefix(60))...\n", stderr)
            return polished
        } catch {
            fputs("[polish] LLM failed: \(type(of: error)), skipping grammar pass\n", stderr)
            return text
        }
        #else
        return text
        #endif
    }
}

/// Convenience entry point. Regex filler stripping only — Apple FM too unreliable for dictation.
enum PolishFilterCompat {
    static func applyIfAvailable(_ text: String) async -> String {
        return PolishFilter.stripFillers(text)
    }

    static func prewarmIfAvailable() {
        // No-op
    }
}
