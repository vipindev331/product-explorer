import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/presentation/widgets/app_network_image.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(width: 100, height: 100, child: child)));

  test('the app uses a disk-cached provider so images work offline', () {
    final provider = AppNetworkImage.defaultProvider('https://cdn.example.com/a.png');

    expect(provider, isA<CachedNetworkImageProvider>());
    expect((provider as CachedNetworkImageProvider).url, 'https://cdn.example.com/a.png');
  });

  testWidgets('loads the image through the provider factory', (tester) async {
    final requested = <String>[];
    final original = AppNetworkImage.providerFactory;
    addTearDown(() => AppNetworkImage.providerFactory = original);
    AppNetworkImage.providerFactory = (url) {
      requested.add(url);
      return original(url);
    };

    await tester.pumpWidget(wrap(const AppNetworkImage(url: 'https://cdn.example.com/a.png')));

    expect(requested, ['https://cdn.example.com/a.png']);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows a placeholder for an empty url', (tester) async {
    await tester.pumpWidget(wrap(const AppNetworkImage(url: '  ')));

    expect(find.byType(Image), findsNothing);
    expect(find.byType(ImagePlaceholder), findsOneWidget);
  });

  testWidgets('falls back to a broken-image icon when loading fails', (tester) async {
    final original = AppNetworkImage.providerFactory;
    addTearDown(() => AppNetworkImage.providerFactory = original);
    AppNetworkImage.providerFactory = (_) => _FailingImageProvider();

    await tester.pumpWidget(wrap(const AppNetworkImage(url: 'https://cdn.example.com/missing.png')));
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(_FailingImageProvider key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future<ImageInfo>.error(Exception('offline')));
}
