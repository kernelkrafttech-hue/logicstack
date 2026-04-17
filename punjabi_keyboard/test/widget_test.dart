import 'package:flutter_test/flutter_test.dart';
import 'package:punjabi_keyboard/data/punjabi_emojis.dart';

void main() {
  test('PunjabiEmojis.all contains all categories', () {
    final total = PunjabiEmojis.expressions.length +
        PunjabiEmojis.culture.length +
        PunjabiEmojis.food.length +
        PunjabiEmojis.stickers.length;
    expect(PunjabiEmojis.all.length, total);
  });

  test('Stickers include Ik Onkar', () {
    expect(PunjabiEmojis.stickers, contains('ੴ'));
  });
}
