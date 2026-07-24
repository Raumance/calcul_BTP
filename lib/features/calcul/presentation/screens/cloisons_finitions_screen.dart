import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/calcul_page_scaffold.dart';
import '../../../../shared/widgets/disclaimer_banner.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../projet/presentation/providers/app_session_provider.dart';
import '../../domain/moteur/cloisons_engine.dart';
import '../../domain/moteur/finitions_engine.dart';

class CloisonsFinitionsScreen extends ConsumerStatefulWidget {
  const CloisonsFinitionsScreen({super.key, this.modeFinitions = false});

  final bool modeFinitions;

  @override
  ConsumerState<CloisonsFinitionsScreen> createState() =>
      _CloisonsFinitionsScreenState();
}

class _CloisonsFinitionsScreenState
    extends ConsumerState<CloisonsFinitionsScreen> {
  final _long = TextEditingController(text: '5');
  final _larg = TextEditingController(text: '4');
  final _haut = TextEditingController(text: '2.5');
  double _perte = AppConstants.perteCloisons;
  String _type = 'plaque_platre';
  dynamic _result;

  @override
  void initState() {
    super.initState();
    _calculer();
  }

  @override
  void dispose() {
    _long.dispose();
    _larg.dispose();
    _haut.dispose();
    super.dispose();
  }

  void _calculer() {
    final l = Validators.parsePositive(_long.text);
    final la = Validators.parsePositive(_larg.text);
    final h = Validators.parsePositive(_haut.text);
    if (l == null || la == null || h == null) return;
    setState(() {
      if (widget.modeFinitions) {
        _result = FinitionsEngine.surfacePeinture(
          longueur: l,
          largeur: la,
          hauteur: h,
          coefficientPerte: _perte,
        );
      } else {
        _result = CloisonsEngine.surfaceCloison(
          longueurPiece: l,
          largeurPiece: la,
          hauteurPiece: h,
          typeMateriau: _type,
          coefficientPerte: _perte,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.modeFinitions ? 'Finitions' : 'Cloisons / plafonds';
    return CalculPageScaffold(
      title: title,
      child: ListView(
        children: [
          if (!widget.modeFinitions) ...[
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type de matériau',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'plaque_platre', child: Text('Plaque de plâtre')),
                DropdownMenuItem(value: 'carreaux_platre', child: Text('Carreaux de plâtre')),
                DropdownMenuItem(value: 'alveolaire', child: Text('Cloison alvéolaire')),
                DropdownMenuItem(value: 'placomur', child: Text('Doublage Placomûr')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
                _calculer();
              },
            ),
            const SizedBox(height: 12),
          ],
          NumberField(label: 'Longueur', controller: _long, suffix: 'm', onChanged: (_) => _calculer()),
          const SizedBox(height: 12),
          NumberField(label: 'Largeur', controller: _larg, suffix: 'm', onChanged: (_) => _calculer()),
          const SizedBox(height: 12),
          NumberField(label: 'Hauteur', controller: _haut, suffix: 'm', onChanged: (_) => _calculer()),
          const SizedBox(height: 12),
          PerteSlider(
            value: _perte,
            onChanged: (v) {
              setState(() => _perte = v);
              _calculer();
            },
          ),
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
                        phase: widget.modeFinitions ? 'finition' : 'finition',
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajouté au devis.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
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
