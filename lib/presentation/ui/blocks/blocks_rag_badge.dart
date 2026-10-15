import 'package:flutter/material.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';

/// Pure view data: no provider, model or index access in the locked shell.
class BlocksRagBadge extends StatelessWidget {
  const BlocksRagBadge({super.key, required this.data});
  final BlocksRagStatus data;
  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: data.tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.searching)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  color: c.accent,
                  strokeWidth: 1.2,
                ),
              ),
            ),
          Text(
            'RAG',
            key: const Key('blocks-rag-badge'),
            style: UiText.sans(10, color: data.available ? c.accent : c.muted),
          ),
        ],
      ),
    );
  }
}
