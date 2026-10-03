part of 'ai_service_editor.dart';

extension _ServiceOverview on _AiServiceEditorState {
  Widget _buildServiceOverview(BuildContext context, bool dirty) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, viewport) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final title = Row(
                      children: [
                        const SizedBox(width: 16),
                        ProviderLogo(_preset, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name.text.trim().isEmpty
                                    ? context.l10n.modelSettings_addProvider
                                    : _name.text.trim(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${context.l10n.modelService_enabledModels(_selected.length)} · ${dirty ? context.l10n.modelService_pendingSave : context.l10n.modelService_saved}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    final actions = _serviceActions(constraints.maxWidth);
                    return constraints.maxWidth <
                            650 * MediaQuery.textScalerOf(context).scale(1)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              title,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 16),
                              // Longer translations wrap the actions instead of
                              // squeezing the service name.
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * .6,
                                ),
                                child: actions,
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, bodyViewport) => SingleChildScrollView(
                key: const Key('service-overview-scroll'),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (_error != null || _catalogMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error ?? _catalogMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _error == null
                                  ? colors.onSurfaceVariant
                                  : colors.error,
                            ),
                          ),
                        ),
                      ),
                    _connectionOverview(context),
                    const SizedBox(height: 16),
                    _modelsOverview(
                      context,
                      viewport.maxHeight.clamp(320.0, 460.0),
                    ),
                    const SizedBox(height: 24),
                    _usageOverview(context),
                    const SizedBox(height: 18),
                    _advancedOverview(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceActions(double availableWidth) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final compact =
        availableWidth < 440 * MediaQuery.textScalerOf(context).scale(1);
    Widget separator() => SizedBox(
      height: 22,
      child: VerticalDivider(width: 12, color: colors.outlineVariant),
    );
    return Material(
      key: const Key('service-actions'),
      color: colors.onSurface.withValues(alpha: .035),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.modelService_enable,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 7),
                  SettingsToggle(
                    key: const Key('service-enabled'),
                    value: _enabled,
                    onChanged: _busy
                        ? null
                        : (value) => _updateOverview(() => _enabled = value),
                  ),
                ],
              ),
            ),
            if (!compact) separator(),
            TextButton.icon(
              key: const Key('service-test'),
              onPressed: _canOperate ? _testModel : null,
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurface,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: serviceControlRadius,
                ),
              ),
              icon: const Icon(Icons.power_outlined, size: 15),
              label: Text(context.l10n.modelService_testConnection),
            ),
            _saveButton(),
            if (widget.provider != null && widget.onDelete != null) ...[
              if (!compact) separator(),
              IconButton(
                key: const Key('service-delete'),
                tooltip: context.l10n.modelService_delete,
                onPressed: _busy ? null : widget.onDelete,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(32),
                  minimumSize: const Size.square(32),
                  padding: EdgeInsets.zero,
                  foregroundColor: colors.onSurfaceVariant,
                  shape: const RoundedRectangleBorder(
                    borderRadius: serviceControlRadius,
                  ),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    final colors = Theme.of(context).colorScheme;
    return FilledButton(
      key: const Key('service-save'),
      onPressed: _canOperate ? _save : null,
      clipBehavior: Clip.antiAlias,
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: _saving
            ? colors.primary
            : colors.onSurface.withValues(alpha: .12),
        disabledForegroundColor: _saving
            ? colors.onPrimary
            : colors.onSurface.withValues(alpha: .38),
        side: BorderSide.none,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: const RoundedRectangleBorder(borderRadius: serviceControlRadius),
        overlayColor: colors.onPrimary.withValues(alpha: .08),
        animationDuration: Duration.zero,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: _saving ? 0 : 1,
            child: Text(context.l10n.modelService_save),
          ),
          if (_saving)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimary,
                semanticsLabel: context.l10n.modelService_saving,
              ),
            ),
        ],
      ),
    );
  }

  Widget _overviewSection(
    BuildContext context,
    String title, {
    String? count,
    List<Widget> actions = const [],
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Text(
                count,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
            const Spacer(),
            ...actions,
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
      ],
    );
  }

  Widget _connectionOverview(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasKey =
        ref
            .watch(promptAssistantConfigProvider)
            .providerHasApiKey[widget.provider?.id] ??
        false;
    final keyStatus = _apiKey.text.trim().isNotEmpty
        ? context.l10n.modelService_pendingSave
        : hasKey
        ? context.l10n.modelService_saved
        : _preset.requiresApiKey
        ? context.l10n.modelService_notConfigured
        : context.l10n.modelService_optional;
    Widget value(String label, String text, {bool selectable = false}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            selectable
                ? SelectableText(text, style: theme.textTheme.bodySmall)
                : Text(text, style: theme.textTheme.bodySmall),
          ],
        );
    return Material(
      key: const Key('service-connection-summary'),
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_editingConnection)
              LayoutBuilder(
                builder: (context, constraints) {
                  final address = value(
                    context.l10n.modelConnection_address,
                    _baseUrl.text.trim().isEmpty
                        ? context.l10n.modelService_notConfigured
                        : _baseUrl.text.trim(),
                    selectable: true,
                  );
                  final key = value(
                    context.l10n.modelConnection_apiKey,
                    keyStatus,
                  );
                  final protocol = value(
                    context.l10n.modelConnection_protocol,
                    _protocol.label,
                  );
                  final edit = TextButton.icon(
                    key: const Key('service-edit-connection'),
                    onPressed: _busy
                        ? null
                        : () => _updateOverview(
                            () => _editingConnection = !_editingConnection,
                          ),
                    icon: Icon(
                      _editingConnection
                          ? Icons.expand_less
                          : Icons.edit_outlined,
                      size: 15,
                    ),
                    label: Text(
                      _editingConnection
                          ? context.l10n.modelService_collapse
                          : context.l10n.modelService_editConnection,
                    ),
                  );
                  return constraints.maxWidth <
                          640 * MediaQuery.textScalerOf(context).scale(1)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            address,
                            const SizedBox(height: 12),
                            protocol,
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: key),
                                edit,
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 4, child: address),
                            const SizedBox(width: 20),
                            Expanded(flex: 3, child: protocol),
                            const SizedBox(width: 20),
                            SizedBox(width: 104, child: key),
                            const SizedBox(width: 12),
                            edit,
                          ],
                        );
                },
              ),
            if (_editingConnection) ...[
              Row(
                children: [
                  Text(
                    context.l10n.modelService_connectionSettings,
                    style: theme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('service-edit-connection'),
                    onPressed: _busy
                        ? null
                        : () =>
                              _updateOverview(() => _editingConnection = false),
                    icon: const Icon(Icons.expand_less, size: 15),
                    label: Text(context.l10n.modelService_collapse),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _connectionFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modelsOverview(BuildContext context, double height) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth <
          680 * MediaQuery.textScalerOf(context).scale(1);
      if (stacked) {
        return Column(
          children: [
            SizedBox(height: 300, child: _availablePanel()),
            const SizedBox(height: 12),
            SizedBox(height: height, child: _selectedPanel()),
          ],
        );
      }
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 51, child: _availablePanel()),
            const SizedBox(width: 12),
            Expanded(flex: 49, child: _selectedPanel()),
          ],
        ),
      );
    },
  );

  Widget _overviewModelRow(ModelConfig model, Widget parameters, int index) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final expanded = _expandedModel == model.name;
    return Padding(
      key: _selectedRowKeys.putIfAbsent(model.name, GlobalKey.new),
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: colors.onSurface.withValues(alpha: expanded ? .065 : .035),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Tooltip(
                    message: context.l10n.modelService_dragToReorder,
                    child: ReorderableDragStartListener(
                      key: ValueKey('model-drag-${model.name}'),
                      index: index,
                      enabled: !_busy,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 6,
                          ),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Tooltip(
                      message: model.displayName == model.name
                          ? model.name
                          : '${model.name} · ${model.displayName}',
                      child: Text(
                        model.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Tooltip(
                    message: context.l10n.modelService_capacityTooltip,
                    child: Text(
                      '${modelTokenLabel(model.contextWindow)} · ${modelTokenLabel(model.maxOutputTokens)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colors.onSurfaceVariant.withValues(alpha: .7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  TextButton(
                    key: ValueKey('service-model-parameters-${model.name}'),
                    onPressed: _busy ? null : () => _toggleAdvanced(model.name),
                    style: TextButton.styleFrom(
                      foregroundColor: Color.lerp(
                        colors.onSurface,
                        colors.onSurfaceVariant,
                        .35,
                      ),
                      backgroundColor: colors.onSurface.withValues(alpha: .06),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 27),
                      visualDensity: VisualDensity.standard,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(context.l10n.modelService_advanced),
                  ),
                  IconButton(
                    key: ValueKey('service-remove-model-${model.name}'),
                    tooltip: context.l10n.modelService_removeModel(model.name),
                    onPressed: _busy
                        ? null
                        : () => _toggleModel(model.name, false),
                    icon: const Icon(Icons.close, size: 13),
                    color: colors.onSurfaceVariant.withValues(alpha: .6),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(
                      minWidth: 25,
                      minHeight: 25,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            if (expanded) parameters,
          ],
        ),
      ),
    );
  }

  Widget _usageOverview(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(promptAssistantConfigProvider);
    final tasks = LauncherInterface.values
        .where(
          (task) =>
              widget.provider != null &&
              config.interfaceFor(task).providerId == widget.provider!.id,
        )
        .toList();
    Widget taskRow(LauncherInterface task) => InkWell(
      onTap: () => widget.onTaskSelected?.call(task),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                interfaceIcon(task),
                size: 17,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.titleIn(context.l10n),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    config.interfaceFor(task).model,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _overviewSection(context, context.l10n.modelService_linkedInterfaces),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              context.l10n.modelService_noLinkedInterfaces,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 440 ? 2 : 1;
            return Wrap(
              spacing: 22,
              children: [
                for (final task in tasks)
                  SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 22) / columns,
                    child: taskRow(task),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _requestControlRow(
    BuildContext context,
    String title,
    String description,
    Widget control,
  ) {
    final theme = Theme.of(context);
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 3),
        Text(
          description,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return SettingsHoverLine(
      enabled: !_busy,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final controlWidth = (244 * scale).clamp(0.0, constraints.maxWidth);
            final trailing = SizedBox(width: controlWidth, child: control);
            return constraints.maxWidth < 444 * scale
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label,
                      const SizedBox(height: 9),
                      Align(alignment: Alignment.centerRight, child: trailing),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: 20),
                      trailing,
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _advancedOverview(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(height: 1),
      SettingsHoverLine(
        child: TextButton(
          key: const Key('service-advanced-toggle'),
          onPressed: () =>
              _updateOverview(() => _advancedExpanded = !_advancedExpanded),
          style:
              TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ).copyWith(
                overlayColor: settingsFieldOverlay,
                iconColor: settingsFieldIconColor(
                  Theme.of(context).colorScheme,
                ),
              ),
          child: Row(
            children: [
              Text(
                context.l10n.modelService_advancedSettings,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                size: 17,
              ),
            ],
          ),
        ),
      ),
      if (_advancedExpanded) ...[
        _requestControlRow(
          context,
          context.l10n.modelService_requestTimeout,
          context.l10n.modelService_requestTimeoutHelp,
          ServiceRequestStepper(
            fieldKey: 'service-request-timeout',
            label: context.l10n.modelService_requestTimeout,
            unit: context.l10n.modelService_seconds,
            value: _timeoutSeconds,
            minimum: 10,
            maximum: 600,
            step: 10,
            enabled: !_busy,
            onChanged: (value) =>
                _updateOverview(() => _timeoutSeconds = value),
          ),
        ),
        const Divider(height: 1),
        _requestControlRow(
          context,
          context.l10n.modelService_maxConcurrency,
          context.l10n.modelService_maxConcurrencyHelp,
          ServiceRequestStepper(
            fieldKey: 'service-max-concurrency',
            label: context.l10n.modelService_maxConcurrency,
            unit: context.l10n.modelService_countUnit,
            value: _maxConcurrentRequests,
            minimum: 1,
            maximum: 20,
            enabled: !_busy,
            onChanged: (value) =>
                _updateOverview(() => _maxConcurrentRequests = value),
          ),
        ),
        const Divider(height: 1),
        _requestControlRow(
          context,
          context.l10n.modelService_retry,
          context.l10n.modelService_retryHelp,
          ServiceRetrySegments(
            key: const Key('service-retry-attempts'),
            value: _retryAttempts,
            enabled: !_busy,
            onChanged: (value) => _updateOverview(() => _retryAttempts = value),
          ),
        ),
      ],
      const Divider(height: 1),
    ],
  );
}
