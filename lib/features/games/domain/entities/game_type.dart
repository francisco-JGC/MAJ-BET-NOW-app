enum GameType {
  regular,
  date,
  threeDigit,
  fourDigit,
  multiSorteo;

  static GameType fromKey(String key) {
    switch (key) {
      case 'regular':
        return GameType.regular;
      case 'date':
        return GameType.date;
      case 'three_digit':
        return GameType.threeDigit;
      case 'four_digit':
        return GameType.fourDigit;
      case 'multi_sorteo':
        return GameType.multiSorteo;
      default:
        return GameType.regular;
    }
  }

  String get apiKey {
    switch (this) {
      case GameType.regular:
        return 'regular';
      case GameType.date:
        return 'date';
      case GameType.threeDigit:
        return 'three_digit';
      case GameType.fourDigit:
        return 'four_digit';
      case GameType.multiSorteo:
        return 'multi_sorteo';
    }
  }
}
