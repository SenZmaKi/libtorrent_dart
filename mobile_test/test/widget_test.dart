import 'package:flutter_test/flutter_test.dart';
import 'package:libtorrent_dart_example/main.dart';

void main() {
  testWidgets('shows the magnet download controls', (tester) async {
    await tester.pumpWidget(const LibtorrentExampleApp());

    expect(find.text('libtorrent_dart example'), findsOneWidget);
    expect(find.text('Magnet URI'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
