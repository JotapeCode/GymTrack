// Gera os ícones do Android a partir do símbolo desenhado em código
// (GymTrackMarkPainter), garantindo que app, ícone e abertura usem o mesmo
// desenho e a mesma paleta.
//
// Uso (na raiz do projeto):
//   flutter test tool/generate_brand_icons.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/theme/app_colors.dart';
import 'package:meu_app/widgets/brand.dart';

const _res = 'android/app/src/main/res';

/// Densidades Android e o tamanho base (mdpi) de cada ícone.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

Future<void> _write(
  String path,
  int px,
  void Function(Canvas, double) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas, px.toDouble());
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Ícone legado (Android < 8): bloco escuro arredondado com o símbolo.
void _legacy(Canvas canvas, double s) {
  const p = AppPalette.dark;
  final rect = Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1F2B42), Color(0xFF0F172A)],
      ).createShader(rect),
  );
  canvas.drawRRect(
    rrect.deflate(s * 0.004),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.008
      ..color = p.accent.withValues(alpha: 0.35),
  );
  _mark(canvas, s, 0.80);
}

/// Primeiro plano do ícone adaptativo e da abertura do Android 12+:
/// só o símbolo, dentro da área segura (66 de 108 dp).
void _foreground(Canvas canvas, double s) => _mark(canvas, s, 0.60);

void _mark(Canvas canvas, double s, double scale) {
  final m = s * scale;
  canvas.save();
  canvas.translate((s - m) / 2, (s - m) / 2);
  GymTrackMarkPainter().paint(canvas, Size.square(m));
  canvas.restore();
}

void main() {
  testWidgets('gera os ícones do Android', (tester) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: d, value: f) in _densities.entries) {
        await _write(
          '$_res/mipmap-$d/ic_launcher.png',
          (48 * f).round(),
          _legacy,
        );
        await _write(
          '$_res/mipmap-$d/ic_launcher_foreground.png',
          (108 * f).round(),
          _foreground,
        );
      }
      // Prévia em alta resolução para conferência visual.
      await _write('build/brand_preview.png', 512, _legacy);
    });
  });
}
