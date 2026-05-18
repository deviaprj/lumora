import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../data/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _busy = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  void _showFirebaseUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase non configuré sur ce build. Utilise "Jouer anonymement" en attendant.'),
      ),
    );
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) {
        return;
      }
      context.go('/home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.message ?? 'Erreur d\'authentification.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openEmailDialog() async {
    if (!_firebaseReady) {
      _showFirebaseUnavailableMessage();
      return;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmailSignupDialog(authService: _authService),
    );

    if ((success ?? false) && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LumoraGradients.authBg,
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const _LogoWithParticles(),
                  const SizedBox(height: 20),
                  Text(
                    'Lumora',
                    style: LumoraTextStyles.displayLarge(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecte-toi pour sauvegarder ta lumière',
                    textAlign: TextAlign.center,
                    style: LumoraTextStyles.bodyMedium(),
                  ),
                  const SizedBox(height: 36),
                  _AuthBubble(
                    label: 'Continuer avec Google',
                    icon: Icons.g_mobiledata_rounded,
                    colors: const [Color(0xFFEA4335), Color(0xFFFBBC05)],
                    enabled: !_busy,
                    onTap: () {
                      if (!_firebaseReady) {
                        _showFirebaseUnavailableMessage();
                        return;
                      }
                      _runAuth(() async {
                      await _authService.signInWithGoogle();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AuthBubble(
                    label: 'Continuer avec Apple',
                    icon: Icons.apple_rounded,
                    colors: const [Color(0xFF555555), Color(0xFFBBBBBB)],
                    enabled: !_busy,
                    onTap: () {
                      if (!_firebaseReady) {
                        _showFirebaseUnavailableMessage();
                        return;
                      }
                      _runAuth(() async {
                      await _authService.signInWithApple();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AuthBubble(
                    label: 'Continuer avec Facebook',
                    icon: Icons.facebook_rounded,
                    colors: const [Color(0xFF1877F2), Color(0xFF0D47A1)],
                    enabled: !_busy,
                    onTap: () {
                      if (!_firebaseReady) {
                        _showFirebaseUnavailableMessage();
                        return;
                      }
                      _runAuth(() async {
                      await _authService.signInWithFacebook();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AuthBubble(
                    label: 'Créer un compte avec Email',
                    icon: Icons.email_rounded,
                    colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
                    enabled: !_busy,
                    onTap: _openEmailDialog,
                  ),
                  const SizedBox(height: 12),
                  _AuthBubble(
                    label: 'Jouer anonymement',
                    icon: Icons.person_outline_rounded,
                    colors: [LumoraColors.twilight, LumoraColors.dawn],
                    enabled: !_busy,
                    onTap: () {
                      if (!_firebaseReady) {
                        context.go('/home');
                        return;
                      }
                      _runAuth(() async {
                        await _authService.signInAnonymously();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_busy)
                    const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  LumoraButton(
                    onPressed: _busy ? null : () => context.go('/home'),
                    text: 'Retour',
                    gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                    elevation: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailSignupDialog extends StatefulWidget {
  const _EmailSignupDialog({required this.authService});

  final AuthService authService;

  @override
  State<_EmailSignupDialog> createState() => _EmailSignupDialogState();
}

class _EmailSignupDialogState extends State<_EmailSignupDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _loading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  String? _verificationToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _showMessage('Saisis un email valide et un mot de passe (6+ caractères).');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await widget.authService.requestEmailVerificationCode(email: email);
      if (!mounted) {
        return;
      }

      if (result.emailAlreadyExists) {
        _showMessage('Cet email existe déjà. Connecte-toi avec email/mot de passe.');
        return;
      }

      if (!result.sent) {
        _showMessage(result.message ?? 'Impossible d\'envoyer le code.');
        return;
      }

      setState(() => _codeSent = true);
      _showMessage('Code envoyé. Vérifie ta boîte mail.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Erreur Firebase.');
    } catch (error) {
      _showMessage('Erreur: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showMessage('Le code doit contenir 6 chiffres.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await widget.authService.verifyEmailCode(email: email, code: code);
      if (!mounted) {
        return;
      }

      if (!result.verified || result.verificationToken == null) {
        _showMessage(result.message ?? 'Code invalide.');
        return;
      }

      setState(() {
        _codeVerified = true;
        _verificationToken = result.verificationToken;
      });
      _showMessage('Email validé. Tu peux créer le compte.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Erreur Firebase.');
    } catch (error) {
      _showMessage('Erreur: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createAccount() async {
    final token = _verificationToken;
    if (!_codeVerified || token == null) {
      _showMessage('Valide d\'abord le code reçu par email.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.authService.finalizeEmailSignup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        verificationToken: token,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Erreur Firebase.');
    } catch (error) {
      _showMessage('Erreur: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loginExistingAccount() async {
    setState(() => _loading = true);
    try {
      await widget.authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Connexion impossible.');
    } catch (error) {
      _showMessage('Erreur: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151828),
      title: Text('Compte Email', style: LumoraTextStyles.titleLarge()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Code de validation',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
            if (_codeVerified)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Email validé avec succès.',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _loading ? null : _loginExistingAccount,
          child: const Text('Connexion email'),
        ),
        if (!_codeSent)
          TextButton(
            onPressed: _loading ? null : _requestCode,
            child: const Text('Envoyer code'),
          ),
        if (_codeSent && !_codeVerified)
          TextButton(
            onPressed: _loading ? null : _verifyCode,
            child: const Text('Vérifier code'),
          ),
        if (_codeVerified)
          TextButton(
            onPressed: _loading ? null : _createAccount,
            child: const Text('Créer compte'),
          ),
      ],
    );
  }
}

/// Bulle organique d'authentification — wrapper autour de LumoraButton
/// avec micro-animation flottante.
class _AuthBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool enabled;
  final VoidCallback onTap;

  const _AuthBubble({
    required this.label,
    required this.icon,
    required this.colors,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LumoraButton(
      onPressed: enabled ? onTap : null,
      text: label,
      icon: Icon(icon, color: Colors.white, size: 22),
      gradientColors: colors,
      elevation: 6,
      isFloating: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}

/// Logo Lumora avec particules placeholder.
/// Remplace par un vrai ParticleSystem plus tard.
class _LogoWithParticles extends StatelessWidget {
  const _LogoWithParticles();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bulle principale
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LumoraGradients.primaryBubble,
              boxShadow: [
                LumoraShadows.glow(),
                LumoraShadows.floating(),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bubble_chart_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          // Petites particules placeholder
          Positioned(
            top: 10,
            right: 20,
            child: _ParticleDot(color: LumoraColors.auroraGold),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _ParticleDot(color: LumoraColors.auroraPurple),
          ),
          Positioned(
            top: 40,
            left: 0,
            child: _ParticleDot(color: LumoraColors.auroraPink, size: 6),
          ),
        ],
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ParticleDot({required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(120),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
