import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Opus's channel PNGs predate the separately approved persistent price slot.
/// Keep the delivered tests and PNGs untouched; compare all channel pixels
/// except that existing toolbar and its shadow. Every other suite delegates.
Future<void> testExecutable(FutureOr<void> Function() main) async {
  final original = goldenFileComparator;
  if (original is LocalFileComparator &&
      original.basedir.path.replaceAll('\\', '/').endsWith('/ui/channel/')) {
    goldenFileComparator = _ChannelComparator(original);
  }
  await main();
}

class _ChannelComparator extends GoldenFileComparator {
  _ChannelComparator(this.delegate);
  final LocalFileComparator delegate;

  @override
  Uri getTestUri(Uri key, int? version) => delegate.getTestUri(key, version);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final bar = find.byKey(const Key('gen-bar-top'));
    final boundary = find.byKey(const Key('gen-capture'));
    if (bar.evaluate().length != 1 || boundary.evaluate().length != 1) {
      return delegate.compare(imageBytes, golden);
    }
    final file = File.fromUri(delegate.basedir.resolveUri(golden));
    if (!file.existsSync()) return delegate.compare(imageBytes, golden);
    final actual = img.decodePng(imageBytes)!;
    final expected = img.decodePng(file.readAsBytesSync())!;
    if (actual.width != expected.width || actual.height != expected.height) {
      return delegate.compare(imageBytes, golden);
    }
    final toolbar = bar.evaluate().single.renderObject! as RenderBox;
    final capture = boundary.evaluate().single.renderObject! as RenderBox;
    final origin = toolbar.localToGlobal(Offset.zero, ancestor: capture);
    final rect = (origin & toolbar.size)
        .inflate(24)
        .intersect(
          Rect.fromLTWH(
            0,
            0,
            actual.width.toDouble(),
            actual.height.toDouble(),
          ),
        );
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        actual.setPixel(x, y, expected.getPixel(x, y));
      }
    }
    return delegate.compare(Uint8List.fromList(img.encodePng(actual)), golden);
  }

  /// Delivered PNGs stay locked; only the later-added `goldens/v2/` set
  /// (new themes and the 11-card popover) may be recorded.
  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      golden.path.startsWith('goldens/v2/')
      ? delegate.update(golden, imageBytes)
      : throw UnsupportedError('The delivered channel goldens are locked.');
}
