/// Lets navigation save the currently mounted editor, including validation.
class ModelDraftSaveController {
  Object? _owner;
  Future<bool> Function()? _save;

  void attach(Object owner, Future<bool> Function() save) {
    _owner = owner;
    _save = save;
  }

  void detach(Object owner) {
    if (identical(owner, _owner)) {
      _owner = null;
      _save = null;
    }
  }

  Future<bool> save() => _save?.call() ?? Future.value(false);
}
