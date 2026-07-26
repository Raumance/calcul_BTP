import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:calcul_projet/core/constants/app_colors.dart';
import 'package:calcul_projet/core/providers/core_providers.dart';
import 'package:calcul_projet/core/utils/freemium_guard.dart';
import 'package:calcul_projet/features/projet/presentation/providers/app_session_provider.dart';
import 'package:calcul_projet/shared/widgets/chantier_button.dart';

class PlanSegment {
  const PlanSegment({
    required this.type,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.valeurMetres,
    this.label = '',
  });

  final String type;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double? valeurMetres;
  final String label;

  factory PlanSegment.fromJson(Map<String, dynamic> json) => PlanSegment(
        type: json['type'] as String? ?? 'mur',
        x1: (json['x1'] as num?)?.toDouble() ?? 0,
        y1: (json['y1'] as num?)?.toDouble() ?? 0,
        x2: (json['x2'] as num?)?.toDouble() ?? 0,
        y2: (json['y2'] as num?)?.toDouble() ?? 0,
        valeurMetres: (json['valeur_metres'] as num?)?.toDouble(),
        label: json['label'] as String? ?? '',
      );
}

/// Écran plan : picker → étalonnage → analyse IA (ou démo locale) → overlay.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _picker = ImagePicker();
  final _mesureMetres = TextEditingController(text: '5');
  File? _imageFile;
  ui.Image? _decoded;
  /// Points en coordonnées pixels image.
  Offset? _p1;
  Offset? _p2;
  List<PlanSegment> _segments = [];
  double? _echelle;
  bool _loading = false;
  String? _mode;

  @override
  void dispose() {
    _mesureMetres.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    // Optimisation : réduction de la résolution et compression qualité
    // pour accélérer l'envoi réseau vers l'IA sans perte de précision métier.
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (x == null) return;
    final file = File(x.path);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _imageFile = file;
      _decoded = frame.image;
      _p1 = null;
      _p2 = null;
      _segments = [];
      _echelle = null;
      _mode = null;
    });
  }

  double? get _pixelsRef {
    if (_p1 == null || _p2 == null) return null;
    return (_p2! - _p1!).distance;
  }

  Future<void> _analyser() async {
    final session = ref.read(appSessionProvider);
    final pixels = _pixelsRef;
    final metres = double.tryParse(_mesureMetres.text.replaceAll(',', '.'));
    if (_imageFile == null || pixels == null || metres == null || metres <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez une image, deux points d\'étalonnage et une mesure > 0.',
          ),
        ),
      );
      return;
    }

    final peutApi = FreemiumGuard.peutAcceder(
      estConnecte: session.estConnecte,
      estAbonne: session.estAbonne,
      fonctionnalite: 'analyse_ia',
    );

    setState(() => _loading = true);
    try {
      if (peutApi && session.isOnline) {
        final b64 = base64Encode(await _imageFile!.readAsBytes());
        final api = ref.read(apiClientProvider);
        final resp = await api.post(
          '/api/plans/analyse/',
          data: {
            'image_base64': b64,
            'mesure_ref_metres': metres,
            'mesure_ref_pixels': pixels,
          },
        );
        final root = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : <String, dynamic>{};
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        final segs = (data['segments'] as List? ?? [])
            .map(
              (e) => PlanSegment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        setState(() {
          _segments = segs;
          _echelle = (data['echelle_metres_par_pixel'] as num?)?.toDouble() ??
              metres / pixels;
          _mode = data['mode'] as String? ?? 'api';
        });
      } else {
        final echelle = metres / pixels;
        setState(() {
          _echelle = echelle;
          _mode = peutApi ? 'offline_local' : 'demo_freemium';
          _segments = [
            PlanSegment(
              type: 'cote',
              x1: _p1!.dx,
              y1: _p1!.dy,
              x2: _p2!.dx,
              y2: _p2!.dy,
              valeurMetres: metres,
              label: 'Référence',
            ),
          ];
        });
        if (!peutApi && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mode démo : abonnement requis pour l\'analyse IA serveur.',
              ),
            ),
          );
        }
      }

      final projet = session.projetActif;
      if (projet != null) {
        await ref.read(localStoreProvider).upsertPlan({
          'id': const Uuid().v4(),
          'projet_id': projet.id,
          'image_path': _imageFile!.path,
          'echelle': _echelle,
          'mode': _mode,
          'segments': _segments
              .map(
                (s) => {
                  'type': s.type,
                  'x1': s.x1,
                  'y1': s.y1,
                  'x2': s.x2,
                  'y2': s.y2,
                  'valeur_metres': s.valeurMetres,
                  'label': s.label,
                },
              )
              .toList(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } on DioException catch (e) {
      final msg = e.error?.toString() ??
          e.response?.data?.toString() ??
          'Analyse impossible.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _decoded;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plan par image'),
        actions: [
          IconButton(
            tooltip: 'Galerie',
            onPressed: _loading ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '1. Importez un plan · 2. Touchez deux points d\'une cote connue · '
            '3. Saisissez la longueur réelle · 4. Analysez.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (img == null)
            Container(
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: ChantierButton(
                label: 'Choisir une image',
                icon: Icons.add_photo_alternate_outlined,
                onPressed: _pick,
                expand: false,
              ),
            )
          else
            AspectRatio(
              aspectRatio: img.width / img.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (d) {
                      final ix =
                          d.localPosition.dx / constraints.maxWidth * img.width;
                      final iy = d.localPosition.dy /
                          constraints.maxHeight *
                          img.height;
                      final point = Offset(ix, iy);
                      setState(() {
                        if (_p1 == null || (_p1 != null && _p2 != null)) {
                          _p1 = point;
                          _p2 = null;
                        } else {
                          _p2 = point;
                        }
                      });
                    },
                    child: CustomPaint(
                      painter: _PlanPainter(
                        image: img,
                        p1: _p1,
                        p2: _p2,
                        segments: _segments,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _mesureMetres,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Longueur réelle de référence (m)',
              suffixText: 'm',
            ),
          ),
          if (_pixelsRef != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Distance image : ${_pixelsRef!.toStringAsFixed(1)} px'
                '${_echelle != null ? ' · échelle ${_echelle!.toStringAsExponential(2)} m/px' : ''}'
                '${_mode != null ? ' · $_mode' : ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          if (_segments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Segments détectés',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ..._segments.map(
              (s) => ListTile(
                dense: true,
                title: Text(s.label.isEmpty ? s.type : s.label),
                trailing: Text(
                  s.valeurMetres == null
                      ? '—'
                      : '${s.valeurMetres!.toStringAsFixed(2)} m',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ChantierButton(
            label: _loading ? 'Analyse…' : 'Analyser le plan',
            icon: Icons.auto_fix_high,
            onPressed: _loading ? null : _analyser,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.image,
    required this.p1,
    required this.p2,
    required this.segments,
  });

  final ui.Image image;
  final Offset? p1;
  final Offset? p2;
  final List<PlanSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / image.width;
    final sy = size.height / image.height;

    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
    );

    final refPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final segPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = AppColors.secondary;

    Offset map(Offset o) => Offset(o.dx * sx, o.dy * sy);

    for (final s in segments) {
      canvas.drawLine(
        map(Offset(s.x1, s.y1)),
        map(Offset(s.x2, s.y2)),
        segPaint,
      );
    }

    if (p1 != null) {
      canvas.drawCircle(map(p1!), 6, pointPaint);
    }
    if (p1 != null && p2 != null) {
      canvas.drawLine(map(p1!), map(p2!), refPaint);
      canvas.drawCircle(map(p2!), 6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanPainter oldDelegate) => true;
}
