import 'try_on_session.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'experience_session.dart';
import 'mobile_layout.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool english = false;
  void open(bool partner) {
    TryOnSession.current.reset();
    if (!partner) ExperienceSession.personal();
    Navigator.pushNamed(
      context,
      partner ? '/partner' : '/universe',
      arguments: english,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, viewport) {
        final compact = viewport.maxHeight < 650;
        final wide = viewport.maxWidth > 600;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
            Positioned.fill(
              bottom: viewport.maxHeight * .16,
              child: Image.asset(
                'assets/universe_femme.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.3),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xffe5d4e8),
                    Color(0xe6e5d4e8),
                    Color(0x00e5d4e8),
                    Color(0x00e5d4e8),
                    Color(0xffe5d4e8),
                  ],
                  stops: [0, .17, .39, .69, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 44 : 24,
                          compact ? 6 : 14,
                          wide ? 44 : 24,
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  'lib/logo digiwearit.png',
                                  width: wide ? 260 : 170,
                                  height: wide ? 66 : 46,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white30,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 1.3,
                                ),
                              ),
                              child: PopupMenuButton<bool>(
                                tooltip: english ? 'Language' : 'Langue',
                                initialValue: english,
                                onSelected: (value) =>
                                    setState(() => english = value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: false,
                                    child: Text('Français'),
                                  ),
                                  PopupMenuItem(
                                    value: true,
                                    child: Text('English'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.language,
                                        size: 20,
                                        color: digiInk,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        english ? 'EN' : 'FR',
                                        style: const TextStyle(color: digiInk),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: digiInk,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 30),
                      Text(
                        english
                            ? 'AI VIRTUAL TRY-ON'
                            : 'ESSAYAGE VIRTUEL PAR IA',
                        style: TextStyle(
                          color: const Color(0xff9783ac),
                          letterSpacing: 3,
                          fontSize: wide ? 13 : 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                          english
                              ? 'Discover outfits that feel like you'
                              : 'Découvrez des tenues\nqui vous ressemblent',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontWeight: FontWeight.bold,
                            color: digiInk,
                            height: 1.1,
                            fontSize: wide ? 44 : (compact ? 25 : 30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          english
                              ? 'Tradition, modernity and innovation.\nTry it on in an instant.'
                              : 'Tradition, modernité et innovation,\nessayez en un instant.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color(0xff9783ac),
                            fontSize: wide ? 20 : 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!compact)
                                Text(
                                  'Try\nYour Next\nLook ♡',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontFamilyFallback: const ['serif'],
                                    fontStyle: FontStyle.italic,
                                    fontSize: wide ? 30 : 19,
                                    color: Colors.white,
                                    height: 1.25,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              if (!compact)
                                Text(
                                  'TRADITION\nMEETS\nTOMORROW\n——',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 3,
                                    height: 2,
                                    fontSize: wide ? 13 : 9,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xffeaddeb,
                                ).withValues(alpha: .83),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white70),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                wide ? 30 : 16,
                                compact ? 14 : 20,
                                wide ? 30 : 16,
                                compact ? 14 : 26,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _action(partner: false),
                                  const SizedBox(height: 10),
                                  _action(partner: true),
                                  SizedBox(height: compact ? 14 : 24),
                                  Row(
                                    children: [
                                      _benefit(
                                        Icons.auto_awesome_outlined,
                                        english
                                            ? 'Realistic try-on'
                                            : 'Essayage réaliste',
                                      ),
                                      Container(
                                        width: 1,
                                        height: 28,
                                        color: const Color(0x229783ac),
                                      ),
                                      _benefit(
                                        Icons.verified_user_outlined,
                                        english
                                            ? 'Simple and secure'
                                            : 'Simple et sécurisé',
                                      ),
                                      Container(
                                        width: 1,
                                        height: 28,
                                        color: const Color(0x229783ac),
                                      ),
                                      _benefit(
                                        Icons.favorite_border,
                                        english
                                            ? 'Fashion for everyone'
                                            : 'Mode pour tous',
                                      ),
                                    ],
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 26),
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '—  DRESS YOURSELF DIFFERENTLY  —',
                                        style: TextStyle(
                                          color: Color(0xffaa92ba),
                                          letterSpacing: 3,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _action({required bool partner}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: partner ? null : digiGradient,
      border: partner
          ? Border.all(color: const Color(0xff85729f), width: 1.2)
          : null,
      borderRadius: BorderRadius.circular(22),
    ),
    child: TextButton(
      key: ValueKey(partner ? 'partner-start' : 'personal-start'),
      onPressed: () => open(partner),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(0, 54),
        foregroundColor: partner ? digiInk : Colors.white,
      ),
      child: Row(
        children: [
          Icon(partner ? Icons.storefront_outlined : Icons.checkroom, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              partner
                  ? (english ? 'Partner space' : 'Espace partenaire')
                  : (english ? 'Start your try-on' : 'Commencer l’essayage'),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 24),
        ],
      ),
    ),
  );

  Widget _benefit(IconData icon, String label) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: digiInk, size: 23),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(color: digiInk, fontSize: 10),
        ),
      ],
    ),
  );
}
