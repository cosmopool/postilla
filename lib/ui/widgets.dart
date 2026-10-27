// Componentes do design system (docs/design/components-shared.md) usados por
// mais de uma tela.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../strings.dart';
import 'icons.dart';
import 'theme.dart';

/// Toque com fundo de pressão e anel de foco, sem splash. Base de todos os botões.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 999,
    this.color,
    this.hoverColor,
    this.pressedColor,
    this.semanticLabel,
    this.selected,
    this.button = true,
    this.scaleOnPress = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color? color, hoverColor, pressedColor;
  final String? semanticLabel;
  final bool? selected;
  final bool button;
  final bool scaleOnPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false, _hover = false, _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final enabled = widget.onTap != null;
    final bg = !enabled
        ? widget.color
        : _pressed
        ? (widget.pressedColor ?? t.surface2)
        : _hover
        ? (widget.hoverColor ?? t.surface)
        : widget.color;
    final radius = BorderRadius.circular(widget.radius);
    Widget box = AnimatedContainer(
      duration: Motion.of(context, Motion.fast),
      curve: Motion.standard,
      decoration: BoxDecoration(color: bg ?? const Color(0x00000000), borderRadius: radius),
      child: widget.child,
    );
    if (widget.scaleOnPress) {
      box = AnimatedScale(scale: _pressed ? 0.98 : 1, duration: Motion.of(context, Motion.instant), child: box);
    }
    return Semantics(
      button: widget.button,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: CustomPaint(foregroundPainter: _focus ? _FocusRing(t.focus, widget.radius) : null, child: box),
        ),
      ),
    );
  }
}

class _FocusRing extends CustomPainter {
  _FocusRing(this.color, this.radius);
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).inflate(3), Radius.circular(radius + 3));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FocusRing old) => old.color != color;
}

/// Botão de ícone 44×44 (glifo 24). `selected` pinta o disco de tinta.
class IconBtn extends StatelessWidget {
  const IconBtn(this.glyph, {super.key, required this.label, this.onTap, this.selected = false, this.filled = false, this.child});
  final Glyphs glyph;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool filled;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final fg = onTap == null ? t.inkFaint : (selected ? t.onInk : t.ink);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected ? true : null,
      color: selected ? t.ink : (filled ? t.surface : null),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg),
            child: child ?? Glyph(glyph, color: fg),
          ),
        ),
      ),
    );
  }
}

enum BtnKind { primary, secondary, ghost }

class Btn extends StatelessWidget {
  const Btn(this.text, {super.key, this.onTap, this.kind = BtnKind.primary, this.small = false, this.block = false, this.glyph});
  final String text;
  final VoidCallback? onTap;
  final BtnKind kind;
  final bool small;
  final bool block;
  final Glyphs? glyph;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final enabled = onTap != null;
    final (bg, fg, border) = switch (kind) {
      _ when !enabled => (
        kind == BtnKind.primary ? t.surface2 : null,
        t.inkFaint,
        kind == BtnKind.secondary ? t.ruleStrong : null,
      ),
      BtnKind.primary => (t.ink, t.onInk, null),
      BtnKind.secondary => (null, t.ink, t.ink),
      BtnKind.ghost => (null, t.ink, null),
    };
    final style = (small ? T.smallMedium : T.button).copyWith(color: fg);
    final content = Container(
      constraints: BoxConstraints(minHeight: small ? 36 : 48),
      padding: EdgeInsets.symmetric(horizontal: kind == BtnKind.ghost || small ? 16 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (glyph != null) ...[Glyph(glyph!, size: 20, color: fg), const SizedBox(width: 8)],
          Flexible(
            child: Text(text, style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    return Padding(
      // Alvo de toque de 44 nos botões pequenos.
      padding: EdgeInsets.symmetric(vertical: small ? 4 : 0),
      child: Pressable(
        onTap: onTap,
        color: bg,
        hoverColor: kind == BtnKind.primary ? Color.lerp(t.ink, t.bg, 0.14) : t.surface,
        pressedColor: kind == BtnKind.primary ? Color.lerp(t.ink, t.bg, 0.24) : t.surface2,
        scaleOnPress: true,
        child: content,
      ),
    );
  }
}

/// Chip de filtro (32 de altura, alvo de 44). Selecionado: tinta.
class FilterChipBtn extends StatelessWidget {
  const FilterChipBtn(this.text, {super.key, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        color: selected ? t.ink : null,
        hoverColor: selected ? t.ink : t.surface,
        pressedColor: selected ? Color.lerp(t.ink, t.bg, 0.2) : t.surface2,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? t.ink : t.ruleStrong),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(text, style: T.smallMedium.copyWith(color: selected ? t.onInk : t.ink), maxLines: 1),
          ),
        ),
      ),
    );
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key, required this.name});
  final int level; // 1…4
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final i = (level - 1).clamp(0, 3);
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.levelBg[i], borderRadius: BorderRadius.circular(999)),
      child: Text(name, style: T.label.copyWith(color: t.levelInk[i], letterSpacing: 0.44)),
    );
  }
}

class MicroLabel extends StatelessWidget {
  const MicroLabel(this.text, {super.key, this.header = false});
  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) => Semantics(
    header: header,
    child: Text(text.toUpperCase(), style: T.label.copyWith(color: context.tk.inkMuted)),
  );
}

/// Controle segmentado: grupo com rótulo, cada opção é um toggle selecionado.
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.label, required this.options, required this.selected, required this.onSelect});
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Pressable(
                  onTap: () => onSelect(i),
                  selected: i == selected,
                  color: i == selected ? t.bg : null,
                  hoverColor: i == selected ? t.bg : t.surface,
                  pressedColor: i == selected ? t.bg : t.surface,
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: i == selected
                        ? BoxDecoration(
                            color: t.bg,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(color: const Color(0x0D181713), blurRadius: 2, offset: const Offset(0, 1)),
                              BoxShadow(color: const Color(0x0F181713), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          )
                        : null,
                    child: Text(
                      options[i],
                      style: T.smallMedium.copyWith(color: i == selected ? t.ink : t.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Campo de busca em pílula, com lupa e "Limpar busca" quando há texto.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.autofocus = false,
    this.italian = false,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool italian;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final style = T.body.copyWith(color: t.ink);
    return CustomPaint(
      foregroundPainter: _focus.hasFocus ? _FocusRing(t.focus, 999) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Glyph(Glyphs.search, size: 20, color: t.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                style: style,
                cursorColor: t.ink,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: style.copyWith(color: t.inkFaint),
                  semanticCounterText: '',
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              IconBtn(
                Glyphs.x,
                label: ui.clearSearch,
                onTap: () {
                  widget.controller.clear();
                  _focus.requestFocus();
                },
                child: Glyph(Glyphs.x, size: 20, color: t.ink),
              )
            else
              const SizedBox(width: 12, height: 44),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho de seção: rótulo + contagem, com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.count, this.action});
  final String label;
  final int? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MicroLabel(label, header: true),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: T.meta.copyWith(color: t.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
          const Spacer(),
          if (action != null) Transform.translate(offset: const Offset(16, 0), child: action),
        ],
      ),
    );
  }
}

/// Linha de lista (compacta: 44; normal: 64).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.meta,
    this.value,
    this.glyph,
    this.onTap,
    this.compact = false,
    this.titleWidget,
    this.italian = false,
  });
  final String title;
  final String? meta;
  final String? value;
  final Glyphs? glyph;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? titleWidget;
  final bool italian;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Pressable(
        onTap: onTap,
        radius: 14,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 44 : 64),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (glyph != null) ...[Glyph(glyph!, size: 20, color: t.inkMuted), const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleWidget ?? Text(title, style: (compact ? T.body : T.rowTitle).copyWith(color: t.ink)),
                    if (meta != null && meta!.isNotEmpty)
                      Text(
                        meta!,
                        style: T.meta.copyWith(color: t.inkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Text(value!, style: T.small.copyWith(color: t.inkMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.glyph, required this.title, this.text, this.action});
  final Glyphs glyph;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: t.surface, shape: BoxShape.circle),
            child: Center(child: Glyph(glyph, color: t.inkMuted)),
          ),
          Text(
            title,
            style: T.button.copyWith(color: t.ink),
            textAlign: TextAlign.center,
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                text!,
                style: T.small.copyWith(color: t.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (action != null) Padding(padding: const EdgeInsets.only(top: 12), child: action),
        ],
      ),
    );
  }
}

/// App bar compacta (56): voltar · título · ações. Hairline quando rolada.
class CompactBar extends StatelessWidget {
  const CompactBar({
    super.key,
    this.backLabel,
    this.title = '',
    this.titleVisible = true,
    this.scrolled = false,
    this.actions = const [],
    this.italianTitle = false,
  });
  final String? backLabel;
  final String title;
  final bool titleVisible;
  final bool scrolled;
  final List<Widget> actions;
  final bool italianTitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: scrolled ? t.rule : t.bg)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: backLabel == null
                ? null
                : IconBtn(Glyphs.chevronLeft, label: backLabel!, onTap: () => Navigator.of(context).maybePop()),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: AnimatedOpacity(
              opacity: titleVisible ? 1 : 0,
              duration: Motion.of(context, Motion.fast),
              child: Text(
                title,
                style: T.button.copyWith(color: t.ink),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Row(mainAxisSize: MainAxisSize.min, children: actions.isEmpty ? [const SizedBox(width: 44)] : actions),
        ],
      ),
    );
  }
}

/// Toast: aviso rápido, 2,6 s, anunciado sem mover o foco.
void showToast(BuildContext context, String text) {
  final overlay = Overlay.of(context, rootOverlay: true);
  SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context));
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _Toast(text: text, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.text, required this.onDone});
  final String text;
  final VoidCallback onDone;
  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _shown = true) : null);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _shown = false);
      Future.delayed(Motion.base, widget.onDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Positioned(
      left: 20,
      right: 20,
      bottom: bottom + 56,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, 0.2),
          duration: Motion.of(context, Motion.base),
          curve: Motion.standard,
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: Motion.of(context, Motion.base),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: t.ink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x24181713), blurRadius: 32, offset: Offset(0, 10))],
              ),
              child: Text(
                widget.text,
                style: T.small.copyWith(color: t.onInk, decoration: TextDecoration.none),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Push: a página nova entra da direita e a de baixo recua um terço e continua
/// montada (guarda a rolagem). Sobre a rota do Cupertino para ganhar o gesto de
/// borda nas duas plataformas, com a duração do design (`--dur-base`).
class PushRoute<R> extends CupertinoPageRoute<R> {
  PushRoute(Widget page, {super.settings}) : super(builder: (_) => page);

  @override
  Duration get transitionDuration => Motion.base;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}

/// Copia texto para a área de transferência e avisa.
Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, ui.copied);
}
