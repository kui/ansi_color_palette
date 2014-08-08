library ansi_color_palette;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:color_palette/color_palette.dart';
import 'package:color_palette/color_palette_cell.dart';
import 'ansi_color_code.dart';
import 'palette_container.dart';

@CustomTag('ansi-color-palette')
class AnsiColorPaletteElement extends PolymerElement implements PaletteContainer {

  @published
  String colorSpace = '8';

  final StreamController<AnsiColorChangeEvent> _ansiColorChangeStreamController =
      new StreamController.broadcast();

  MutationObserver _containerObserver;
  AnsiColorCode _ansiCode;

  AnsiColorPaletteElement.created() : super.created();

  @override
  ready() {
    _containerObserver = new MutationObserver(_handleContainerMutation);
  }

  @override
  attached() {
    _initPalette(_container);
    _containerObserver.observe(shadowRoot, childList: true);
  }

  @override
  detached() {
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

  AnsiColorCode get ansiCode => _ansiCode;
  set ansiCode(AnsiColorCode code) {
    _ansiCode = code;
    if (_container != null) _container.ansiCode = ansiCode;
  }

  PaletteContainer get _container => shadowRoot.querySelector(
      'color8-palette,color16-palette,color256-palette');

  @override
  Stream<AnsiColorChangeEvent> get onColorChange =>
      _ansiColorChangeStreamController.stream;

  // delegate to _paletteContainer
  @override
  ColorPaletteElement get palette => _container.palette;
  @override
  ColorPaletteCellElement get selectedCell => _container.selectedCell;
  @override
  List<ColorPaletteCellElement> get cells => _container.cells;
  @override
  String get color => _container.color;
  @override
  set selectedCell(ColorPaletteCellElement cell) =>
      _container.selectedCell = cell;
  @override
  void cellXCodeChangeHandler(ColorPaletteCellElement cell) =>
      _container.cellXCodeChangeHandler(cell);
  @override
  ColorPaletteCellElement getCellByCode(int code) =>
      _container.getCellByCode(code);
  @override
  select(ColorPaletteCellElement cell) => _container.select(cell);
  @override
  selectByCode(AnsiColorCode code) => _container.selectByCode(code);
  @override
  selectByCodeInt(int code) => _container.selectByCodeInt(code);
  @override
  selectByCodeString(String code) => _container.selectByCodeString(code);
}
