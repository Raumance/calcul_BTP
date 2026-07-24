import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/disclaimer_banner.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../projet/presentation/providers/app_session_provider.dart';
import '../../domain/models/ratio_ferraillage.dart';
import '../../domain/moteur/gros_oeuvre_engine.dart';

class GrosOeuvreScreen extends ConsumerStatefulWidget {
  const GrosOeuvreScreen({super.key});

  @override
  ConsumerState<GrosOeuvreScreen> createState() => _GrosOeuvreScreenState();
}

class _GrosOeuvreScreenState extends ConsumerState<GrosOeuvreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _long = TextEditingController(text: '6');
  final _larg = TextEditingController(text: '4');
  final _epais = TextEditingController(text: '0.15');
  final _longMur = TextEditingController(text: '12');
  final _hautMur = TextEditingController(text: '2.5');

  double _perteBeton = AppConstants.perteBeton;
  double _perteParpaing = AppConstants.perteParpaing;
  RatioFerraillage _ratio = RatioFerraillage.dalle;

  dynamic _beton;
  dynamic _parpaings;
  dynamic _mortier;
  dynamic _acier;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _recalculer();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _long.dispose();
    _larg.dispose();
    _epais.dispose();
    _longMur.dispose();
    _hautMur.dispose();
    super.dispose();
  }

  void _recalculer() {
    final l = Validators.parsePositive(_long.text);
    final la = Validators.parsePositive(_larg.text);
    final e = Validators.parsePositive(_epais.text);
    final lm = Validators.parsePositive(_longMur.text);
    final hm = Validators.parsePositive(_hautMur.text);

    setState(() {
      if (l != null && la != null && e != null) {
        _beton = GrosOeuvreEngine.volumeBeton(
          longueur: l,
          largeur: la,
          epaisseur: e,
          coefficientPerte: _perteBeton,
        );
        _acier = GrosOeuvreEngine.quantiteAcier(
          volumeBeton: _beton.valeurPrincipale,
          ratio: _ratio,
        );
      }
      if (lm != null && hm != null) {
        _parpaings = GrosOeuvreEngine.nombreParpaings(
          longueurMur: lm,
          hauteurMur: hm,
          coefficientPerte: _perteParpaing,
        );
        _mortier = GrosOeuvreEngine.volumeMortier(
          nombreParpaings: _parpaings.valeurPrincipale,
        );
      }
    });
  }

  void _add(dynamic result, String phase) {
    try {
      ref.read(appSessionProvider.notifier).ajouterResultatAuDevis(
            result: result,
            phase: phase,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté au devis.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gros œuvre'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Béton'),
            Tab(text: 'Parpaings'),
            Tab(text: 'Ferraillage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildBeton(),
          _buildParpaings(),
          _buildFerraillage(),
        ],
      ),
    );
  }

  Widget _buildBeton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NumberField(label: 'Longueur', controller: _long, suffix: 'm', onChanged: (_) => _recalculer()),
        const SizedBox(height: 12),
        NumberField(label: 'Largeur', controller: _larg, suffix: 'm', onChanged: (_) => _recalculer()),
        const SizedBox(height: 12),
        NumberField(label: 'Épaisseur', controller: _epais, suffix: 'm', onChanged: (_) => _recalculer()),
        const SizedBox(height: 12),
        PerteSlider(
          value: _perteBeton,
          min: 0.01,
          max: 0.10,
          onChanged: (v) {
            setState(() => _perteBeton = v);
            _recalculer();
          },
        ),
        if (_beton != null)
          ResultCard(
            valeur: _beton.valeurPrincipale,
            unite: _beton.unite,
            designation: _beton.designation,
            referenceNormative: _beton.referenceNormative,
            onAddToDevis: () => _add(_beton, 'gros_oeuvre'),
          ),
        const SizedBox(height: 16),
        const DisclaimerBanner(),
      ],
    );
  }

  Widget _buildParpaings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NumberField(label: 'Longueur du mur', controller: _longMur, suffix: 'm', onChanged: (_) => _recalculer()),
        const SizedBox(height: 12),
        NumberField(label: 'Hauteur du mur', controller: _hautMur, suffix: 'm', onChanged: (_) => _recalculer()),
        const SizedBox(height: 12),
        PerteSlider(
          value: _perteParpaing,
          min: 0.01,
          max: 0.20,
          onChanged: (v) {
            setState(() => _perteParpaing = v);
            _recalculer();
          },
        ),
        if (_parpaings != null) ...[
          ResultCard(
            valeur: _parpaings.valeurPrincipale,
            unite: _parpaings.unite,
            designation: _parpaings.designation,
            referenceNormative: _parpaings.referenceNormative,
            onAddToDevis: () => _add(_parpaings, 'gros_oeuvre'),
          ),
          const SizedBox(height: 12),
        ],
        if (_mortier != null)
          ResultCard(
            valeur: _mortier.valeurPrincipale,
            unite: _mortier.unite,
            designation: _mortier.designation,
            referenceNormative: _mortier.referenceNormative,
            onAddToDevis: () => _add(_mortier, 'gros_oeuvre'),
          ),
        const SizedBox(height: 16),
        const DisclaimerBanner(),
      ],
    );
  }

  Widget _buildFerraillage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Type d\'ouvrage', style: TextStyle(fontWeight: FontWeight.w600)),
        ...RatioFerraillage.defaults.map(
          (r) => RadioListTile<RatioFerraillage>(
            value: r,
            groupValue: _ratio,
            title: Text(r.libelle),
            subtitle: Text('${r.valeurKgM3} kg/m³ — ${r.sourceNormative}'),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _ratio = v);
              _recalculer();
            },
          ),
        ),
        if (_acier != null)
          ResultCard(
            valeur: _acier.valeurPrincipale,
            unite: _acier.unite,
            designation: _acier.designation,
            referenceNormative: _acier.referenceNormative,
            onAddToDevis: () => _add(_acier, 'fondation'),
          ),
        const SizedBox(height: 16),
        const DisclaimerBanner(),
      ],
    );
  }
}
