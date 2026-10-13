import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Shows a network image at full width, with blank white or transparent
/// edges removed so the photo itself is not letterboxed.
class FullBleedImage extends StatefulWidget {
  final String url;

  const FullBleedImage({super.key, required this.url});

  @override
  State<FullBleedImage> createState() => _FullBleedImageState();
}

class _FullBleedImageState extends State<FullBleedImage> {
  static final Map<String, Future<ui.Image>> _cache = {};

  Future<ui.Image>? _image;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(FullBleedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolve();
  }

  void _resolve() {
    _image = _cache.putIfAbsent(widget.url, () => _load(widget.url));
  }

  static Future<ui.Image> _load(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Image failed: ${response.statusCode}');
    }
    final codec = await ui.instantiateImageCodec(
      response.bodyBytes,
      targetWidth: 1400,
    );
    final frame = await codec.getNextFrame();
    final source = frame.image;
    final cropped = await _trimBlankEdges(source);
    if (!identical(cropped, source)) source.dispose();
    return cropped;
  }

  static bool _isBlank(int r, int g, int b, int a) {
    if (a < 16) return true;
    return r > 242 && g > 242 && b > 242;
  }

  static Future<ui.Image> _trimBlankEdges(ui.Image source) async {
    final byteData = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return source;

    final pixels = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final width = source.width;
    final height = source.height;

    bool rowHasContent(int y) {
      final row = y * width * 4;
      for (var x = 0; x < width; x++) {
        final i = row + x * 4;
        if (!_isBlank(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])) {
          return true;
        }
      }
      return false;
    }

    bool columnHasContent(int x, int top, int bottom) {
      for (var y = top; y <= bottom; y++) {
        final i = (y * width + x) * 4;
        if (!_isBlank(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])) {
          return true;
        }
      }
      return false;
    }

    var top = 0;
    while (top < height && !rowHasContent(top)) {
      top++;
    }
    var bottom = height - 1;
    while (bottom > top && !rowHasContent(bottom)) {
      bottom--;
    }
    if (top >= bottom) return source;

    var left = 0;
    while (left < width && !columnHasContent(left, top, bottom)) {
      left++;
    }
    var right = width - 1;
    while (right > left && !columnHasContent(right, top, bottom)) {
      right--;
    }
    if (left >= right) return source;

    final cropWidth = right - left + 1;
    final cropHeight = bottom - top + 1;
    if (cropWidth > width - 4 && cropHeight > height - 4) return source;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(left.toDouble(), top.toDouble(), cropWidth.toDouble(), cropHeight.toDouble()),
      Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
      Paint(),
    );
    return recorder.endRecording().toImage(cropWidth, cropHeight);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            height: 220,
            color: Colors.grey[200],
          );
        }
        final image = snapshot.data;
        if (image == null) {
          return const SizedBox(
            width: double.infinity,
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return RawImage(
          image: image,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
