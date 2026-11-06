import 'try_on_session.dart';
import 'package:flutter/material.dart';
import 'mobile_layout.dart';
import 'style_selection.dart';

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({
    super.key,
    this.initialEnglish = false,
    this.onSelected,
    this.onBack,
  });
  final bool initialEnglish;
  final void Function(String gender, bool english)? onSelected;
  final VoidCallback? onBack;
  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> {
  late bool english = widget.initialEnglish;
  void choose(String gender) {
    if (widget.onSelected != null) {
      widget.onSelected!(gender, english);
      return;
    }
    TryOnSession.current.selectGender(gender);
    Navigator.pushNamed(
      context,
      '/style',
      arguments: StyleSelection(gender: gender, english: english),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xdde5d5ed)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 650;
                  final wide = constraints.maxWidth > 600;
                  final gap = compact ? 10.0 : 18.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 18),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 6 : 16),
                        SizedBox(
                          height: wide ? 68 : 52,
                          child: Row(
                            children: [
                              _glassControl(
                                child: IconButton(
                                  tooltip: english ? 'Back' : 'Retour',
                                  onPressed:
                                      widget.onBack ??
                                      () => Navigator.maybePop(context),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: digiInk,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Image.asset(
                                    'lib/logo digiwearit.png',
                                    height: wide ? 64 : 42,
                                  ),
                                ),
                              ),
                              _glassControl(
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
                                      horizontal: 10,
                                      vertical: 14,
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
                                          style: const TextStyle(
                                            color: digiInk,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Semantics(
                          label: english
                              ? 'Choose your model, first setup step'
                              : 'Choix du modèle, première étape',
                          child: SizedBox(
                            width: wide ? 300 : 150,
                            child: Row(
                              children: List.generate(
                                4,
                                (index) => Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: index == 0
                                          ? digiGradient
                                          : null,
                                      color: index == 0
                                          ? null
                                          : const Color(0x337b648d),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        Text(
                          english
                              ? 'Who would you like to try an outfit for?'
                              : 'Pour qui souhaitez-vous essayer une tenue ?',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontSize: wide ? 42 : (compact ? 25 : 29),
                            height: 1.12,
                            fontWeight: FontWeight.bold,
                            color: digiInk,
                          ),
                        ),
                        SizedBox(height: gap * .7),
                        Text(
                          english
                              ? 'Choose a model to discover our collection.'
                              : 'Choisissez le modèle pour découvrir notre collection.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color(0xff8b7a9f),
                            fontSize: wide ? 20 : 13,
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _card('femme', wide)),
                              SizedBox(width: wide ? 14 : 10),
                              Expanded(child: _card('homme', wide)),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 18 : 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xffac91bd)),
                            ),
                            Flexible(
                              flex: 6,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'DRESS YOURSELF DIFFERENTLY',
                                    style: TextStyle(
                                      color: const Color(0xffa58bb8),
                                      fontSize: wide ? 12 : 9,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xffac91bd)),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 22 : 48),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _glassControl({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white70, width: 1.2),
    ),
    child: child,
  );

  Widget _card(String gender, bool wide) {
    final female = gender == 'femme';
    final label = female
        ? (english ? 'Women' : 'Femme')
        : (english ? 'Men' : 'Homme');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (female ? const Color(0xffee6acb) : const Color(0xffa5a7f6))
                .withValues(alpha: .3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('universe-$gender'),
          onTap: () => choose(gender),
          child: Semantics(
            label: label,
            button: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/universe_$gender.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.25),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.45, 1],
                      colors: [Colors.transparent, Color(0xdd24182f)],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(wide ? 24 : 14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        width: wide ? 290 : 135,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              female ? Icons.female : Icons.male,
                              color: female
                                  ? const Color(0xffe480f1)
                                  : const Color(0xffc8bfff),
                              size: wide ? 40 : 30,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: const ['serif'],
                                color: Colors.white,
                                fontSize: wide ? 36 : 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    english
                                        ? 'Discover our collection for ${female ? 'women' : 'men'}.'
                                        : 'Découvrez notre collection de tenues pour ${female ? 'femmes' : 'hommes'}.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: .85,
                                      ),
                                      fontSize: wide ? 15 : 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: wide ? 58 : 36,
                                  height: wide ? 58 : 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: female ? digiGradient : null,
                                    color: female ? null : Colors.white30,
                                    border: Border.all(color: Colors.white54),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: female
                            ? const Color(0xfff4aae6)
                            : Colors.white70,
                        width: 1.2,
                      ),
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
