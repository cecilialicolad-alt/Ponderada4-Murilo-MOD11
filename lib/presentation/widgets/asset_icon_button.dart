import 'dart:math';
import 'package:flutter/material.dart';

class AssetIconButton extends StatefulWidget {
  final String asset;
  final String tooltip;
  final VoidCallback? onTap;
  final double height;
  final bool enabled;
  final bool tremble;

  const AssetIconButton({
    super.key,
    required this.asset,
    required this.tooltip,
    this.onTap,
    this.height = 44,
    this.enabled = true,
    this.tremble = false,
  });

  @override
  State<AssetIconButton> createState() => _AssetIconButtonState();
}

class _AssetIconButtonState extends State<AssetIconButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AssetIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.tremble && _c == null) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 130),
      )..repeat(reverse: true);
    } else if (!widget.tremble && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget img = Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset(widget.asset, height: widget.height),
    );
    if (_c != null) {
      img = AnimatedBuilder(
        animation: _c!,
        builder: (context, child) => Transform.translate(
          offset: Offset(sin(_c!.value * 2 * pi) * 2.5, 0),
          child: child,
        ),
        child: img,
      );
    }
    return Tooltip(
      message: widget.tooltip,
      child: InkResponse(
        onTap: widget.onTap,
        radius: 30,
        child: Opacity(opacity: widget.enabled ? 1.0 : 0.4, child: img),
      ),
    );
  }
}
