import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:calcul_projet/core/constants/app_colors.dart';
import 'package:calcul_projet/core/utils/responsive.dart';
import 'package:calcul_projet/core/utils/validators.dart';
import 'package:calcul_projet/shared/widgets/app_card.dart';
import 'package:calcul_projet/shared/widgets/chantier_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (prev, next) {
      if (next is AuthAuthenticated) context.go('/');
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: ResponsiveBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Synchronisez vos projets entre mobile et desktop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration:
                              const InputDecoration(labelText: 'Mot de passe'),
                          obscureText: true,
                          validator: (v) =>
                              Validators.required(v, 'Le mot de passe'),
                        ),
                        const SizedBox(height: 20),
                        ChantierButton(
                          label: auth is AuthLoading
                              ? 'Connexion…'
                              : 'Continuer',
                          onPressed: auth is AuthLoading
                              ? null
                              : () {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  ref.read(authProvider.notifier).login(
                                        _email.text,
                                        _password.text,
                                      );
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/auth/register'),
                  child: const Text('Créer un compte'),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Continuer hors-ligne'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _cgu = false;

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (prev, next) {
      if (next is AuthAuthenticated) context.go('/');
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inscription')),
      body: ResponsiveBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              children: [
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nom,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (v) => Validators.required(v, 'Le nom'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration:
                              const InputDecoration(labelText: 'Mot de passe'),
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _cgu,
                          onChanged: (v) => setState(() => _cgu = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'J\'accepte les ',
                                style: TextStyle(fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/auth/cgu'),
                                child: const Text(
                                  'CGU',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                ' (résultats indicatifs).',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        ChantierButton(
                          label: auth is AuthLoading
                              ? 'Création…'
                              : 'Créer mon compte',
                          onPressed: auth is AuthLoading
                              ? null
                              : () {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  if (!_cgu) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Veuillez accepter les CGU.'),
                                      ),
                                    );
                                    return;
                                  }
                                  ref.read(authProvider.notifier).register(
                                        email: _email.text,
                                        password: _password.text,
                                        nom: _nom.text,
                                        cgu: _cgu,
                                      );
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
