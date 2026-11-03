import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddleclash/services/iap_service.dart';

void main() {
  test('iOS maps to the single Gold Star product', () {
    expect(ClashStore.productIdsFor(TargetPlatform.iOS), {'paddleclashstar'});
    expect(ClashStore.starId, 'paddleclashstar');
  });
  test('Android maps to coffee + chocolate only', () {
    expect(ClashStore.productIdsFor(TargetPlatform.android),
        {'paddleclashcoffee', 'paddleclashchocolate'});
    expect(ClashStore.productIdsFor(TargetPlatform.android),
        isNot(contains('paddleclashstar')));
  });
}
