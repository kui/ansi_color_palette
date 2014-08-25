library ansi_color_palette.ansi_color_code;

String getColorFromAnsiCode(int code) => AnsiColorCode.codeToColor[code];
int getAnsiCodeFromColor(String color) => AnsiColorCode.colorToCode[color];

class AnsiColorCode {
  static final List<String> codeToColor =
      new List.generate(256, (code) => _color(code), growable: false);
  static final Map<String, int> colorToCode =
      new Map.fromIterable(codeToColor,
          value: (k) => codeToColor.indexOf(k));

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
  AnsiColorCode.fromCodeString(String s, {int radix: 10}):
    this(int.parse(s, radix: radix));
  AnsiColorCode.fromRGB(int r, int g, int b): this(r * 36 + g * 6 + b + 16);
  AnsiColorCode.fromColorString(String color): this(getAnsiCodeFromColor(color));

  String get color => codeToColor[code];

  bool get isStandard => code < 16;
  bool get isRGB => 16 <= code && code < 232;
  bool get isGrayscale => 232 <= code;

  int get redFactor =>   isRGB ? ((code-16)/36).floor() : null;
  int get greenFactor => isRGB ? (((code-16)%36)/6).floor() : null;
  int get blueFactor =>  isRGB ? ((code-16)%6).floor() : null;

  @override
  String toString() => 'AnsiColor($code)';

  @override
  bool operator ==(o) => (o is AnsiColorCode) && code == o.code;
}

const _STANDARD_COLORS =
    const ['#000', '#c00', '#0c0', '#cc0', '#00c', '#c0c', '#0cc', '#ccc',
           '#666', '#f66', '#6f6', '#ff6', '#66f', '#f6f', '#6ff', '#fff'];
const _RGB_STEP = 255 / 5;
const _GRAYSCALE_STEP = 100 / 23; // lightness: 0% - 100%
String _color(int code) {
  if (code < 16) {
    return _standardColor(code);
  } else if (code < 232) {
    return _rgbColor(code);
  } else {
    return _grayscaleColor(code);
  }
}
String _standardColor(int code) => _STANDARD_COLORS[code];
String _rgbColor(int code) {
  final base = code - 16;
  final r = _rgbValue(base / 36);
  final gb = base % 36;
  final g = _rgbValue(gb / 6);
  final b = _rgbValue(gb % 6);
  return 'rgb($r,$g,$b)';
}
int _rgbValue(num f) => (_RGB_STEP * f.floor()).round();
String _grayscaleColor(int code) {
  final base = code - 232;
  final v = (_GRAYSCALE_STEP * base).round();
  return 'hsl(0,0%,$v%)';
}
