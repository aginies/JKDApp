import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';
import '../../../services/series_provider.dart';
import '../glossary/glossary_ui_builder.dart';
import '../../../models/picker_state.dart';
import 'move_display_widgets.dart';
import 'package:provider/provider.dart';

class GlossaryTabWidget extends StatefulWidget {
  final PickerState pickerState;
  final List<dynamic> currentCombo;
  final StateSetter setState;
  final TextEditingController customMoveController;
  final VoidCallback onActivateGlossaryItem;
  final Function(String, String) onShowMediaGallery;
  final Function(int) onPickSpecial;
  final Function(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
    bool isCustom,
  )
  onWorkflowAction;
  final Function(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  )
  onSimultaneousAction;
  final Function(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  )
  onChainAction;
  final Function(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  )
  onAnswerAction;
  final Function(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  )
  onFinishAction;
  final VoidCallback onCancelAction;
  final VoidCallback onFinishCombo;
  final Function(
    Map<String, dynamic> c,
    String cat,
    String cs,
    Map<String, dynamic> at,
    String ac,
    String as,
    String al,
    bool af,
    String? asp,
    Map<String, String> atr,
    Map<String, String> ctr,
    int r,
    String? cLevelOverride,
  )
  onAddCounterMove;

  const GlossaryTabWidget({
    super.key,
    required this.pickerState,
    required this.currentCombo,
    required this.setState,
    required this.customMoveController,
    required this.onActivateGlossaryItem,
    required this.onShowMediaGallery,
    required this.onPickSpecial,
    required this.onWorkflowAction,
    required this.onSimultaneousAction,
    required this.onChainAction,
    required this.onAnswerAction,
    required this.onFinishAction,
    required this.onCancelAction,
    required this.onFinishCombo,
    required this.onAddCounterMove,
  });

  @override
  State<GlossaryTabWidget> createState() => _GlossaryTabWidgetState();
}

class _GlossaryTabWidgetState extends State<GlossaryTabWidget>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _lastCounterMode = false;

  @override
  void initState() {
    super.initState();
    _lastCounterMode = widget.pickerState.pendingAttackMove != null;
    _tabController = TabController(length: 9, vsync: this);
    widget.pickerState.addListener(_onPickerStateChanged);
    // Handle any initial tab index request
    _consumeRequestedTab();
  }

  @override
  void didUpdateWidget(covariant GlossaryTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isCounterMode =
        widget.pickerState.pendingAttackMove != null ||
        widget.pickerState.isEditingCounter;
    if (isCounterMode != _lastCounterMode) {
      _lastCounterMode = isCounterMode;
      // Recreate the tab controller when counter mode changes
      _tabController?.dispose();
      _tabController = TabController(length: 9, vsync: this);
    }
    if (oldWidget.pickerState != widget.pickerState) {
      oldWidget.pickerState.removeListener(_onPickerStateChanged);
      widget.pickerState.addListener(_onPickerStateChanged);
    }
  }

  @override
  void dispose() {
    widget.pickerState.removeListener(_onPickerStateChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onPickerStateChanged() {
    _consumeRequestedTab();
  }

  void _consumeRequestedTab() {
    final requestedIndex = widget.pickerState.consumeRequestedTabIndex();
    if (requestedIndex != null && _tabController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController!.index != requestedIndex) {
          _tabController!.animateTo(requestedIndex);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;

    return Column(
      children: [
        _buildTabBar(context, lang),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(context, 'punch', lang),
              _buildTabContent(context, 'kick', lang),
              _buildTabContent(context, 'packs', lang),
              _buildTabContent(context, 'trapping', lang),
              _buildTabContent(context, 'move', lang),
              _buildTabContent(context, 'kali', lang),
              _buildTabContent(context, 'angles', lang),
              _buildTabContent(context, 'other', lang),
              _buildCustomTextTab(context, lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, String lang) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: [
        _buildTab(lang, 'punches', 'punch'),
        _buildTab(lang, 'kicks', 'kick'),
        _buildTab(lang, 'packs', 'packs'),
        _buildTab(lang, 'trapping', 'trapping'),
        _buildTab(lang, 'move', 'move'),
        _buildTab(lang, 'kali', 'kali'),
        _buildTab(lang, 'angles', 'angles'),
        _buildTab(lang, 'other', 'other'),
        const Tab(
          text: 'Text',
          icon: Icon(Icons.text_fields, color: Colors.teal),
        ),
      ],
    );
  }

  Tab _buildTab(String lang, String labelKey, String iconCat, {Color? color}) {
    return Tab(
      text: LocalizationService.translate(labelKey, lang),
      icon: Icon(
        MoveDisplayWidgets.getCategoryIcon(iconCat),
        color: color ?? MoveDisplayWidgets.getCategoryColor(iconCat),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String category, String lang) {
    final isCounterMode =
        widget.pickerState.pendingAttackMove != null ||
        widget.pickerState.isEditingCounter;

    return GlossaryUIBuilder.buildGlossaryList(
      context,
      category,
      widget.setState,
      isCounterMode: isCounterMode,
      attackMove: isCounterMode ? widget.pickerState.pendingAttackMove : null,
      pickerState: widget.pickerState,
      currentCombo: widget.currentCombo,
      onShowMediaGallery: () {
        // Double tap handled in GlossaryUIBuilder calling onShowMediaGallery if we passed it
      },
      onActivateGlossaryItem: widget.onActivateGlossaryItem,
      onPickSpecial: widget.onPickSpecial,
      onNext: (item, cat, side, level, isFeint, special, translations) {
        debugPrint('GlossaryTabWidget: onNext triggered for ${item['name']}');
        final attack = widget.pickerState.pendingAttackMove;
        if (attack != null) {
          widget.onAddCounterMove(
            item,
            cat,
            side,
            attack['item'],
            attack['cat'],
            attack['sd'],
            attack['lv'],
            attack['f'],
            attack['sp'],
            attack['tr'],
            translations,
            1,
            null,
          );
        } else if (widget.pickerState.isEditingCounter) {
          // Editing counter on existing combo item (e.g. simultaneous→Answer flow).
          // Attack data is already on the combo item; pass dummy attack params
          // since _addCounterMove editing path uses ex directly.
          widget.onAddCounterMove(
            item,
            cat,
            side,
            <String, dynamic>{},
            '',
            '',
            '',
            false,
            null,
            <String, String>{},
            translations,
            1,
            null,
          );
        } else {
          widget.onWorkflowAction(
            item,
            cat,
            side,
            level,
            isFeint,
            special,
            translations,
            false,
          );
        }
      },
      onSimultaneous: (item, cat, side, level, isFeint, special, translations) {
        debugPrint(
          'GlossaryTabWidget: onSimultaneous triggered for ${item['name']}',
        );
        widget.onSimultaneousAction(
          item,
          cat,
          side,
          level,
          isFeint,
          special,
          translations,
        );
      },
      onChain: (item, cat, side, level, isFeint, special, translations) {
        debugPrint('GlossaryTabWidget: onChain triggered for ${item['name']}');
        widget.onChainAction(
          item,
          cat,
          side,
          level,
          isFeint,
          special,
          translations,
        );
      },
      onAnswer: (item, cat, side, level, isFeint, special, translations) {
        debugPrint('GlossaryTabWidget: onAnswer triggered for ${item['name']}');
        widget.onAnswerAction(
          item,
          cat,
          side,
          level,
          isFeint,
          special,
          translations,
        );
      },
      onFinish: (item, cat, side, level, isFeint, special, translations) {
        debugPrint('GlossaryTabWidget: onFinish triggered for ${item['name']}');
        final attack = widget.pickerState.pendingAttackMove;
        if (attack != null) {
          // In counter mode: add the counter move, then finish the combo
          // and close the picker. Do NOT call onFinishAction here because
          // it internally calls _onWorkflowAction which would add a
          // duplicate move to the combo.
          widget.onAddCounterMove(
            item,
            cat,
            side,
            attack['item'],
            attack['cat'],
            attack['sd'],
            attack['lv'],
            attack['f'],
            attack['sp'],
            attack['tr'],
            translations,
            1,
            null,
          );
          widget.onFinishCombo();
        } else if (widget.pickerState.isEditingCounter) {
          // Editing counter on existing combo item (simultaneous→Answer flow).
          // Attack data is already on the combo item; pass dummy attack params.
          widget.onAddCounterMove(
            item,
            cat,
            side,
            <String, dynamic>{},
            '',
            '',
            '',
            false,
            null,
            <String, String>{},
            translations,
            1,
            null,
          );
          widget.onFinishCombo();
        } else {
          widget.onFinishAction(
            item,
            cat,
            side,
            level,
            isFeint,
            special,
            translations,
          );
        }
      },
      onCancel: widget.onCancelAction,
    );
  }

  Widget _buildCustomTextTab(BuildContext context, String lang) {
    final isCounterMode =
        widget.pickerState.pendingAttackMove != null ||
        widget.pickerState.isEditingCounter;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: widget.customMoveController,
            decoration: const InputDecoration(
              labelText: 'Custom Move Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => widget.setState(() {}),
          ),
          const SizedBox(height: 20),
          if (!isCounterMode)
            _buildCustomTextWorkflowButtons(lang)
          else
            ElevatedButton(
              onPressed: () {
                if (widget.customMoveController.text.isEmpty) return;
                final attack = widget.pickerState.pendingAttackMove;
                if (attack != null) {
                  widget.onAddCounterMove(
                    {'name': widget.customMoveController.text, 'id': null},
                    'text',
                    '',
                    attack['item'],
                    attack['cat'],
                    attack['sd'],
                    attack['lv'],
                    attack['f'],
                    attack['sp'],
                    attack['tr'],
                    {},
                    1,
                    null,
                  );
                } else {
                  // Editing counter on existing combo item
                  widget.onAddCounterMove(
                    {'name': widget.customMoveController.text, 'id': null},
                    'text',
                    '',
                    <String, dynamic>{},
                    '',
                    '',
                    '',
                    false,
                    null,
                    <String, String>{},
                    {},
                    1,
                    null,
                  );
                }
              },
              child: Text(LocalizationService.translate('add', lang)),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomTextWorkflowButtons(String lang) {
    // For custom text we simplify for now
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: widget.customMoveController.text.isEmpty
              ? null
              : () {
                  widget.onWorkflowAction(
                    {
                      'name': widget.customMoveController.text,
                      'translations': '{}',
                      'id': null,
                    },
                    'text',
                    '',
                    '',
                    false,
                    null,
                    {},
                    true,
                  );
                },
          child: Text(LocalizationService.translate('add', lang)),
        ),
      ],
    );
  }
}
