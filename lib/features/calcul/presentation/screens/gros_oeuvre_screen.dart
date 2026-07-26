import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/disclaimer_banner.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../projet/presentation/providers/app_session_provider.dart';
import '../../domain/models/bloc.dart';
import '../../domain/models/ciment.dart';
import '../../domain/models/ferraillage.dart';
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
  DosageBeton _dosageBeton = DosageBeton.standard;
  TypeCiment _typeCiment = TypeCiment.cpj325;
  SacCiment _sacCiment = SacCiment.sac50;
  TypeParpaing _typeParpaing = TypeParpaing.parpaing50x20x20;
  TypeBrique _typeBrique = TypeBrique.standard27x13x7;
  double _dosageMortier = 250.0;
  TypeCiment _typeCimentMortier = TypeCiment.cpj325;
  SacCiment _sacCimentMortier = SacCiment.sac50;
  TypeAcier _typeAcier = TypeAcier.feE400;
  SectionType _sectionType = SectionType.carre;
  double _longueurPoteau = 3.0;
  double _largeurPoteau = 0.30;
  double _hauteurPoteau = 0.30;
  double _diametreEtrier = 8;
  double _pasEtrier = 0.20;
  double _longueurBarre = 12.0;

  dynamic _beton;
  dynamic _parpaings;
  dynamic _mortier;
  dynamic _mortierCiment;
  dynamic _acier;
  dynamic _acierDetail;
  dynamic _ciment;
  dynamic _briques;
  dynamic _acierDetail;

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
          typeAcier: _typeAcier,
          sectionType: _sectionType,
          longueurPoteau: _longueurPoteau,
          largeurPoteau: _largeurPoteau,
          hauteurPoteau: _hauteurPoteau,
          diametreEtrierMm: _diametreEtrier,
          pasEtrier: _pasEtrier,
          longueurTige: _longueurBarre,
        );
        _acierDetail = _acier;
        _ciment = GrosOeuvreEngine.quantiteCiment(
          volumeBeton: _beton.valeurPrincipale,
          dosage: _dosageBeton,
          typeCiment: _typeCiment,
          sacCiment: _sacCiment,
        );
      }
      if (lm != null && hm != null) {
        _parpaings = GrosOeuvreEngine.nombreParpaings(
          longueurMur: lm,
          hauteurMur: hm,
          typeParpaing: _typeParpaing,
          coefficientPerte: _perteParpaing,
        );
        _mortier = GrosOeuvreEngine.volumeMortier(
          nombreParpaings: _parpaings.valeurPrincipale,
          typeParpaing: _typeParpaing,
        );
        if (_mortier != null) {
          _mortierCiment = GrosOeuvreEngine.quantiteCimentMortier(
            volumeMortier: _mortier.valeurPrincipale,
            dosageKgM3: _dosageMortier,
            typeCiment: _typeCimentMortier,
            sacCiment: _sacCimentMortier,
          );
        }
        _briques = GrosOeuvreEngine.nombreBriques(
          longueurMur: lm,
          hauteurMur: hm,
          typeBrique: _typeBrique,
          coefficientPerte: _perteParpaing,
        );
        _acier = GrosOeuvreEngine.quantiteAcier(
          volumeBeton: _volumeBeton,
          ratio: _ratioFerraillage,
        );
        _acierDetail = GrosOeuvreEngine.quantiteAcierDetail(
          volumeBeton: _volumeBeton,
          ratio: _ratioFerraillage,
          typeAcier: _typeAcier,
          sectionType: _sectionType,
          longueurPoteau: _longueurPoteau,
          largeurPoteau: _largeurPoteau,
          hauteurPoteau: _hauteurPoteau,
          diametreEtrierMm: _diametreEtrier,
          pasEtrier: _pasEtrier,
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
        DropdownButtonFormField<DosageBeton>(
          value: _dosageBeton,
          decoration: const InputDecoration(
            labelText: 'Dosage béton',
            border: OutlineInputBorder(),
          ),
          items: DosageBeton.defaults
              .map((d) => DropdownMenuItem(value: d, child: Text(d.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _dosageBeton = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TypeCiment>(
          value: _typeCiment,
          decoration: const InputDecoration(
            labelText: 'Type de ciment',
            border: OutlineInputBorder(),
          ),
          items: TypeCiment.defaults
              .map((c) => DropdownMenuItem(value: c, child: Text(c.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _typeCiment = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SacCiment>(
          value: _sacCiment,
          decoration: const InputDecoration(
            labelText: 'Poids sac ciment',
            border: OutlineInputBorder(),
          ),
          items: SacCiment.defaults
              .map((s) => DropdownMenuItem(value: s, child: Text(s.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _sacCiment = v);
            _recalculer();
          },
        ),
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
        const SizedBox(height: 12),
        if (_ciment != null)
          ResultCard(
            valeur: _ciment.valeurPrincipale,
            unite: _ciment.unite,
            designation: _ciment.designation,
            referenceNormative: _ciment.referenceNormative,
            onAddToDevis: () => _add(_ciment, 'gros_oeuvre'),
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
        DropdownButtonFormField<TypeParpaing>(
          value: _typeParpaing,
          decoration: const InputDecoration(
            labelText: 'Type de parpaing',
            border: OutlineInputBorder(),
          ),
          items: TypeParpaing.defaults
              .map((p) => DropdownMenuItem(value: p, child: Text(p.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _typeParpaing = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Dosage ciment (mortier)',
          controller: TextEditingController(text: _dosageMortier.toString()),
          suffix: 'kg/m³',
          onChanged: (value) {
            final parsed = double.tryParse(value.replaceAll(',', '.'));
            if (parsed != null && parsed > 0) {
              setState(() => _dosageMortier = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TypeCiment>(
          value: _typeCimentMortier,
          decoration: const InputDecoration(
            labelText: 'Type de ciment (mortier)',
            border: OutlineInputBorder(),
          ),
          items: TypeCiment.defaults
              .map((c) => DropdownMenuItem(value: c, child: Text(c.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _typeCimentMortier = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SacCiment>(
          value: _sacCimentMortier,
          decoration: const InputDecoration(
            labelText: 'Poids sac ciment (mortier)',
            border: OutlineInputBorder(),
          ),
          items: SacCiment.defaults
              .map((s) => DropdownMenuItem(value: s, child: Text(s.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _sacCimentMortier = v);
            _recalculer();
          },
        ),
        DropdownButtonFormField<TypeBrique>(
          value: _typeBrique,
          decoration: const InputDecoration(
            labelText: 'Type de brique',
            border: OutlineInputBorder(),
          ),
          items: TypeBrique.defaults
              .map((b) => DropdownMenuItem(value: b, child: Text(b.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _typeBrique = v);
            _recalculer();
          },
        ),
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
        if (_mortier != null) ...[
          ResultCard(
            valeur: _mortier.valeurPrincipale,
            unite: _mortier.unite,
            designation: _mortier.designation,
            referenceNormative: _mortier.referenceNormative,
            onAddToDevis: () => _add(_mortier, 'gros_oeuvre'),
          ),
          const SizedBox(height: 12),
        ],
        if (_briques != null) ...[
          ResultCard(
            valeur: _briques.valeurPrincipale,
            unite: _briques.unite,
            designation: _briques.designation,
            referenceNormative: _briques.referenceNormative,
            onAddToDevis: () => _add(_briques, 'gros_oeuvre'),
          ),
          const SizedBox(height: 12),
        ],
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
        const SizedBox(height: 12),
        DropdownButtonFormField<TypeAcier>(
          value: _typeAcier,
          decoration: const InputDecoration(
            labelText: 'Type d\'acier',
            border: OutlineInputBorder(),
          ),
          items: TypeAcier.defaults
              .map((a) => DropdownMenuItem(value: a, child: Text(a.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _typeAcier = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SectionType>(
          value: _sectionType,
          decoration: const InputDecoration(
            labelText: 'Section poteau/poutre',
            border: OutlineInputBorder(),
          ),
          items: SectionType.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.libelle)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _sectionType = v);
            _recalculer();
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Longueur poteau/poutre',
          controller: TextEditingController(text: _longueurPoteau.toString()),
          suffix: 'm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _longueurPoteau = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Largeur section',
          controller: TextEditingController(text: _largeurPoteau.toString()),
          suffix: 'm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _largeurPoteau = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Hauteur section',
          controller: TextEditingController(text: _hauteurPoteau.toString()),
          suffix: 'm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _hauteurPoteau = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Diamètre étrier',
          controller: TextEditingController(text: _diametreEtrier.toString()),
          suffix: 'mm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _diametreEtrier = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Pas étrier',
          controller: TextEditingController(text: _pasEtrier.toString()),
          suffix: 'm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _pasEtrier = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
        NumberField(
          label: 'Longueur barre acier',
          controller: TextEditingController(text: _longueurBarre.toString()),
          suffix: 'm',
          onChanged: (value) {
            final parsed = Validators.parsePositive(value);
            if (parsed != null) {
              setState(() => _longueurBarre = parsed);
              _recalculer();
            }
          },
        ),
        const SizedBox(height: 12),
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
