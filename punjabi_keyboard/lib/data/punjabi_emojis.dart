/// "Punjabi-flavored" emoji groupings. These are standard Unicode emoji
/// hand-picked to fit Punjabi culture (food, festivals, kabaddi, etc.) plus
/// Gurmukhi glyph stickers rendered as text.
class PunjabiEmojis {
  static const culture = <String>[
    '\u{1F54C}', // mosque (gurdwara stand-in – see stickers for Ik Onkar)
    '\u{1FA95}', // banjo (dhol stand-in)
    '\u{1F941}', // drum
    '\u{1F938}', // person cartwheeling (kabaddi)
    '\u{1F93C}', // wrestlers
    '\u{1F33E}', // sheaf of rice (farming)
    '\u{1F69C}', // tractor
    '\u{1F42E}', // cow
    '\u{1F436}', // dog
    '\u{1F338}', // cherry blossom (spring / Vaisakhi)
    '\u{1FA94}', // diya lamp
    '\u{1F389}', // party popper
  ];

  static const food = <String>[
    '\u{1F35B}', // curry (dal/makhani stand-in)
    '\u{1F958}', // shallow pan of food
    '\u{1F950}', // croissant (paratha stand-in)
    '\u{1FAD3}', // flatbread (roti)
    '\u{1F95B}', // glass of milk (lassi stand-in)
    '\u{1F375}', // teacup (chai)
    '\u{1F36C}', // candy (mithai)
    '\u{1F9C5}', // onion
    '\u{1F336}', // hot pepper
    '\u{1F347}', // grapes
    '\u{1F33F}', // herb (methi)
  ];

  static const expressions = <String>[
    '\u{1F602}', '\u{1F923}', '\u{1F60D}', '\u{1F618}', '\u{1F44D}',
    '\u{1F64F}', '\u{1F91D}', '\u{1F525}', '\u{1F4AF}', '\u{2764}\u{FE0F}',
    '\u{1F389}', '\u{1F483}', '\u{1F57A}',
  ];

  /// Gurmukhi/Punjabi text "sticker" glyphs.
  static const stickers = <String>[
    'ੴ', // Ik Onkar
    'ਵਾਹਿਗੁਰੂ',
    'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ',
    'ਪੰਜਾਬ',
    'ਸ਼ੁਕਰੀਆ',
    'ਮੁਬਾਰਕਾਂ',
    'ਜੀ ਆਇਆਂ ਨੂੰ',
    'ਰੱਬ ਰਾਖਾ',
  ];

  static List<String> get all => [
        ...expressions,
        ...culture,
        ...food,
        ...stickers,
      ];
}
