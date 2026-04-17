package com.kernelkraft.punjabi_keyboard.ime

object EmojiPalette {
    val expressions = listOf(
        "😂", "🤣", "😍", "😘", "👍", "🙏", "🤝", "🔥", "💯", "❤️",
        "🎉", "💃", "🕺", "😎", "🥰", "😢", "😡", "🙌", "👏", "✨",
    )
    val culture = listOf(
        "🕌", "🪕", "🥁", "🤸", "🤼", "🌾", "🚜", "🐄", "🐕", "🌸",
        "🪔", "🎊", "🏵️",
    )
    val food = listOf(
        "🍛", "🥘", "🥐", "🫓", "🥛", "🍵", "🍬", "🧅", "🌶️", "🍇",
        "🌿", "🫛",
    )
    val stickers = listOf(
        "ੴ", "ਵਾਹਿਗੁਰੂ", "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ", "ਪੰਜਾਬ",
        "ਸ਼ੁਕਰੀਆ", "ਮੁਬਾਰਕਾਂ", "ਜੀ ਆਇਆਂ ਨੂੰ", "ਰੱਬ ਰਾਖਾ",
    )

    val all: List<Pair<String, List<String>>> = listOf(
        "Expressions" to expressions,
        "Culture" to culture,
        "Food" to food,
        "Stickers" to stickers,
    )
}
