library ansi_color_palette.ansi_color_code;

String getColorFromAnsiCode(int code) =>
  new AnsiColorCode(code).color;

class AnsiColorCode {
  static const STANDARD_COLORS =
      const ['rgb(0,0,0)', 'rgb(187,0,0)', 'rgb(0,187,0)', 'rgb(187,187,0)',
             'rgb(0,0,187)', 'rgb(187,0,187)', 'rgb(0,187,187)', 'rgb(187,187,187)',
             'rgb(85,85,85)', 'rgb(255,85,85)', 'rgb(85,255,85)', 'rgb(255,255,85)',
             'rgb(85,85,255)', 'rgb(255,85,255)', 'rgb(85,255,255)', 'rgb(255,255,255)'];
  static const RGB_STEP = 255 / 5;
  static const GRAYSCALE_STEP = 255 / 23;

  final int code;

  const AnsiColorCode.withoutAssertion(this.code);
  AnsiColorCode(this.code) {
    if (code < 0) {
      throw new ArgumentError('"code" is expected to be zero or a positive integer');
    }
    if (code > 255) {
      throw new ArgumentError('"code" is expected less than or equal to 255');
    }
  }
  AnsiColorCode.fromString(String s, {int radix: 10}):
    this(int.parse(s, radix: radix));
  AnsiColorCode.fromRGB(int r, int g, int b): this(r * 36 + g * 6 + b + 16);

  String get color {
    if (code < 16) {
      return _standardColor();
    } else if (code < 232) {
      return _rgbColor();
    } else {
      return _grayscaleColor();
    }
  }

  bool get isStandard => code < 16;
  bool get isRGB => 16 <= code && code < 232;
  bool get isGrayscale => 232 <= code;

  int get redFactor =>   isRGB ? ((code-16)/36).floor() : null;
  int get greenFactor => isRGB ? (((code-16)%36)/6).floor() : null;
  int get blueFactor =>  isRGB ? ((code-16)%6).floor() : null;

  String _standardColor() => STANDARD_COLORS[code];

  String _rgbColor() {
    final base = code - 16;
    final r = _rgbValue(base / 36);
    final gb = base % 36;
    final g = _rgbValue(gb / 6);
    final b = _rgbValue(gb % 6);
    return 'rgb($r,$g,$b)';
  }
  int _rgbValue(num f) => (RGB_STEP * f.floor()).round();

  String _grayscaleColor() {
    final base = code - 232;
    final v = (GRAYSCALE_STEP * base).round();
    return 'rgb($v,$v,$v)';
  }

  @override
  String toString() => 'AnsiColor($code)';

  @override
  bool operator ==(o) => (o is AnsiColorCode) && code == o.code;
}
