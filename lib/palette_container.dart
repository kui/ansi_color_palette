library ansi_color_palette.palette_conainer;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:color_palette/color_palette.dart';
import 'package:color_palette/color_palette_cell.dart';
import 'ansi_color_code.dart';

abstract class PaletteContainer extends PolymerElement implements ColorPaletteElement {
  static const String X_CODE_ATTR_NAME = 'x-code';

  ColorPaletteElement get palette => shadowRoot == null ?
      null : shadowRoot.querySelector('color-palette');

  @override
  Stream<AnsiColorChangeEvent> get onColorChange =>
      palette.onColorChange.map(convertColorChangeEvnetToAnsi);

  @override
  List<ColorPaletteCellElement> get cells {
    final p = palette;
    return p == null ? null : p.cells;
  }

  @override
  @reflectable
  String get color {
    final p = palette;
    return p == null ? null : p.color;
  }

  @override
  @reflectable
  ColorPaletteCellElement get selectedCell {
    final p = palette;
    return p == null ? null : p.selectedCell;
  }

  @override
  set selectedCell(ColorPaletteCellElement cell) {
    palette.selectedCell = cell;
  }

  @reflectable
  AnsiColorCode get ansiCode => getXCodeAttr(selectedCell);
  set ansiCode(AnsiColorCode code) => selectByCode(code);

  PaletteContainer.created() : super.created();

  @override
  ready() {
    super.ready();
    _initAnsiCodeCells();
    // propagate events of property changes from [palette]
    palette.changes
      .expand((r) => r)
      .where((r) => r is PropertyChangeRecord)
      .listen((PropertyChangeRecord r) {
        notifyPropertyChange(r.name, r.oldValue, r.newValue);

        if (r.name == #selectedCell) {
          notifyPropertyChange(#ansiCode,
              getXCodeAttr(r.oldValue), getXCodeAttr(r.newValue));
        }
      });
  }

  @override
  selectedCellChanged(old) {
    // no-op
  }

  void _initAnsiCodeCells() {
    cells.forEach(cellXCodeChangeHandler);
  }

  void selectByCode(AnsiColorCode code) {
    final cell = (code == null) ? null : getCellByCode(code.code);
    selectedCell = cell;
  }
  void selectByCodeInt(int code) =>
      selectByCode(new AnsiColorCode(code));
  void selectByCodeString(String code) =>
      selectByCode(new AnsiColorCode.fromCodeString(code, radix: 10));

  ColorPaletteCellElement getCellByCode(int code) =>
    cells.firstWhere((c) {
      final attr = c.getAttribute(X_CODE_ATTR_NAME);
      return code == int.parse(attr, radix: 10, onError: (_) => null);
    }, orElse: () => null);
}

AnsiColorCode getXCodeAttr(ColorPaletteCellElement e) {
  if (e == null) return null;
  String a = e.getAttribute(PaletteContainer.X_CODE_ATTR_NAME);
  if (a == null || a.isEmpty) return null;
  return new AnsiColorCode.fromCodeString(a, radix: 10);
}

void cellXCodeChangeHandler(ColorPaletteCellElement cell) {
  final code = getXCodeAttr(cell);
  if (code == null) {
    cell
        ..color = ''
        ..title = '';
  } else {
    final rgb = code.color;
    cell
        ..color = rgb
        ..title = 'code:${code.code}, ${rgb}'
        ..style.color = getFontColor(rgb)
        ..style.textStrokeColor = 'transparent';
  }
}

// See http://www.w3.org/TR/AERT#color-contrast
String getFontColor(String bgColor) {
  final c = new Rgb.fromColorString(bgColor);
  return FONT_COLORS
      .firstWhere((f) => (f.lightness - c.lightness).abs() > 125)
      .toString();
}

const List<Rgb> FONT_COLORS =
  const [const Rgb(255, 255, 255), const Rgb(0, 0, 0)];

class Rgb {
  static final colorPickerElement = new CanvasElement(width: 1, height: 1);
  static final colorPicker = colorPickerElement.getContext('2d');

  final int red, green, blue;
  final double lightness;

  const Rgb(int red, int green, int blue) :
    this.red = red,
    this.green = green,
    this.blue = blue,
    this.lightness = (red * 299 + green * 587 + blue * 114) / 1000;

  factory Rgb.fromColorString(String color) {
    colorPicker.fillStyle = color;
    colorPicker.fillRect(0, 0, 1, 1);
    final d = colorPicker.getImageData(0, 0, 1, 1).data;
    return new Rgb(d[0], d[1], d[2]);
  }

  @override
  toString() => 'rgb($red,$green,$blue)';
}

AnsiColorChangeEvent convertColorChangeEvnetToAnsi(ColorChangeEvent e) =>
    new AnsiColorChangeEvent.fromColorChangeEvent(e);

class AnsiColorChangeEvent implements ColorChangeEvent {
  final ColorPaletteCellElement newCell;
  @override
  String get newColor => (newCode == null) ? null : newCode.color;
  final AnsiColorCode newCode;

  final ColorPaletteCellElement oldCell;
  @override
  String get oldColor => (oldCode == null) ? null : oldCode.color;
  final AnsiColorCode oldCode;

  AnsiColorChangeEvent({
    this.newCell, this.newCode,
    this.oldCell, this.oldCode});

  factory AnsiColorChangeEvent.fromColorChangeEvent(ColorChangeEvent e) =>
    new AnsiColorChangeEvent(
        newCell: e.newCell, newCode: getXCodeAttr(e.newCell),
        oldCell: e.oldCell, oldCode: getXCodeAttr(e.oldCell));
}
