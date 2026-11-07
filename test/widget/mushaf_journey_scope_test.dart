import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/mushaf/mushaf_page_screen.dart';

void main() {
  test('standalone Mushaf does not track journey progress by default', () {
    const standaloneMushaf = MushafPageScreen();
    const journeyQuranReader = MushafPageScreen(trackJourneyProgress: true);

    expect(standaloneMushaf.trackJourneyProgress, isFalse);
    expect(journeyQuranReader.trackJourneyProgress, isTrue);
  });
}
