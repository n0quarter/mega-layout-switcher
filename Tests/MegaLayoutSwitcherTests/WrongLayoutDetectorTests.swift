import Testing
@testable import MegaLayoutSwitcher

// Uses the real layouts installed on this Mac (U.S. + Ukrainian) and the real macOS spellchecker.
// Each case: what appears on screen → what one Option tap should turn it into.

private let latin = KeyboardLayout.enabled().first { !$0.isCyrillic }!
private let cyrillic = KeyboardLayout.enabled().first { $0.isCyrillic }!

/// Types `screenText` in `layout`, taps Option, returns the resulting text.
private func optionTap(_ screenText: String, typedIn layout: KeyboardLayout) -> String {
    let other = layout.isCyrillic ? latin : cyrillic
    let keys = screenText.map { key(for: $0, in: layout) }
    let count = WrongLayoutDetector.wrongTailLength(of: keys, typedIn: layout, intended: other)
    return keys.dropLast(count).map(layout.character).joined()
        + keys.suffix(count).map(other.character).joined()
}

private func key(for character: Character, in layout: KeyboardLayout) -> TypedKey {
    for keyCode in UInt16(0)...50 {
        for shift in [false, true] {
            let key = TypedKey(keyCode: keyCode, shift: shift, capsLock: false)
            if layout.character(for: key) == String(character) { return key }
        }
    }
    fatalError("No key for \(character) in \(layout.id)")
}

@MainActor @Suite(.serialized)
struct WrongLayoutDetectorTests {
    @Test(arguments: [
        ("ghbdsn", "привіт"),
        ("ghbdsn zr cghfdb", "привіт як справи"),
        ("Ghbdsn Dsrnjh", "Привіт Віктор"),
        ("ok ,elm kfcrf", "ok будь ласка"),
        (",elm kfcrf? lzre./", "будь ласка, дякую."),
        ("zr cghfdb&", "як справи?"),
        ("I will send it pfdnhf dhfyws", "I will send it завтра вранці"),
        ("I don't know xjve", "I don't know чому"),
        ("let me check it, pfxtrfq [dbkbyre", "let me check it, зачекай хвилинку"),
        ("Slack yt ghfw.'", "Slack не працює"),
        ("thnaks lzre.", "thnaks дякую"),
        ("z d jascs", "я в офісі"),
        ("z", "я"),
        ("j 10 ujlbys", "о 10 годині"),
        ("lzre. ))", "дякую ))"),
        ("v\\zcj s g\\znm", "мʼясо і пʼять"),
        ("`fyjr 'yjn ];fr", "ґанок єнот їжак"),
        ("ghbdsn Nfhfcbr", "привіт Тарасик"),
        ("rhby;", "кринж"),
        ("hello cdsn", "hello світ"),
    ])
    func typedInLatinMeantUkrainian(screen: String, expected: String) {
        #expect(optionTap(screen, typedIn: latin) == expected)
    }

    @Test(arguments: [
        ("руддщ", "hello"),
        ("як справи руддщ", "як справи hello"),
        ("як спарви руддщ", "як спарви hello"),
        ("я зараз скину згдд куйгуіе", "я зараз скину pull request"),
        ("треба оновити Лгиуктуеуі", "треба оновити Kubernetes"),
        ("це дщд", "це lol"),
        ("Ш фь фе рщьу", "I am at home"),
        ("дивись ф сфе", "дивись a cat"),
        ("нуіб ігкуб црн тще", "yes, sure, why not"),
        ("скинь ЗК", "скинь PR"),
    ])
    func typedInUkrainianMeantLatin(screen: String, expected: String) {
        #expect(optionTap(screen, typedIn: cyrillic) == expected)
    }
}
