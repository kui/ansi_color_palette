library ansi_color_palette.color256_palette;

import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:color_palette/color_palette_cell.dart';
import 'palette_container.dart';
import 'ansi_color_code.dart';

@CustomTag('color256-palette')
class Color256PaletteElement extends PaletteContainer {
  static const DEFAULT_GRAYSCALE = const AnsiColorCode.withoutAssertion(232);
  static const HUE_CODES = const {
     0: 196,  1: 202,  2: 208,  3: 214,  4: 202, /* red -> yellow */
     5: 226,  6: 190,  7: 154,  8: 118,  9: 082, /* yellow -> green */
    10: 046, 11: 047, 12: 048, 13: 049, 14: 050, /* green -> cyan */
    15: 051, 16: 045, 17: 039, 18: 033, 19: 027, /* cyan -> blue */
    20: 021, 21: 057, 22: 093, 23: 129, 24: 165, /* blue -> magenta */
    25: 201, 26: 200, 27: 199, 28: 198, 29: 197, /* magenta -> red */
    30: 196
  };

  MutationObserver _xCodeObserver;

  final StreamController<AnsiColorChangeEvent> colorChangeController =
      new StreamController.broadcast();
  @override
  Stream<AnsiColorChangeEvent> get onColorChange =>
      colorChangeController.stream;

  @override
  @reflectable
  AnsiColorCode get ansiCode => getXCodeAttr(selectedCell);

  // rgb

  @reflectable
  ColorPaletteCellElement get rgbCell =>
      shadowRoot.querySelector('.rgb-colors color-palette-cell');

  RangeInputElement get redRange => shadowRoot.querySelector('.red-range');
  RangeInputElement get greenRange => shadowRoot.querySelector('.green-range');
  RangeInputElement get blueRange => shadowRoot.querySelector('.blue-range');

  @reflectable
  int redFactor;
  @reflectable
  int greenFactor;
  @reflectable
  int blueFactor;

  @reflectable
  AnsiColorCode rgbCode;
  AnsiColorCode get _rgbCode {
    int r = _getRGBFactor(redRange);
    int g = _getRGBFactor(greenRange);
    int b = _getRGBFactor(blueRange);
    if (r == null || g == null || b == null) return null;
    return new AnsiColorCode.fromRGB(r, g, b);
  }

  // grayscale

  @reflectable
  ColorPaletteCellElement get grayscaleCell =>
      shadowRoot.querySelector('.grayscale-colors color-palette-cell');

  RangeInputElement get grayscaleRange =>
      shadowRoot.querySelector('.grayscale-range');

  @reflectable
  AnsiColorCode grayscaleCode;
  AnsiColorCode get _grayscaleCode {
    String v = grayscaleRange.value;
    if (v == null || v.isEmpty) return DEFAULT_GRAYSCALE;
    return new AnsiColorCode.fromString(v, radix: 10);
  }

  //

  Color256PaletteElement.created() : super.created();

  @override
  ready() {
    super.ready();
    palette.onColorChange
      .map(convertColorChangeEvnetToAnsi)
      .listen(colorChangeController.add);

    changes
      .expand((r) => r)
      .where((r) => r is PropertyChangeRecord)
      .listen((PropertyChangeRecord r) {
        if (r.name == #rgbCode) {
          _notifyCodeChange(rgbCell, r.oldValue, r.newValue);
        } else if (r.name == #grayscaleCode) {
          _notifyCodeChange(grayscaleCell, r.oldValue, r.newValue);
        }
      });

    rgbCell.changes
      .expand((r) => r)
      .where((r) => r is PropertyChangeRecord)
      .listen((PropertyChangeRecord r) {
        if (r.name == #selected) {
          notifyPropertyChange(#rgbCell, r.oldValue, r.newValue);
        }
      });

    grayscaleCell.changes
      .expand((r) => r)
      .where((r) => r is PropertyChangeRecord)
      .listen((PropertyChangeRecord r) {
        if (r.name == #selected) {
          notifyPropertyChange(#grayscaleCell, r.oldValue, r.newValue);
        }
      });
  }

  @override
  attached() {
    super.attached();
    _startXCodeObserver();
    notifyRedChange();
    notifyGreenChange();
    notifyBlueChange();
    notifyGrayScaleChange();
  }

  @override
  detached() {
    super.detached();
    _xCodeObserver.disconnect();
  }

  @override
  selectByCode(AnsiColorCode code) {
    final c = code.code;
    if (code.isStandard) {
      super.selectByCode(code);
    } else if (code.isRGB) {
      select(rgbCell);
      redRange.value = code.redFactor.toString();
      greenRange.value = code.greenFactor.toString();
      blueRange.value = code.blueFactor.toString();
      notifyRedChange();
      notifyGreenChange();
      notifyBlueChange();
    } else { // if code.isGrayscale
      select(grayscaleCell);
      grayscaleRange.value = c.toString();
      notifyGrayScaleChange();
    }
  }

  void notifyRedChange() {
    final oldFactor = redFactor;
    final newFactor = _getRGBFactor(redRange);
    if (oldFactor == newFactor) return;

    redFactor = newFactor;
    notifyPropertyChange(#redFactor, oldFactor, newFactor);
    _notifyRGBChange();
  }
  void notifyGreenChange() {
    final oldFactor = greenFactor;
    final newFactor = _getRGBFactor(greenRange);
    if (oldFactor == newFactor) return;

    greenFactor = newFactor;
    notifyPropertyChange(#greenFactor, oldFactor, newFactor);
    _notifyRGBChange();
  }
  void notifyBlueChange() {
    final oldFactor = blueFactor;
    final newFactor = _getRGBFactor(blueRange);
    if (oldFactor == newFactor) return;

    blueFactor = newFactor;
    notifyPropertyChange(#blueFactor, oldFactor, newFactor);
    _notifyRGBChange();
  }

  void _notifyRGBChange() {
    final oldCode = rgbCode;
    final newCode = _rgbCode;
    if (oldCode == newCode) return;

    rgbCode = newCode;
    notifyPropertyChange(#rgbCode, oldCode, newCode);
  }

  void notifyGrayScaleChange() {
    final oldCode = grayscaleCode;
    final newCode = _grayscaleCode;
    if (oldCode == newCode) return;

    grayscaleCode = newCode;
    notifyPropertyChange(#grayscaleCode, oldCode, newCode);
  }

  int _getRGBFactor(RangeInputElement e) =>
      int.parse(e.value, radix: 10, onError: (_) => null);

  void _notifyCodeChange(ColorPaletteCellElement cell, AnsiColorCode oldCode, AnsiColorCode newCode) {
    if (oldCode == newCode) return;
    async((_) {
      if (!cell.selected) return;
      colorChangeController.add(new AnsiColorChangeEvent(
        oldCell: cell, oldCode: oldCode,
        newCell: cell, newCode: newCode
      ));
      notifyPropertyChange(#ansiCode, oldCode, newCode);
    });
  }

  void _startXCodeObserver() {
    if (_xCodeObserver == null) {
      _xCodeObserver = new MutationObserver(_xCodeMutationHandler);
    }

    _xCodeObserver.observe(rgbCell, attributes: true,
        attributeFilter: [PaletteContainer.X_CODE_ATTR_NAME]);
    _xCodeObserver.observe(grayscaleCell, attributes: true,
        attributeFilter: [PaletteContainer.X_CODE_ATTR_NAME]);
  }

  void _xCodeMutationHandler(List<MutationRecord> mutations, _) {
    mutations
      .where((m) => m.attributeName == PaletteContainer.X_CODE_ATTR_NAME)
      .where((m) => m.target != null)
      .forEach((m) {
        cellXCodeChangeHandler(m.target);
      });
  }
}
