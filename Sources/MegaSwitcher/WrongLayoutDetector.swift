import AppKit
import Carbon

/// Finds the tail of the typed text that was typed in the wrong layout,
/// by checking words against the macOS spellchecker in both layouts.
enum WrongLayoutDetector {
    private enum Verdict { case right, wrong, ambiguous, unknown }

    /// How many trailing keys should be converted to `intended`.
    static func wrongTailLength(of keys: [TypedKey], typedIn: KeyboardLayout, intended: KeyboardLayout) -> Int {
        let words = splitIntoWords(keys)
        guard let lastWord = words.last else { return 0 }

        // Walk back from the end until a word that is clearly correct as typed.
        var run: [(range: Range<Int>, verdict: Verdict)] = []
        for range in words.reversed() {
            let asTyped = keys[range].map(typedIn.character).joined()
            let asIntended = keys[range].map(intended.character).joined()
            let verdict = classify(asTyped, typedIn, asIntended, intended)
            if verdict == .right { break }
            run.append((range, verdict))
        }

        // Nothing clearly wrong: the user still tapped Option, so convert the last word.
        guard var start = run.lastIndex(where: { $0.verdict == .wrong }) else {
            return keys.count - lastWord.lowerBound
        }
        // Pull in short ambiguous words right before it ("z d jascs" → "я в офісі").
        while start + 1 < run.count, run[start + 1].verdict == .ambiguous { start += 1 }
        return keys.count - run[start].range.lowerBound
    }

    private static func classify(
        _ asTyped: String, _ typedIn: KeyboardLayout, _ asIntended: String, _ intended: KeyboardLayout
    ) -> Verdict {
        let typedLetters = letterCount(asTyped), intendedLetters = letterCount(asIntended)
        if typedLetters == 0 && intendedLetters == 0 { return .ambiguous } // numbers, smileys

        switch (isWord(asTyped, in: typedIn), isWord(asIntended, in: intended)) {
        case (true, true):
            // ",elm" is "elm" in English, but "будь" has more letters → wrong.
            if typedLetters != intendedLetters { return typedLetters > intendedLetters ? .right : .wrong }
            return typedLetters == 1 ? .ambiguous : .right
        case (true, false): return .right
        case (false, true): return .wrong
        case (false, false): return .unknown
        }
    }

    private static func isWord(_ text: String, in layout: KeyboardLayout) -> Bool {
        let word = text.replacingOccurrences(of: "ʼ", with: "'") // Ukrainian apostrophe isn't in the dictionary
        let letters = word.unicodeScalars.filter(CharacterSet.letters.contains)
        guard !letters.isEmpty else { return false }

        // The spellchecker happily accepts "ok" as Ukrainian, so check the script ourselves.
        let isCyrillic = letters.allSatisfy { (0x0400...0x04FF).contains($0.value) }
        let isLatin = letters.allSatisfy(\.isASCII)
        guard layout.isCyrillic ? isCyrillic : isLatin else { return false }

        let misspelled = NSSpellChecker.shared.checkSpelling(
            of: word, startingAt: 0, language: layout.language, wrap: false,
            inSpellDocumentWithTag: 0, wordCount: nil
        )
        return misspelled.location == NSNotFound
    }

    private static func letterCount(_ text: String) -> Int {
        text.filter(\.isLetter).count
    }

    private static func splitIntoWords(_ keys: [TypedKey]) -> [Range<Int>] {
        var words: [Range<Int>] = []
        var start = 0
        for (index, key) in keys.enumerated() where key.keyCode == kVK_Space {
            if start < index { words.append(start..<index) }
            start = index + 1
        }
        if start < keys.count { words.append(start..<keys.count) }
        return words
    }
}
