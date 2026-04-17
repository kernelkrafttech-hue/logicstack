package com.kernelkraft.punjabi_keyboard.ime

/**
 * Gurmukhi keyboard key model and layouts.
 *
 * The layout is phonetic-ish: consonants and vowels are grouped roughly by
 * articulation so a Punjabi speaker can find them quickly. Long-press
 * alternates are offered for common diacritics and conjuncts.
 */
data class Key(
    val label: String,
    val output: String = label,
    val longPress: List<String> = emptyList(),
    val weight: Float = 1f,
    val type: KeyType = KeyType.CHAR,
) {
    enum class KeyType { CHAR, SHIFT, BACKSPACE, ENTER, SPACE, SWITCH_LANG, SWITCH_SYM, EMOJI, COMMA, PERIOD }
}

object GurmukhiLayout {

    // Row 1 – common consonants and short vowels (Gurmukhi).
    // Row 2 – more consonants.
    // Row 3 – shift + consonants + backspace.
    // Row 4 – symbol switch, language switch, space, period, enter.
    val rows: List<List<Key>> = listOf(
        listOf(
            Key("ਕ", longPress = listOf("ਖ", "ਗ", "ਘ", "ਙ")),
            Key("ਚ", longPress = listOf("ਛ", "ਜ", "ਝ", "ਞ")),
            Key("ਟ", longPress = listOf("ਠ", "ਡ", "ਢ", "ਣ")),
            Key("ਤ", longPress = listOf("ਥ", "ਦ", "ਧ", "ਨ")),
            Key("ਪ", longPress = listOf("ਫ", "ਬ", "ਭ", "ਮ")),
            Key("ਯ", longPress = listOf("ਰ", "ਲ", "ਵ")),
            Key("ਸ", longPress = listOf("ਸ਼", "ਹ")),
            Key("ਾ", longPress = listOf("ਿ", "ੀ", "ੁ", "ੂ")),
            Key("ੇ", longPress = listOf("ੈ", "ੋ", "ੌ")),
            Key("ਂ", longPress = listOf("ੰ", "ਃ", "ੱ")),
        ),
        listOf(
            Key("ਖ"), Key("ਗ"), Key("ਘ"), Key("ਛ"), Key("ਜ"),
            Key("ਝ"), Key("ਠ"), Key("ਡ"), Key("ਢ"), Key("ਣ"),
        ),
        listOf(
            Key("⇧", type = Key.KeyType.SHIFT, weight = 1.5f),
            Key("ਥ"), Key("ਦ"), Key("ਧ"), Key("ਨ"),
            Key("ਫ"), Key("ਬ"), Key("ਭ"), Key("ਮ"),
            Key("⌫", type = Key.KeyType.BACKSPACE, weight = 1.5f),
        ),
        listOf(
            Key("?123", type = Key.KeyType.SWITCH_SYM, weight = 1.5f),
            Key("🌐", type = Key.KeyType.SWITCH_LANG),
            Key("😊", type = Key.KeyType.EMOJI),
            Key(",", type = Key.KeyType.COMMA),
            Key("ਸਪੇਸ", output = " ", type = Key.KeyType.SPACE, weight = 4f),
            Key(".", type = Key.KeyType.PERIOD),
            Key("↵", type = Key.KeyType.ENTER, weight = 1.5f),
        ),
    )

    // Shifted row: aspirated / additional consonants (pair-style).
    val shifted: List<List<Key>> = listOf(
        listOf(
            Key("ਅ"), Key("ਆ"), Key("ਇ"), Key("ਈ"), Key("ਉ"),
            Key("ਊ"), Key("ਏ"), Key("ਐ"), Key("ਓ"), Key("ਔ"),
        ),
        listOf(
            Key("ੜ"), Key("ਫ਼"), Key("ਜ਼"), Key("ਖ਼"), Key("ਗ਼"),
            Key("ਲ਼"), Key("ਸ਼"), Key("ੲ"), Key("ੳ"), Key("ੴ"),
        ),
        listOf(
            Key("⇧", type = Key.KeyType.SHIFT, weight = 1.5f),
            Key("੍"), Key("਼"), Key("ਁ"), Key("ੱ"),
            Key("ੴ"), Key("॥"), Key("।"), Key("—"),
            Key("⌫", type = Key.KeyType.BACKSPACE, weight = 1.5f),
        ),
        listOf(
            Key("?123", type = Key.KeyType.SWITCH_SYM, weight = 1.5f),
            Key("🌐", type = Key.KeyType.SWITCH_LANG),
            Key("😊", type = Key.KeyType.EMOJI),
            Key(",", type = Key.KeyType.COMMA),
            Key("ਸਪੇਸ", output = " ", type = Key.KeyType.SPACE, weight = 4f),
            Key(".", type = Key.KeyType.PERIOD),
            Key("↵", type = Key.KeyType.ENTER, weight = 1.5f),
        ),
    )
}

object SymbolLayout {
    val rows: List<List<Key>> = listOf(
        listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0").map { Key(it) },
        listOf("੧", "੨", "੩", "੪", "੫", "੬", "੭", "੮", "੯", "੦").map { Key(it) },
        listOf(
            Key("=\\<", type = Key.KeyType.SHIFT, weight = 1.5f),
            Key("@"), Key("#"), Key("\$"), Key("%"),
            Key("&"), Key("*"), Key("-"), Key("+"),
            Key("⌫", type = Key.KeyType.BACKSPACE, weight = 1.5f),
        ),
        listOf(
            Key("ABC", type = Key.KeyType.SWITCH_SYM, weight = 1.5f),
            Key("🌐", type = Key.KeyType.SWITCH_LANG),
            Key("😊", type = Key.KeyType.EMOJI),
            Key(",", type = Key.KeyType.COMMA),
            Key(" ", output = " ", type = Key.KeyType.SPACE, weight = 4f),
            Key(".", type = Key.KeyType.PERIOD),
            Key("↵", type = Key.KeyType.ENTER, weight = 1.5f),
        ),
    )
}
