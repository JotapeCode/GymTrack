import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Símbolo do GymTrack: a letra G no centro de um halter.
///
/// Desenhado em código para ficar nítido em qualquer tamanho e usar a
/// paleta do app. O mesmo desenho gera os ícones do Android
/// (veja `tool/generate_brand_icons.dart`).
class GymTrackMark extends StatelessWidget {
  const GymTrackMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: GymTrackMarkPainter());
}

class GymTrackMarkPainter extends CustomPainter {
  GymTrackMarkPainter({AppPalette palette = AppPalette.dark})
    : plate = palette.textPrimary,
      bar = palette.textSecondary,
      accent = palette.accent,
      accentDark = palette.accentDark;

  final Color plate;
  final Color bar;
  final Color accent;
  final Color accentDark;

  // Geometria em unidades de 0 a 1 (quadrado), centrada em (0,5; 0,5).
  static const _gOuter = 0.22; // raio externo do G
  static const _gStroke = 0.085; // espessura do traço do G

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);

    // Anilhas e pegador, espelhados dos dois lados do G.
    _drawHalf(canvas);
    canvas.save();
    canvas.translate(1, 0);
    canvas.scale(-1, 1);
    _drawHalf(canvas);
    canvas.restore();

    _drawG(canvas);
    canvas.restore();
  }

  /// Metade esquerda do halter (a direita é espelhada).
  void _drawHalf(Canvas canvas) {
    Paint fill(Color c) => Paint()..color = c;
    RRect r(double l, double top, double w, double h) =>
        RRect.fromLTRBR(l, top, l + w, top + h, const Radius.circular(0.022));

    // Pegador: termina na borda do G, que o "esconde".
    canvas.drawRRect(r(0.05, 0.4725, 0.23, 0.055), fill(bar));
    // Anilha externa (menor) e interna (maior).
    canvas.drawRRect(r(0.095, 0.35, 0.06, 0.30), fill(plate));
    canvas.drawRRect(r(0.165, 0.28, 0.08, 0.44), fill(plate));
    // Aro verde na face interna da anilha maior.
    canvas.drawRRect(r(0.222, 0.28, 0.023, 0.44), fill(accent));
  }

  void _drawG(Canvas canvas) {
    const center = Offset(0.5, 0.5);
    const rc = _gOuter - _gStroke / 2;
    final bounds = Rect.fromCircle(center: center, radius: _gOuter);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accentDark],
      ).createShader(bounds);

    // G inclinado (itálico): sugere movimento e diferencia o símbolo de um
    // G redondo genérico.
    canvas.save();
    canvas.translate(0.5, 0.5);
    canvas.skew(-0.2, 0);
    canvas.translate(-0.5, -0.5);

    // Arco: começa no alto à direita e dá a volta pela esquerda até o meio
    // do lado direito, onde nasce a barra horizontal do G.
    const start = -0.24 * 3.14159265;
    const sweep = -1.76 * 3.14159265;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rc),
      start,
      sweep,
      false,
      Paint()
        ..shader = paint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = _gStroke,
    );
    // Barra do G, no nível do centro.
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0.5,
        0.5,
        0.5 + _gOuter,
        0.5 + _gStroke * 0.95,
        bottomLeft: const Radius.circular(0.012),
        topLeft: const Radius.circular(0.012),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GymTrackMarkPainter old) =>
      old.plate != plate || old.accent != accent;
}

/// Ícone do app: o símbolo sobre um bloco escuro com borda sutil.
/// Sempre usa o fundo escuro da marca, nos dois temas.
class GymTrackAppIcon extends StatelessWidget {
  const GymTrackAppIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.cardHighlight, p.background],
        ),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: p.accent.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: GymTrackMark(size: size * 0.82)),
    );
  }
}
