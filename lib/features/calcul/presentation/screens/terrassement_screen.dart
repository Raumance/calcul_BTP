import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/calcul_page_scaffold.dart';
import '../../../../shared/widgets/disclaimer_banner.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../projet/presentation/providers/app_session_provider.dart';
import '../../domain/moteur/terrassement_engine.dart';

class TerrassementScreen extends ConsumerStatefulWidget {
  const TerrassementScreen({super.key});

  @override
  ConsumerState<TerrassementScreen> createState() => _TerrassementScreenState();
}

class _TerrassementScreenState extends ConsumerState<TerrassementScreen> {
  final _longueur = TextEditingController(text: '10');
  final _largeur = TextEditingController(text: '8');
  final _profondeur = TextEditingController(text: '0.8');
  TypeSol _typeSol = TypeSol.terreVegetale;
  bool _modeRemblai = false;
  dynamic _result;

  @override
  void dispose() {
    _longueur.dispose();
    _largeur.dispose();
    _profondeur.dispose();
    super.dispose();
  }

  void _calculer() {
    final l = Validators.parsePositive(_longueur.text);
    final la = Validators.parsePositive(_largeur.text);
    final p = Validators.parsePositive(_profondeur.text);
    if (l == null || la == null || p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez des dimensions > 0.')),
      );
      return;
    }
    setState(() {
      _result = _modeRemblai
          ? TerrassementEngine.remblai(
              longueur: l,
              largeur: la,
              hauteur: p,
              typeSol: _typeSol,
            )
          : TerrassementEngine.deblai(
              longueur: l,
              largeur: la,
              profondeur: p,
              typeSol: _typeSol,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculPageScaffold(
      title: 'Terrassement',
      child: ListView(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Déblais'), icon: Icon(Icons.upload)),
              ButtonSegment(value: true, label: Text('Remblais'), icon: Icon(Icons.download)),
            ],
            selected: {_modeRemblai},
            onSelectionChanged: (s) {
              setState(() => _modeRemblai = s.first);
              _calculer();
            },
          ),
          const SizedBox(height: 16),
          NumberField(
            label: 'Longueur',
            controller: _longueur,
            suffix: 'm',
            onChanged: (_) => _calculer(),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: 'Largeur',
            controller: _largeur,
            suffix: 'm',
            onChanged: (_) => _calculer(),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: _modeRemblai ? 'Hauteur' : 'Profondeur',
            controller: _profondeur,
            suffix: 'm',
            onChanged: (_) => _calculer(),
          ),
          const SizedBox(height: 16),
          const Text('Nature du sol', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...TypeSol.defaults.map(
            (sol) => RadioListTile<TypeSol>(
              value: sol,
              groupValue: _typeSol,
              title: Text(sol.libelle),
              subtitle: Text('Foisonnement × ${sol.coefficientFoisonnement}'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _typeSol = v);
                _calculer();
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coefficient : ${_typeSol.coefficientFoisonnement} (modifiable)',
            style: const TextStyle(color: AppColors.muted),
          ),
          Slider(
            value: _typeSol.coefficientFoisonnement,
            min: 1.0,
            max: 2.0,
            divisions: 20,
            label: _typeSol.coefficientFoisonnement.toStringAsFixed(2),
            onChanged: (v) {
              setState(() => _typeSol = _typeSol.copyWith(coefficientFoisonnement: v));
              _calculer();
            },
          ),
          const SizedBox(height: 12),
          if (_result != null)
            ResultCard(
              valeur: _result.valeurPrincipale,
              unite: _result.unite,
              designation: _result.designation,
              referenceNormative: _result.referenceNormative,
              onAddToDevis: () {
                try {
                  ref.read(appSessionProvider.notifier).ajouterResultatAuDevis(
                        result: _result,
                        phase: 'terrassement',
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajouté au devis.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              },
            ),
          const SizedBox(height: 16),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}
