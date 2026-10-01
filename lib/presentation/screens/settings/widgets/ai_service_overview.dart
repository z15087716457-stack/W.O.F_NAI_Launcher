part of 'ai_service_editor_dialog.dart';

extension _ServiceOverview on _AiServiceEditorDialogState {
  Widget _buildServiceOverview(BuildContext context, bool dirty) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      key: const Key('service-overview-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Row(
                children: [
                  ProviderLogo(_preset, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider?.name ?? '添加服务商',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _protocol.label,
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
              final enabled = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _enabled,
                    visualDensity: VisualDensity.compact,
                    onChanged: _busy
                        ? null
                        : (value) =>
                              _updateOverview(() => _enabled = value ?? false),
                  ),
                  Text(
                    '启用',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
              return constraints.maxWidth < 330
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 8), enabled],
                    )
                  : Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 12),
                        enabled,
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null || _catalogMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 26),
          _modelsOverview(context),
          const SizedBox(height: 26),
          _usageOverview(context),
          const SizedBox(height: 20),
          _advancedOverview(context),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Text(
                dirty
                    ? '有未保存的修改'
                    : widget.provider == null
                    ? '配置服务后保存'
                    : '连接信息已保存',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: dirty ? colors.primary : colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _testModel,
                    icon: const Icon(Icons.power_outlined, size: 15),
                    label: const Text('测试连接'),
                    style: _overviewButton(context),
                  ),
                  if (dirty || widget.provider == null)
                    FilledButton(
                      key: const Key('service-save'),
                      onPressed: _canSaveOverview ? _save : null,
                      style: _overviewButton(context),
                      child: const Text('保存'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canSaveOverview => !_busy && _headersLoaded && !_headersLoadFailed;

  ButtonStyle _overviewButton(BuildContext context) => TextButton.styleFrom(
    textStyle: Theme.of(context).textTheme.bodySmall,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    minimumSize: const Size(32, 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    visualDensity: VisualDensity.compact,
  );

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
            Row(
              children: [
                Text(
                  '连接信息',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  key: const Key('service-edit-connection'),
                  onPressed: _busy
                      ? null
                      : () => _updateOverview(
                          () => _editingConnection = !_editingConnection,
                        ),
                  style: _overviewButton(context).copyWith(
                    foregroundColor: WidgetStatePropertyAll(
                      colors.onSurfaceVariant,
                    ),
                  ),
                  icon: Icon(
                    _editingConnection
                        ? Icons.expand_less
                        : Icons.edit_outlined,
                    size: 15,
                  ),
                  label: Text(_editingConnection ? '收起' : '编辑'),
                ),
              ],
            ),
            const SizedBox(height: 13),
            value(
              '接口地址',
              _baseUrl.text.trim().isEmpty ? '尚未配置' : _baseUrl.text.trim(),
              selectable: true,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final protocol = value('接口格式', _protocol.label);
                final key = value('API 密钥', keyStatus);
                return constraints.maxWidth < 360
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [protocol, const SizedBox(height: 14), key],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: protocol),
                          const SizedBox(width: 18),
                          Expanded(child: key),
                        ],
                      );
              },
            ),
            if (_editingConnection) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              _connectionFields(),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const Key('service-connection-save'),
                  onPressed: _canSaveOverview ? _save : null,
                  style: _overviewButton(context),
                  child: const Text('保存'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modelsOverview(BuildContext context) {
    final theme = Theme.of(context);
    final query = _selectedSearch.text.trim().toLowerCase();
    final models = _selected.values.where(
      (model) =>
          query.isEmpty ||
          model.name.toLowerCase().contains(query) ||
          model.displayName.toLowerCase().contains(query),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _overviewSection(
          context,
          '模型',
          count: '${_selected.length}',
          actions: [
            IconButton(
              key: const Key('service-catalog-toggle'),
              tooltip: _catalogVisible ? '收起模型目录' : '读取模型目录',
              visualDensity: VisualDensity.compact,
              onPressed: _busy
                  ? null
                  : () {
                      _updateOverview(() => _catalogVisible = !_catalogVisible);
                      if (_catalogVisible && _catalog.isEmpty) _fetchCatalog();
                    },
              icon: Icon(
                _catalogVisible ? Icons.expand_less : Icons.refresh,
                size: 17,
              ),
            ),
            TextButton.icon(
              key: const Key('service-add-model'),
              onPressed: _busy
                  ? null
                  : () =>
                        _updateOverview(() => _manualVisible = !_manualVisible),
              style: _overviewButton(context).copyWith(
                foregroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.onSurfaceVariant,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加'),
            ),
          ],
        ),
        if (_catalogVisible)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: SizedBox(height: 300, child: _availablePanel()),
          ),
        if (_manualVisible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('ai-service-manual-model-id'),
                    controller: _manualId,
                    onSubmitted: (_) => _addManual(),
                    decoration: const InputDecoration(
                      labelText: '模型 ID',
                      hintText: '输入完整的模型 ID',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '添加自定义模型',
                  onPressed: _busy ? null : _addManual,
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ),
        if (_selected.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: TextField(
              controller: _selectedSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 17),
                hintText: '搜索已选模型',
                isDense: true,
              ),
            ),
          ),
        if (models.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Text(
              _selected.isEmpty ? '读取模型目录，或手动添加模型。' : '没有匹配的模型',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final model in models) _selectedTile(model),
      ],
    );
  }

  Widget _overviewModelRow(ModelConfig model, Widget parameters) {
    final theme = Theme.of(context);
    final expanded = _expandedModel == model.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      model.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model.displayName == model.name
                          ? model.source == ModelSource.manual
                                ? '手动添加'
                                : '模型目录'
                          : model.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: ValueKey('service-model-parameters-${model.name}'),
                onPressed: _busy
                    ? null
                    : () => _updateOverview(
                        () => _expandedModel = expanded ? null : model.name,
                      ),
                style: _overviewButton(context).copyWith(
                  foregroundColor: WidgetStatePropertyAll(
                    expanded
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                icon: const Icon(Icons.tune, size: 14),
                label: const Text('参数'),
              ),
              PopupMenuButton<String>(
                tooltip: '管理模型 ${model.name}',
                enabled: !_busy,
                padding: EdgeInsets.zero,
                iconSize: 16,
                constraints: const BoxConstraints(minWidth: 130),
                onSelected: (_) => _toggleModel(model.name, false),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remove', child: Text('移除模型')),
                ],
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
        if (expanded) parameters,
        const Divider(height: 1),
      ],
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
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('service-request-timeout'),
          initialValue: '$_timeoutSeconds',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '请求超时（秒）',
            helperText: '10–600 秒',
            isDense: true,
          ),
          onChanged: (value) => _updateOverview(
            () => _timeoutSeconds = int.tryParse(value) ?? -1,
          ),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
          initialValue: _maxConcurrentRequests,
          decoration: const InputDecoration(
            labelText: '此服务最大并发请求',
            isDense: true,
          ),
          items: [
            for (var i = 1; i <= 20; i++)
              DropdownMenuItem(value: i, child: Text('$i 个')),
          ],
          onChanged: (value) =>
              _updateOverview(() => _maxConcurrentRequests = value!),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
          initialValue: _retryAttempts,
          decoration: const InputDecoration(
            labelText: '失败重试',
            helperText: '连接失败或服务繁忙时重试；默认关闭。',
            isDense: true,
          ),
          items: [
            for (var i = 0; i <= 3; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i == 0 ? '不自动重试' : '$i 次'),
              ),
          ],
          onChanged: (value) => _updateOverview(() => _retryAttempts = value!),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('允许图片输入'),
          value: _allowImageInput,
          onChanged: _protocol.supportsImagePayload && !_busy
              ? (value) => _updateOverview(() => _allowImageInput = value)
              : null,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('自定义请求头'),
          subtitle: Text('已设置 ${_headers.length} 项 · 安全存储'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: _busy || !_headersLoaded || _headersLoadFailed
              ? null
              : _showAdvanced,
        ),
        const SizedBox(height: 16),
      ],
      const Divider(height: 1),
    ],
  );
}
