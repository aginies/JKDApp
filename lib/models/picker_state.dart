import 'package:flutter/foundation.dart';

/// Manages the state of the move picker modal
class PickerState extends ChangeNotifier {
  // Side selections per glossary item ID
  final Map<int, String> _selectedSides = {};

  // Feint selections per glossary item ID
  final Map<int, bool> _selectedFeints = {};

  // Special action selections per glossary item ID
  final Map<int, String?> _selectedSpecials = {};

  // Simultaneous (+) selections per glossary item ID
  final Map<int, bool> _selectedSimultaneous = {};

  // Currently active item in the picker
  int? _pendingActionItemId;

  // Currently selected level (H/M/L)
  String? _pendingLevel;

  // Index of the series item being edited (if any)
  int? _editingSeriesIndex;

  // Target index when moving/updating item
  int? _targetSeriesIndex;

  // Index of combo item being edited
  int? _editingComboItemIndex;

  // Whether we're editing the counter part of a move
  bool _isEditingCounter = false;

  // Whether the picker modal is currently open
  bool _isPickerOpen = false;

  // Pending attack move data when selecting counter
  Map<String, dynamic>? _pendingAttackMove;

  // Last scrolled item ID to prevent re-scrolling
  int? _lastScrolledItemId;

  // Selected sub-letter (a, b, c, ...)
  String? _selectedSubLetter;

  // Requested tab index for programmatic tab navigation
  int? _requestedTabIndex;

  // Getters
  Map<int, String> get selectedSides => _selectedSides;
  Map<int, bool> get selectedFeints => _selectedFeints;
  Map<int, String?> get selectedSpecials => _selectedSpecials;
  Map<int, bool> get selectedSimultaneous => _selectedSimultaneous;
  int? get pendingActionItemId => _pendingActionItemId;
  String? get pendingLevel => _pendingLevel;
  int? get editingSeriesIndex => _editingSeriesIndex;
  int? get targetSeriesIndex => _targetSeriesIndex;
  int? get editingComboItemIndex => _editingComboItemIndex;
  bool get isEditingCounter => _isEditingCounter;
  bool get isPickerOpen => _isPickerOpen;
  Map<String, dynamic>? get pendingAttackMove => _pendingAttackMove;
  int? get lastScrolledItemId => _lastScrolledItemId;
  String? get selectedSubLetter => _selectedSubLetter;
  int? get requestedTabIndex => _requestedTabIndex;

  bool get isEditingMode => _editingComboItemIndex != null;

  // Setters with notification
  void setSelectedSide(int id, String side) {
    _selectedSides[id] = side;
    notifyListeners();
  }

  void setSelectedFeint(int id, bool isFeint) {
    _selectedFeints[id] = isFeint;
    notifyListeners();
  }

  void setSelectedSpecial(int id, String? special) {
    _selectedSpecials[id] = special;
    notifyListeners();
  }

  void setSelectedSimultaneous(int id, bool isSimultaneous) {
    _selectedSimultaneous[id] = isSimultaneous;
    notifyListeners();
  }

  void setPendingActionItem(int? itemId) {
    _pendingActionItemId = itemId;
    notifyListeners();
  }

  void setPendingLevel(String? level) {
    _pendingLevel = level;
    notifyListeners();
  }

  void setEditingSeriesIndex(int? index) {
    _editingSeriesIndex = index;
    notifyListeners();
  }

  void setTargetSeriesIndex(int? index) {
    _targetSeriesIndex = index;
    notifyListeners();
  }

  void setEditingComboItemIndex(int? index) {
    _editingComboItemIndex = index;
    notifyListeners();
  }

  void setIsEditingCounter(bool value) {
    _isEditingCounter = value;
    notifyListeners();
  }

  void setIsPickerOpen(bool value) {
    _isPickerOpen = value;
    notifyListeners();
  }

  void setPendingAttackMove(Map<String, dynamic>? attackMove) {
    _pendingAttackMove = attackMove;
    notifyListeners();
  }

  void setLastScrolledItemId(int? id) {
    _lastScrolledItemId = id;
    notifyListeners();
  }

  void setSelectedSubLetter(String? letter) {
    _selectedSubLetter = letter;
    notifyListeners();
  }

  void setRequestedTabIndex(int? index) {
    _requestedTabIndex = index;
    notifyListeners();
  }

  /// Consumes the requested tab index (returns it and clears it)
  int? consumeRequestedTabIndex() {
    final index = _requestedTabIndex;
    _requestedTabIndex = null;
    return index;
  }

  /// Activates a glossary item and clears conflicting selections
  void activateGlossaryItem(int itemId) {
    if (_pendingActionItemId != itemId) {
      _selectedSides.clear();
      _selectedFeints.clear();
      _selectedSpecials.clear();
      _selectedSimultaneous.clear();
      _pendingActionItemId = itemId;
      _pendingLevel = null;
      notifyListeners();
    }
  }

  /// Resets all picker state to initial values
  void reset() {
    _selectedSides.clear();
    _selectedFeints.clear();
    _selectedSpecials.clear();
    _selectedSimultaneous.clear();
    _pendingActionItemId = null;
    _pendingLevel = null;
    _editingSeriesIndex = null;
    _targetSeriesIndex = null;
    _editingComboItemIndex = null;
    _isEditingCounter = false;
    _pendingAttackMove = null;
    _lastScrolledItemId = null;
    _selectedSubLetter = null;
    _requestedTabIndex = null;
    notifyListeners();
  }

  /// Clears only the pending action state
  void clearPendingAction() {
    _pendingActionItemId = null;
    _pendingLevel = null;
    notifyListeners();
  }

  /// Clears editing state
  void clearEditingState() {
    _editingComboItemIndex = null;
    _isEditingCounter = false;
    notifyListeners();
  }
}
