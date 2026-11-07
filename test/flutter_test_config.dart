import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:product_explorer/presentation/widgets/app_network_image.dart';

/// A 1x1 transparent PNG, so widget tests render images without any network or
/// disk access.
final _transparentPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppNetworkImage.providerFactory = (_) => MemoryImage(_transparentPixel);
  await testMain();
}
