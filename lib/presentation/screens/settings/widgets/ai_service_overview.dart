part of 'ai_service_editor_dialog.dart';

extension _ServiceOverview on _AiServiceEditorDialogState {
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
                                    ? '添加服务商'
                                    : _name.text.trim(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_selected.length} 个启用模型 · ${dirty ? '待保存' : '已保存'}',
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
                    final actions = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('启用', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 7),
                            SettingsToggle(
                              value: _enabled,
                              onChanged: _busy
                                  ? null
                                  : (value) =>
                                        _updateOverview(() => _enabled = value),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _testModel,
                          icon: const Icon(Icons.power_outlined, size: 15),
                          label: const Text('测试连接'),
                        ),
                        FilledButton(
                          key: const Key('service-save'),
                          onPressed: _canSaveOverview ? _save : null,
                          child: const Text('保存服务'),
                        ),
                        if (widget.provider != null && widget.onDelete != null)
                          IconButton(
                            key: const Key('service-delete'),
                            tooltip: '删除服务',
                            onPressed: _busy ? null : widget.onDelete,
                            style: IconButton.styleFrom(
                              foregroundColor: colors.onSurfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                      ],
                    );
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
                              actions,
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
                      (bodyViewport.maxHeight - 8).clamp(360.0, 680.0),
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

  bool get _canSaveOverview => !_busy && _headersLoaded && !_headersLoadFailed;

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
    final keyStatus = _clearKey
        ? '保存后清除'
        : _apiKey.text.trim().isNotEmpty
        ? '待保存'
        : hasKey
        ? '已保存'
        : _preset.requiresApiKey
        ? '尚未配置'
        : '可留空';
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
                    '接口地址',
                    _baseUrl.text.trim().isEmpty
                        ? '尚未配置'
                        : _baseUrl.text.trim(),
                    selectable: true,
                  );
                  final key = value('API 密钥', keyStatus);
                  final protocol = value('接口协议', _protocol.label);
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
                    label: Text(_editingConnection ? '收起' : '编辑'),
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
                  Text('连接设置', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('service-edit-connection'),
                    onPressed: _busy
                        ? null
                        : () =>
                              _updateOverview(() => _editingConnection = false),
                    icon: const Icon(Icons.expand_less, size: 15),
                    label: const Text('收起'),
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
                    message: '拖拽调整模型排序',
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
                          fontFamily: StudioTypography.mono,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Tooltip(
                    message: '上下文 / 最大输出；可在高级中调整',
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
                    child: const Text('高级'),
                  ),
                  IconButton(
                    key: ValueKey('service-remove-model-${model.name}'),
                    tooltip: '删除模型 ${model.name}',
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
                  Text(task.title, style: theme.textTheme.bodySmall),
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
        _overviewSection(context, '关联功能'),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              '尚未关联功能',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth <
                340 * MediaQuery.textScalerOf(context).scale(1)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label,
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 145, child: control),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: 20),
                  SizedBox(width: 145, child: control),
                ],
              ),
      ),
    );
  }

  Widget _advancedOverview(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(height: 1),
      InkWell(
        key: const Key('service-advanced-toggle'),
        onTap: () =>
            _updateOverview(() => _advancedExpanded = !_advancedExpanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Text(
                '高级设置',
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
          '请求超时',
          '单次请求最长等待时间',
          TextFormField(
            key: const Key('service-request-timeout'),
            initialValue: '$_timeoutSeconds',
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              suffixText: '秒',
              errorText: _timeoutSeconds < 10 || _timeoutSeconds > 600
                  ? '10–600 秒'
                  : null,
            ),
            onChanged: (value) => _updateOverview(
              () => _timeoutSeconds = int.tryParse(value) ?? -1,
            ),
          ),
        ),
        const Divider(height: 1),
        _requestControlRow(
          context,
          '最大并发数量',
          '此服务同时处理的请求数',
          DropdownButtonFormField<int>(
            key: const Key('service-max-concurrency'),
            initialValue: _maxConcurrentRequests,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (var i = 1; i <= 20; i++)
                DropdownMenuItem(value: i, child: Text('$i 个')),
            ],
            onChanged: _busy
                ? null
                : (value) =>
                      _updateOverview(() => _maxConcurrentRequests = value!),
          ),
        ),
        const Divider(height: 1),
        _requestControlRow(
          context,
          '失败重试',
          '连接失败或服务繁忙时重试',
          DropdownButtonFormField<int>(
            key: const Key('service-retry-attempts'),
            initialValue: _retryAttempts,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (var i = 0; i <= 3; i++)
                DropdownMenuItem(value: i, child: Text(i == 0 ? '关闭' : '$i 次')),
            ],
            onChanged: _busy
                ? null
                : (value) => _updateOverview(() => _retryAttempts = value!),
          ),
        ),
      ],
      const Divider(height: 1),
    ],
  );
}
