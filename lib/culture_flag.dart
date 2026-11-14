import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

/// A culture's country flag (chosen in the admin) shown on category cards.
class CultureFlag extends StatelessWidget {
  const CultureFlag(this.code, {super.key, this.height = 20});
  final String code;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
    ),
    child: CountryFlag.fromCountryCode(
      code,
      theme: ImageTheme(
        width: height * 1.5,
        height: height,
        shape: const RoundedRectangle(3),
      ),
    ),
  );
}
