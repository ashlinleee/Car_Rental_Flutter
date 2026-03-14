import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_booking/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarRentalApp());
  });
}
