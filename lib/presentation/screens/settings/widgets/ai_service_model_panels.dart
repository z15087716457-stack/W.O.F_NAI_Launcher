part of 'ai_service_editor.dart';

extension _ServiceModelPanels on _AiServiceEditorState {
  // Testing disables interaction, but must not recolor the saved selection.
  WidgetStateProperty<Color> _catalogCheckboxFill(ColorScheme colors) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.onSurface
            : Colors.transparent,
      );

  Widget _availablePanel() {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final query = _catalogSearch.text.trim().toLowerCase();
    final filtered = _catalog
        .where(
          (id) => '$id ${_catalogDetails(id)?.name ?? ''}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    final selectedCount = filtered.where(_selected.containsKey).length;
    final bool? allSelected = selectedCount == 0
        ? false
        : selectedCount == filtered.length
        ? true
        : null;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final search = TextField(
      key: const Key('service-catalog-search'),
      controller: _catalogSearch,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 14),
        hintText: context.l10n.modelService_searchModelId,
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 27,
          minHeight: 27,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 28 * scale,
          child: Checkbox(
            key: const Key('service-catalog-select-all'),
            value: allSelected,
            activeColor: colors.onSurface,
            fillColor: _catalogCheckboxFill(colors),
            checkColor: colors.surface,
            tristate: true,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: _busy || filtered.isEmpty
                ? null
                : (_) {
                    final select = allSelected != true;
                    for (final id in filtered) {
                      _toggleModel(id, select);
                    }
                  },
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            context.l10n.modelService_serviceModels,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 7),
        TextButton.icon(
          key: const Key('service-fetch-catalog'),
          onPressed: _canOperate ? _fetchCatalog : null,
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            backgroundColor: colors.surfaceContainerHighest.withValues(
              alpha: .45,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            minimumSize: const Size(0, 28),
            visualDensity: VisualDensity.compact,
            textStyle: theme.textTheme.labelSmall,
          ),
          icon: const Icon(Icons.refresh, size: 13),
          label: Text(context.l10n.modelService_fetchList),
        ),
      ],
    );
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth < 380 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        controls,
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(width: 165 * scale, child: search),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: controls,
                          ),
                        ),
                        SizedBox(width: 165 * scale, child: search),
                      ],
                    ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _catalog.isEmpty
                            ? context.l10n.modelService_catalogEmpty
                            : context.l10n.modelService_noMatchingModels,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: const Key('service-catalog-list'),
                      itemCount: filtered.length,
                      itemExtent: 30 * scale,
                      itemBuilder: (context, index) {
                        final id = filtered[index],
                            selected = _selected.containsKey(id),
                            metadata = _catalogDetails(id);
                        final alias = metadata?.name ?? id;
                        final capacity =
                            metadata?.contextLimit != null ||
                            metadata?.outputLimit != null;
                        String tokens(int? n) =>
                            n == null ? '—' : modelTokenLabel(n);
                        return Semantics(
                          selected: selected,
                          child: Material(
                            color: selected
                                ? colors.onSurface.withValues(alpha: .075)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('catalog-model-$id'),
                              onTap: _busy
                                  ? null
                                  : () => _toggleModel(id, !selected),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: Checkbox(
                                        value: selected,
                                        activeColor: colors.onSurface,
                                        fillColor: _catalogCheckboxFill(colors),
                                        checkColor: colors.surface,
                                        onChanged: _busy
                                            ? null
                                            : (value) => _toggleModel(
                                                id,
                                                value ?? false,
                                              ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Tooltip(
                                        message: alias == id
                                            ? id
                                            : '$id · $alias',
                                        child: Row(
                                          children: [
                                            Flexible(
                                              flex: 2,
                                              child: Text(
                                                id,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                              ),
                                            ),
                                            if (alias != id &&
                                                alias.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  alias,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (capacity) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 84 * scale,
                                        child: Tooltip(
                                          message: context
                                              .l10n
                                              .modelService_catalogLimitTooltip,
                                          child: Text(
                                            '${tokens(metadata!.contextLimit)} · ${tokens(metadata.outputLimit)}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.onSurfaceVariant
                                                      .withValues(alpha: .8),
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorderModels(List<ModelConfig> visible, int from, int to) {
    final ordered = [...visible];
    ordered.insert(to, ordered.removeAt(from));
    final visibleIds = visible.map((m) => m.name).toSet();
    var index = 0;
    final entries = [
      for (final model in _selected.values)
        if (visibleIds.contains(model.name))
          MapEntry(ordered[index].name, ordered[index++])
        else
          MapEntry(model.name, model),
    ];
    _updateOverview(() {
      _selected
        ..clear()
        ..addEntries(entries);
    });
  }

  Widget _selectedPanel() {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final query = _selectedSearch.text.trim().toLowerCase();
    final models = _selected.values
        .where(
          (model) =>
              query.isEmpty ||
              model.name.toLowerCase().contains(query) ||
              model.displayName.toLowerCase().contains(query),
        )
        .toList();
    final search = TextField(
      key: const Key('service-selected-search'),
      controller: _selectedSearch,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 14),
        hintText: context.l10n.modelService_searchAddedModels,
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 27,
          minHeight: 27,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.modelService_modelSettings,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${_selected.length}',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, c) => c.maxWidth < 290 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(width: 165 * scale, child: search),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        title,
                        const Spacer(),
                        SizedBox(width: 165 * scale, child: search),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: models.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? context.l10n.modelService_addedEmpty
                            : context.l10n.modelService_noMatchingModels,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      key: const Key('service-selected-list'),
                      scrollController: _selectedScroll,
                      buildDefaultDragHandles: false,
                      itemCount: models.length,
                      onReorderItem: (from, to) =>
                          _reorderModels(models, from, to),
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 3,
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(7),
                        child: child,
                      ),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey('selected-model-${models[index].name}'),
                        child: _overviewModelRow(
                          models[index],
                          _modelParameters(models[index]),
                          index,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final input = TextField(
                  key: const Key('ai-service-manual-model-id'),
                  controller: _manualId,
                  enabled: !_busy,
                  onSubmitted: (_) => _addManual(),
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: context.l10n.modelService_customModelId,
                    prefixIcon: Tooltip(
                      message: context.l10n.modelService_customModelHelp,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        Icons.help_outline,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 28,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withValues(
                      alpha: .6,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
                final add = TextButton.icon(
                  key: const Key('service-add-custom-model'),
                  onPressed: _busy ? null : _addManual,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    backgroundColor: colors.surfaceContainerHighest.withValues(
                      alpha: .6,
                    ),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(context.l10n.modelService_addCustomModel),
                );
                return c.maxWidth < 340 * scale
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          input,
                          const SizedBox(height: 5),
                          Align(alignment: Alignment.centerRight, child: add),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: input),
                          const SizedBox(width: 8),
                          add,
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelParameters(ModelConfig model) => ModelConfigurationCard(
    key: ValueKey('model-parameters-${model.name}-${_protocol.name}'),
    value: model,
    protocol: _protocol,
    enabled: _canOperate,
    requestDraft: _requestDrafts[model.name],
    onRequestDraftChanged: (draft) =>
        _updateOverview(() => _requestDrafts[model.name] = draft),
    onRequestValidationChanged: (error) =>
        _requestInputErrors[model.name] = error,
    onValidationChanged: (error) => _modelInputErrors[model.name] = error,
    onChanged: (value) => _updateOverview(() {
      _selected[model.name] = value;
    }),
  );
}
