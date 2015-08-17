@HtmlImport('ansi_color_palette.html')
library ansi_color_palette;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:color_palette/color_palette.dart';
import 'package:color_palette/color_palette_cell.dart';
import 'ansi_color_code.dart';
import 'palette_container.dart';

/// this import statements use for [HtmlImport]
import 'color8_palette.dart';
import 'color16_palette.dart';
import 'color256_palette.dart';
forSuppressWarning() {
  Color8PaletteElement;
  Color16PaletteElement;
  Color256PaletteElement;
}

@CustomTag('ansi-color-palette')
class AnsiColorPaletteElement extends PolymerElement implements PaletteContainer {

  @published
  String colorSpace = '8';

  final StreamController<AnsiColorChangeEvent> _ansiColorChangeStreamController =
      new StreamController.broadcast();

  MutationObserver _containerObserver;
  AnsiColorCode _ansiCode;

  AnsiColorCode get ansiCode => _ansiCode;
  set ansiCode(AnsiColorCode code) {
    _ansiCode = code;
    if (_container != null) _container.ansiCode = ansiCode;
  }

  PaletteContainer get _container => (shadowRoot == null) ? null :
      shadowRoot.querySelector(
          'color8-palette,color16-palette,color256-palette');

  AnsiColorPaletteElement.created() : super.created();

  @override
  ready() {
    super.ready();
    _initPalette(_container);
    _containerObserver = new MutationObserver(_handleContainerMutation);
    _containerObserver.observe(shadowRoot, childList: true);
  }

  @override
  detached() {
    super.detached();
    _containerObserver.disconnect();
  }

  _handleContainerMutation(List<MutationRecord> mutations, _) {
    final PaletteContainer newPalette = mutations
        .expand((m) => m.addedNodes)
        .lastWhere((n) => n is PaletteContainer);
    _initPalette(newPalette);
  }

  _initPalette(PaletteContainer p) {
    p
        ..ansiCode = ansiCode
        ..onColorChange.listen((e) {
          _ansiCode = e.newCode;
          _ansiColorChangeStreamController.add(e);
        });

    if (p.selectedCell == null) {
      final e = new AnsiColorChangeEvent(oldCode: _ansiCode);
      _ansiCode = null;
      _ansiColorChangeStreamController.add(e);
    }
  }

  @override
  Stream<AnsiColorChangeEvent> get onColorChange =>
      _ansiColorChangeStreamController.stream;

  // delegate to _paletteContainer
  @override
  ColorPaletteElement get palette =>
      _container == null ? null : _container.palette;
  @override
  ColorPaletteCellElement get selectedCell =>
      _container == null ? null : _container.selectedCell;
  @override
  List<ColorPaletteCellElement> get cells =>
      _container == null ? null : _container.cells;
  @override
  String get color => _container == null ? null : _container.color;
  @override
  set selectedCell(ColorPaletteCellElement cell) {
    if (_container == null) return;
    _container.selectedCell = cell;
  }
  @override
  ColorPaletteCellElement getCellByCode(int code) =>
      _container == null ? null : _container.getCellByCode(code);
  @override
  selectByCode(AnsiColorCode code) =>
      _container == null ? null : _container.selectByCode(code);
  @override
  selectByCodeInt(int code) =>
      _container == null ? null : _container.selectByCodeInt(code);
  @override
  selectByCodeString(String code) =>
      _container == null ? null : _container.selectByCodeString(code);
  @override
  selectedCellChanged(old) { }
}
