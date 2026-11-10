import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/theme_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Mostra a tela de abertura enquanto o app inicializa (sessão, tema,
/// formatação de datas) e depois faz a transição para o app.
class GymTrackBoot extends StatefulWidget {
  const GymTrackBoot({
    super.key,
    required this.initialize,
    required this.builder,
  });

  /// Carregamento inicial. Retorna a preferência de tema já lida.
  final Future<ThemeController> Function() initialize;

  /// Monta o app depois do carregamento.
  final Widget Function(ThemeController theme) builder;

  @override
  State<GymTrackBoot> createState() => _GymTrackBootState();
}

class _GymTrackBootState extends State<GymTrackBoot> {
  ThemeController? _theme;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.initialize().then(
      (theme) => _ready(theme),
      // Falha no carregamento não pode prender o usuário na abertura.
      onError: (_) => _ready(ThemeController()),
    );
  }

  void _ready(ThemeController theme) {
    if (mounted) setState(() => _theme = theme);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _finished
          ? KeyedSubtree(
              key: const ValueKey('app'),
              child: widget.builder(_theme!),
            )
          : MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: SplashScreen(
                ready: _theme != null,
                onComplete: () => setState(() => _finished = true),
              ),
            ),
    );
  }
}

/// Tela de abertura do GymTrack: o halter se monta em torno do G, o nome
/// aparece e a barra acompanha o carregamento.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.ready,
    required this.onComplete,
  });

  /// Verdadeiro quando o carregamento terminou.
  final bool ready;

  /// Chamado depois da animação de entrada e do carregamento.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Mesmo tamanho do ícone da abertura nativa do Android 12+.
  static const _markSize = 168.0;

  /// Distância entre o centro do símbolo e o centro da composição
  /// (metade da altura total menos metade do símbolo).
  static const _markToCenter = 107.5;

  /// Entrada: montagem do símbolo, nome e barra (uma única sequência).
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..addStatusListener((_) => _maybeFinish());

  /// Conclusão da barra quando o carregamento termina.
  late final _finish =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Movimento reduzido: pula a animação de entrada.
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
    } else if (!_intro.isAnimating && _intro.value == 0) {
      _intro.forward();
    }
  }

  @override
  void didUpdateWidget(SplashScreen old) {
    super.didUpdateWidget(old);
    _maybeFinish();
  }

  void _maybeFinish() {
    if (widget.ready &&
        _intro.isCompleted &&
        !_finish.isAnimating &&
        !_finish.isCompleted) {
      _finish.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _finish.dispose();
    super.dispose();
  }

  /// Trecho [begin, end] da animação de entrada, com easing.
  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    final text = Theme.of(context).textTheme;
    final rise = _interval(0.0, 0.55);
    final title = _interval(0.15, 0.65);
    final footer = _interval(0.4, 0.9);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _Backdrop(),
            // Centralizado na tela inteira (como a abertura nativa do
            // Android), para o símbolo continuar exatamente no mesmo lugar.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _finish]),
                  // O símbolo começa no centro, onde a abertura nativa o
                  // deixou, e a composição sobe enquanto o nome aparece.
                  builder: (context, _) => Transform.translate(
                    offset: Offset(0, _markToCenter * (1 - rise.value)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GymTrackMark(size: _markSize),
                        _Reveal(
                          progress: title.value,
                          child: Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: text.headlineMedium?.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -1,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Gym'),
                                    TextSpan(
                                      text: 'Track',
                                      style: TextStyle(color: p.accent),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Treine, evolua, supere-se',
                                style: text.bodyMedium?.copyWith(
                                  color: p.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 56),
                        _Reveal(
                          progress: footer.value,
                          child: _LoadingBar(
                            // Durante a entrada a barra avança até 85%; o
                            // restante só completa quando o app está pronto.
                            value: 0.85 * footer.value + 0.15 * _finish.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aparece subindo levemente, em sincronia com a entrada.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress,
    child: Transform.translate(
      offset: Offset(0, 12 * (1 - progress)),
      child: child,
    ),
  );
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Text(
            'Carregando seu progresso…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              key: const Key('splash_progress'),
              value: value,
              minHeight: 5,
              color: p.accent,
              backgroundColor: p.cardHighlight,
            ),
          ),
          const SizedBox(height: 16),
          CustomPaint(
            size: const Size(96, 22),
            painter: _PulsePainter(p.accent.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

/// Linha de pulso (batimento) sob a barra de carregamento.
class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, mid = h / 2;
    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.36, mid)
      ..lineTo(w * 0.44, h * 0.1)
      ..lineTo(w * 0.52, h * 0.95)
      ..lineTo(w * 0.60, mid)
      ..lineTo(w, mid);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.color != color;
}

/// Fundo: brilho verde muito sutil no centro e faixas diagonais discretas
/// nos cantos, como nas placas de anilha.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        // Cores opacas: misturar um verde translúcido com o fundo opaco
        // criaria um anel esverdeado.
        gradient: RadialGradient(
          radius: 0.75,
          colors: [
            Color.alphaBlend(p.accent.withValues(alpha: 0.06), p.background),
            p.background,
          ],
        ),
      ),
      child: CustomPaint(painter: _CornerStripesPainter()),
    );
  }
}

class _CornerStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const p = AppPalette.dark;
    void stripes(Offset origin, double angle) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      for (final (i, alpha) in const [(0, 0.16), (1, 0.09), (2, 0.05)]) {
        final rect = Rect.fromLTWH(-160, i * 22.0 - 30, 320, 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()..color = p.accent.withValues(alpha: alpha),
        );
      }
      canvas.restore();
    }

    stripes(Offset(size.width, 40), -math.pi / 4);
    stripes(Offset(0, size.height - 40), -math.pi / 4 + math.pi);
  }

  @override
  bool shouldRepaint(_CornerStripesPainter old) => false;
}
