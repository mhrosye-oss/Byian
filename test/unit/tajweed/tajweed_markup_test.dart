import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/tajweed/tajweed_data.dart';

void main() {
  const localAyah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
  const markup = 'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ '
      '<tajweed class=madda_normal>ـٰ</tajweed> <span class=end>١</span>';

  test('accepts tagged markup only when it matches the local ayah', () {
    expect(tajweedMarkupMatchesText(markup, localAyah), isFalse);
    const fullMarkup = 'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ '
        '<tajweed class=madda_normal>الرَّحْمَٰنَ الرَّحِيمِ</tajweed>'
        '<span class=end>١</span>';
    final correspondingLocal = 'بِسْمِ ٱللَّهِ الرَّحْمَٰنَ الرَّحِيمِ';
    expect(tajweedMarkupMatchesText(fullMarkup, correspondingLocal), isTrue);
  });

  test('parses documented tags and omits the end-of-ayah marker', () {
    final span = tajweedApiMarkupSpan(markup);
    expect(span.children, isNotEmpty);
    expect(span.toPlainText(), isNot(contains('١')));
    expect(span.toPlainText(), contains('بِسْمِ'));
  });
}
