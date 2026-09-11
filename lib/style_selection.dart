/// Choices carried from onboarding into the try-on catalogue.
class StyleSelection {
  const StyleSelection({
    this.gender = 'femme',
    this.english = false,
    this.style = 'Marocain',
  });

  final String gender;
  final bool english;
  final String style;
}
