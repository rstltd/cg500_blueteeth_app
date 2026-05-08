import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and restoring user layout preferences.
///
/// Stores preferences like:
/// - Preferred view mode (list vs grid)
/// - Panel sizes for split views
/// - Expanded/collapsed states
/// - Sort orders
/// - Filter states
///
/// Example:
/// ```dart
/// final layoutService = LayoutPreferenceService();
/// await layoutService.init();
///
/// // Save preference
/// await layoutService.setViewMode('deviceList', ViewMode.grid);
///
/// // Load preference
/// final viewMode = layoutService.getViewMode('deviceList');
/// ```
class LayoutPreferenceService {
  static const String _keyPrefix = 'layout_';
  static LayoutPreferenceService? _instance;

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Singleton instance
  factory LayoutPreferenceService() {
    _instance ??= LayoutPreferenceService._internal();
    return _instance!;
  }

  /// Independent instance for testing — bypasses the singleton so unit
  /// tests can isolate preference state across tests by pairing this with
  /// `SharedPreferences.setMockInitialValues({})` in `setUp`.
  factory LayoutPreferenceService.forTesting() {
    return LayoutPreferenceService._internal();
  }

  LayoutPreferenceService._internal();

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  // === View Mode ===

  /// Get stored view mode for a screen/widget
  Future<ViewMode> getViewMode(String key, {ViewMode defaultValue = ViewMode.list}) async {
    await _ensureInitialized();
    final value = _prefs?.getString('${_keyPrefix}viewMode_$key');
    if (value == null) return defaultValue;
    return ViewMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultValue,
    );
  }

  /// Set view mode for a screen/widget
  Future<void> setViewMode(String key, ViewMode mode) async {
    await _ensureInitialized();
    await _prefs?.setString('${_keyPrefix}viewMode_$key', mode.name);
  }

  // === Panel Sizes ===

  /// Get stored panel ratio for split views
  Future<double> getPanelRatio(String key, {double defaultValue = 0.4}) async {
    await _ensureInitialized();
    return _prefs?.getDouble('${_keyPrefix}panelRatio_$key') ?? defaultValue;
  }

  /// Set panel ratio for split views
  Future<void> setPanelRatio(String key, double ratio) async {
    await _ensureInitialized();
    await _prefs?.setDouble('${_keyPrefix}panelRatio_$key', ratio.clamp(0.2, 0.8));
  }

  // === Expanded/Collapsed States ===

  /// Get expanded state for a section/panel
  Future<bool> getExpandedState(String key, {bool defaultValue = true}) async {
    await _ensureInitialized();
    return _prefs?.getBool('${_keyPrefix}expanded_$key') ?? defaultValue;
  }

  /// Set expanded state for a section/panel
  Future<void> setExpandedState(String key, bool expanded) async {
    await _ensureInitialized();
    await _prefs?.setBool('${_keyPrefix}expanded_$key', expanded);
  }

  // === Sort Order ===

  /// Get stored sort order
  Future<SortOrder> getSortOrder(String key, {SortOrder defaultValue = SortOrder.nameAsc}) async {
    await _ensureInitialized();
    final value = _prefs?.getString('${_keyPrefix}sortOrder_$key');
    if (value == null) return defaultValue;
    return SortOrder.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultValue,
    );
  }

  /// Set sort order
  Future<void> setSortOrder(String key, SortOrder order) async {
    await _ensureInitialized();
    await _prefs?.setString('${_keyPrefix}sortOrder_$key', order.name);
  }

  // === Filter States ===

  /// Get stored filter string
  Future<String?> getFilter(String key) async {
    await _ensureInitialized();
    return _prefs?.getString('${_keyPrefix}filter_$key');
  }

  /// Set filter string
  Future<void> setFilter(String key, String? filter) async {
    await _ensureInitialized();
    if (filter == null || filter.isEmpty) {
      await _prefs?.remove('${_keyPrefix}filter_$key');
    } else {
      await _prefs?.setString('${_keyPrefix}filter_$key', filter);
    }
  }

  /// Get stored filter list (for multi-select filters)
  Future<List<String>> getFilterList(String key) async {
    await _ensureInitialized();
    return _prefs?.getStringList('${_keyPrefix}filterList_$key') ?? [];
  }

  /// Set filter list
  Future<void> setFilterList(String key, List<String> filters) async {
    await _ensureInitialized();
    if (filters.isEmpty) {
      await _prefs?.remove('${_keyPrefix}filterList_$key');
    } else {
      await _prefs?.setStringList('${_keyPrefix}filterList_$key', filters);
    }
  }

  // === Selected Tab/Index ===

  /// Get stored selected index
  Future<int> getSelectedIndex(String key, {int defaultValue = 0}) async {
    await _ensureInitialized();
    return _prefs?.getInt('${_keyPrefix}selectedIndex_$key') ?? defaultValue;
  }

  /// Set selected index
  Future<void> setSelectedIndex(String key, int index) async {
    await _ensureInitialized();
    await _prefs?.setInt('${_keyPrefix}selectedIndex_$key', index);
  }

  // === Scroll Position ===

  /// Get stored scroll position
  Future<double> getScrollPosition(String key, {double defaultValue = 0.0}) async {
    await _ensureInitialized();
    return _prefs?.getDouble('${_keyPrefix}scrollPos_$key') ?? defaultValue;
  }

  /// Set scroll position
  Future<void> setScrollPosition(String key, double position) async {
    await _ensureInitialized();
    await _prefs?.setDouble('${_keyPrefix}scrollPos_$key', position);
  }

  // === Generic Value Storage ===

  /// Get generic string value
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs?.getString('${_keyPrefix}custom_$key');
  }

  /// Set generic string value
  Future<void> setString(String key, String? value) async {
    await _ensureInitialized();
    if (value == null) {
      await _prefs?.remove('${_keyPrefix}custom_$key');
    } else {
      await _prefs?.setString('${_keyPrefix}custom_$key', value);
    }
  }

  /// Get generic int value
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs?.getInt('${_keyPrefix}custom_$key');
  }

  /// Set generic int value
  Future<void> setInt(String key, int? value) async {
    await _ensureInitialized();
    if (value == null) {
      await _prefs?.remove('${_keyPrefix}custom_$key');
    } else {
      await _prefs?.setInt('${_keyPrefix}custom_$key', value);
    }
  }

  /// Get generic bool value
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs?.getBool('${_keyPrefix}custom_$key');
  }

  /// Set generic bool value
  Future<void> setBool(String key, bool? value) async {
    await _ensureInitialized();
    if (value == null) {
      await _prefs?.remove('${_keyPrefix}custom_$key');
    } else {
      await _prefs?.setBool('${_keyPrefix}custom_$key', value);
    }
  }

  // === Clear Methods ===

  /// Clear all layout preferences
  Future<void> clearAll() async {
    await _ensureInitialized();
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  /// Clear preferences for a specific screen/widget
  Future<void> clearFor(String screenKey) async {
    await _ensureInitialized();
    final keys = _prefs?.getKeys().where(
      (k) => k.startsWith(_keyPrefix) && k.contains(screenKey),
    ) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}

/// View mode options
enum ViewMode {
  list,
  grid,
  compact,
  detailed,
}

/// Sort order options
enum SortOrder {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
  signalAsc,
  signalDesc,
  custom,
}

/// A mixin to easily integrate layout preferences into StatefulWidgets.
///
/// Example:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with LayoutPreferenceMixin {
///   @override
///   String get preferenceKey => 'myScreen';
///
///   @override
///   void initState() {
///     super.initState();
///     loadPreferences();
///   }
/// }
/// ```
mixin LayoutPreferenceMixin<T extends StatefulWidget> on State<T> {
  final LayoutPreferenceService _layoutService = LayoutPreferenceService();

  /// Override this to provide a unique key for this screen's preferences
  String get preferenceKey;

  /// Current view mode
  ViewMode viewMode = ViewMode.list;

  /// Current sort order
  SortOrder sortOrder = SortOrder.nameAsc;

  /// Panel ratio for split views
  double panelRatio = 0.4;

  /// Load all preferences
  Future<void> loadPreferences() async {
    final loadedViewMode = await _layoutService.getViewMode(preferenceKey);
    final loadedSortOrder = await _layoutService.getSortOrder(preferenceKey);
    final loadedPanelRatio = await _layoutService.getPanelRatio(preferenceKey);

    if (mounted) {
      setState(() {
        viewMode = loadedViewMode;
        sortOrder = loadedSortOrder;
        panelRatio = loadedPanelRatio;
      });
    }
  }

  /// Save view mode
  Future<void> saveViewMode(ViewMode mode) async {
    setState(() => viewMode = mode);
    await _layoutService.setViewMode(preferenceKey, mode);
  }

  /// Save sort order
  Future<void> saveSortOrder(SortOrder order) async {
    setState(() => sortOrder = order);
    await _layoutService.setSortOrder(preferenceKey, order);
  }

  /// Save panel ratio
  Future<void> savePanelRatio(double ratio) async {
    setState(() => panelRatio = ratio);
    await _layoutService.setPanelRatio(preferenceKey, ratio);
  }

  /// Get expanded state for a section
  Future<bool> getExpandedState(String sectionKey, {bool defaultValue = true}) {
    return _layoutService.getExpandedState(
      '${preferenceKey}_$sectionKey',
      defaultValue: defaultValue,
    );
  }

  /// Save expanded state for a section
  Future<void> saveExpandedState(String sectionKey, bool expanded) {
    return _layoutService.setExpandedState(
      '${preferenceKey}_$sectionKey',
      expanded,
    );
  }
}

/// A widget that automatically saves and restores scroll position.
///
/// Example:
/// ```dart
/// PersistentScrollView(
///   preferenceKey: 'deviceList',
///   child: ListView(...),
/// )
/// ```
class PersistentScrollView extends StatefulWidget {
  final String preferenceKey;
  final Widget child;
  final ScrollController? controller;

  const PersistentScrollView({
    super.key,
    required this.preferenceKey,
    required this.child,
    this.controller,
  });

  @override
  State<PersistentScrollView> createState() => _PersistentScrollViewState();
}

class _PersistentScrollViewState extends State<PersistentScrollView> {
  final _layoutService = LayoutPreferenceService();
  late ScrollController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final position = await _layoutService.getScrollPosition(widget.preferenceKey);
    if (mounted && position > 0 && _controller.hasClients) {
      _controller.jumpTo(position);
    }
    _initialized = true;
    _controller.addListener(_savePosition);
  }

  void _savePosition() {
    if (_initialized && _controller.hasClients) {
      _layoutService.setScrollPosition(
        widget.preferenceKey,
        _controller.offset,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_savePosition);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
  }
}
