import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/calcul_page_scaffold.dart';
import '../../../../shared/widgets/disclaimer_banner.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../projet/presentation/providers/app_session_provider.dart';
import '../../domain/moteur/electricite_engine.dart';

class ElectriciteScreen extends ConsumerStatefulWidget {
  const ElectriciteScreen({super.key});

  @override
  ConsumerState<ElectriciteScreen> createState() => _ElectriciteScreenState();
}

class _ElectriciteScreenState extends ConsumerState<ElectriciteScreen> {
  final _puissance = TextEditingController(text: '3500');
  final _longueur = TextEditingController(text: '25');
  final _surface = TextEditingController(text: '20');
  double _tension = 230;
  bool _cuivre = true;
  String _typePiece = 'chambre';
  dynamic _bilan;
  dynamic _section;
  dynamic _disjoncteur;
  dynamic _points;

  @override
  void initState() {
    super.initState();
    _calculer();
  }

  @override
  void dispose() {
    _puissance.dispose();
    _longueur.dispose();
    _surface.dispose();
    super.dispose();
  }

  void _calculer() {
    final p = Validators.parsePositive(_puissance.text);
    final l = Validators.parsePositive(_longueur.text);
    final s = Validators.parsePositive(_surface.text);
    if (p == null || l == null) return;
    setState(() {
      final circuit = Circuit(
        designation: 'Circuit principal',
        puissanceW: p,
        longueurM: l,
      );
      _bilan = ElectriciteEngine.bilanPuissance(circuits: [circuit]);
      _section = ElectriciteEngine.sectionCable(
        puissanceW: p,
        longueurM: l,
        tensionV: _tension,
        estCuivre: _cuivre,
      );
      _disjoncteur = ElectriciteEngine.calibreDisjoncteur(
        puissanceW: p,
        tensionV: _tension,
      );
      if (s != null) {
        _points = ElectriciteEngine.pointsLumineux(
          typePiece: _typePiece,
          surfaceM2: s,
        );
      }
    });
  }

  void _add(dynamic r) {
    try {
      ref.read(appSessionProvider.notifier).ajouterResultatAuDevis(
            result: r,
            phase: 'finition',
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
    return CalculPageScaffold(
      title: 'Électricité NF C 15-100',
      child: ListView(
        children: [
          NumberField(
            label: 'Puissance',
            controller: _puissance,
            suffix: 'W',
            onChanged: (_) => _calculer(),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: 'Longueur de câble',
            controller: _longueur,
            suffix: 'm',
            onChanged: (_) => _calculer(),
          ),
          const SizedBox(height: 12),
          const Text('Tension nominale', style: TextStyle(fontWeight: FontWeight.w600)),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 230, label: Text('230 V')),
              ButtonSegment(value: 400, label: Text('400 V')),
            ],
            selected: {_tension},
            onSelectionChanged: (s) {
              setState(() => _tension = s.first);
              _calculer();
            },
          ),
          SwitchListTile(
            title: const Text('Conducteur cuivre'),
            subtitle: Text(_cuivre ? 'Cuivre (ρ = 0,0225)' : 'Aluminium (ρ = 0,036)'),
            value: _cuivre,
            onChanged: (v) {
              setState(() => _cuivre = v);
              _calculer();
            },
          ),
          if (_bilan != null)
            ResultCard(
              valeur: _bilan.valeurPrincipale,
              unite: _bilan.unite,
              designation: _bilan.designation,
              referenceNormative: _bilan.referenceNormative,
              onAddToDevis: () => _add(_bilan),
            ),
          const SizedBox(height: 8),
          if (_section != null)
            ResultCard(
              valeur: _section.valeurPrincipale,
              unite: _section.unite,
              designation: _section.designation,
              referenceNormative: _section.referenceNormative,
              onAddToDevis: () => _add(_section),
            ),
          const SizedBox(height: 8),
          if (_disjoncteur != null)
            ResultCard(
              valeur: _disjoncteur.valeurPrincipale,
              unite: _disjoncteur.unite,
              designation: _disjoncteur.designation,
              referenceNormative: _disjoncteur.referenceNormative,
              onAddToDevis: () => _add(_disjoncteur),
            ),
          const Divider(height: 32),
          const Text('Points lumineux / prises', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _typePiece,
            decoration: const InputDecoration(
              labelText: 'Type de pièce',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'sejour', child: Text('Séjour / salon')),
              DropdownMenuItem(value: 'chambre', child: Text('Chambre')),
              DropdownMenuItem(value: 'cuisine', child: Text('Cuisine')),
              DropdownMenuItem(value: 'salle_de_bain', child: Text('Salle de bain')),
              DropdownMenuItem(value: 'wc', child: Text('WC')),
              DropdownMenuItem(value: 'couloir', child: Text('Couloir')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _typePiece = v);
              _calculer();
            },
          ),
          const SizedBox(height: 12),
          NumberField(
            label: 'Surface',
            controller: _surface,
            suffix: 'm²',
            onChanged: (_) => _calculer(),
          ),
          if (_points != null) ...[
            const SizedBox(height: 12),
            ResultCard(
              valeur: _points.valeurPrincipale,
              unite: _points.unite,
              designation: _points.designation,
              referenceNormative: _points.referenceNormative,
              onAddToDevis: () => _add(_points),
            ),
            Text(
              'Prises recommandées : ${(_points.details['prises'] as num).toInt()}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}
