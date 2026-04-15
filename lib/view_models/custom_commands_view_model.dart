import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/command/custom_command.dart';
import '../repositories/command_repository.dart';
import '../services/custom_command_service.dart';

/// ViewModel for the "Manage Custom Commands" screen (developer mode).
///
/// Fetches the current list from [CustomCommandService], exposes CRUD
/// operations, and surfaces any conflicts between custom commands and
/// the built-in catalog (which can happen after an app update ships a
/// new built-in command that shadows an existing custom one).
class CustomCommandsViewModel extends BaseViewModel {
  CustomCommandsViewModel({
    CustomCommandService? customCommandService,
    CommandRepository? builtInRepository,
  })  : _injectedService = customCommandService,
        _injectedBuiltIn = builtInRepository;

  final CustomCommandService? _injectedService;
  final CommandRepository? _injectedBuiltIn;

  late final CustomCommandService _service;
  late final CommandRepository _builtIn;

  List<CustomCommand> _commands = const [];
  List<CustomCommand> _conflicts = const [];

  List<CustomCommand> get commands => _commands;
  List<CustomCommand> get conflicts => _conflicts;
  bool get hasConflicts => _conflicts.isNotEmpty;
  bool get isEmpty => _commands.isEmpty;

  @override
  Future<void> onInit() async {
    _service = _injectedService ?? getIt<CustomCommandService>();
    _builtIn = _injectedBuiltIn ?? getIt<CommandRepository>();

    // Ensure prefs are loaded in case the service was lazily created
    // after app startup.
    if (!_service.isInitialized) {
      await _service.initialize();
    }

    subscribe<List<CustomCommand>>(
      _service.changeStream,
      _onCommandsChanged,
    );

    _refresh();
  }

  bool _isBuiltIn(String normalizedKey) =>
      _builtIn.getCommand(normalizedKey) != null;

  void _onCommandsChanged(List<CustomCommand> list) {
    _commands = list;
    _conflicts = _service.detectConflicts(isBuiltIn: _isBuiltIn);
    safeNotifyListeners();
  }

  void _refresh() {
    _commands = _service.list();
    _conflicts = _service.detectConflicts(isBuiltIn: _isBuiltIn);
    safeNotifyListeners();
  }

  Future<CustomCommandResult> addCommand(CustomCommand cmd) =>
      _service.add(cmd, isBuiltIn: _isBuiltIn);

  Future<CustomCommandResult> updateCommand(
    String oldCommandStr,
    CustomCommand updated,
  ) =>
      _service.update(oldCommandStr, updated, isBuiltIn: _isBuiltIn);

  Future<void> removeCommand(String commandStr) =>
      _service.remove(commandStr);
}
