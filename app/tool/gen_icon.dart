// App-icon generator. Run from app/ with:
//
//   flutter test tool/gen_icon.dart
//
// Runs under the flutter_tester engine because PNG encoding needs real
// dart:ui (PictureRecorder → toImage → toByteData), which plain `dart run`
// does not provide. Writes assets/icon/icon.png (1024×1024); apply to the
// iOS project with `dart run flutter_launcher_icons`.

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _rexyOrange = Color(0xFFFF8A3D);

Path _star(Offset center, double outer, double inner) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = -pi / 2 + i * pi / 5;
    final p = center + Offset(cos(a) * r, sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

void main() {
  test('generate 1024x1024 Wonder Quest app icon', () async {
    final fontBytes = File('assets/fonts/Baloo2-Regular.ttf').readAsBytesSync();
    final loader = FontLoader('Baloo2')
      ..addFont(Future.value(ByteData.sublistView(fontBytes)));
    await loader.load();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Rexy-orange rounded background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _size, _size),
        const Radius.circular(224),
      ),
      Paint()..color = _rexyOrange,
    );

    // Soft highlight band across the top for depth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _size, _size * 0.5),
        const Radius.circular(224),
      ),
      Paint()..color = const Color(0x1AFFFFFF),
    );

    // Big "WQ".
    final tp = TextPainter(
      text: const TextSpan(
        text: 'WQ',
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 430,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((_size - tp.width) / 2, (_size - tp.height) / 2 + 20),
    );

    // Small star, top-right of the letters.
    canvas.drawPath(
      _star(const Offset(830, 240), 86, 34),
      Paint()..color = const Color(0xFFFFC53D),
    );

    final image =
        await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);

    final out = File('assets/icon/icon.png')..createSync(recursive: true);
    out.writeAsBytesSync(png!.buffer.asUint8List());

    expect(out.lengthSync(), greaterThan(1000));
    // ignore: avoid_print
    print('wrote ${out.path} (${out.lengthSync()} bytes)');
  });
}
