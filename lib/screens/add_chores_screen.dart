import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';

class AddChoresScreen extends StatefulWidget {
  const AddChoresScreen({super.key});

  @override
  State<AddChoresScreen> createState() => _AddChoresScreenState();
}

class _AddChoresScreenState extends State<AddChoresScreen> {
  final TextEditingController controller = TextEditingController();

  // Simple grouped suggestions for "COMMON ESSENTIALS" chips.
  final Map<String, List<String>> _suggestedChoresByCategory = const {
    'Cleaning': [
      'Take out trash',
      'Vacuum living room',
      'Clean bathroom',
    ],
    'Kitchen': [
      'Wash dishes',
      'Wipe kitchen counters',
      'Empty dishwasher',
    ],
    'Laundry': [
      'Do laundry',
      'Fold clothes',
    ],
    'Extras': [
      'Water plants',
      'Sweep entryway',
    ],
  };

  // Tracks which suggestion chips are currently selected.
  final Set<String> _selectedSuggestionTitles = <String>{};

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final canFinish = state.chores.isNotEmpty || _selectedSuggestionTitles.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Allow skipping chore setup and go straight to main shell.
                      context.read<AppState>().setOnboardingComplete(true);
                      Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Add chores',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add a few essentials to get started. You can always add more later.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMuted,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'e.g. Take out trash',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.border, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.welcomeCta, width: 2.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox
                    (
                    width: 64,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                      ),
                      onPressed: () async {
                        final t = controller.text.trim();
                        if (t.isEmpty) return;
                        try {
                          await context.read<AppState>().addChore(t);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          return;
                        }
                        controller.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.add_rounded, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'COMMON ESSENTIALS',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chips
                      for (final entry in _suggestedChoresByCategory.entries) ...[
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final title in entry.value)
                              _CommonChoreChip(
                                title: title,
                                selected: _selectedSuggestionTitles.contains(title),
                                onTap: () async {
                                  final appState = context.read<AppState>();
                                  final alreadyExists = appState.chores.any(
                                    (c) => c.title.toLowerCase() == title.toLowerCase(),
                                  );

                                  if (_selectedSuggestionTitles.contains(title)) {
                                    // Deselect chip and remove matching chore if present.
                                    _selectedSuggestionTitles.remove(title);
                                    if (alreadyExists) {
                                      final chore = appState.chores.firstWhere(
                                        (c) => c.title.toLowerCase() == title.toLowerCase(),
                                      );
                                      try {
                                        await appState.removeChore(chore.id);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  } else {
                                    // Select chip and add the chore.
                                    _selectedSuggestionTitles.add(title);
                                    if (!alreadyExists) {
                                      try {
                                        await appState.addChore(title);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  }

                                  if (mounted) setState(() {});
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (state.chores.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Your selected chores',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          itemCount: state.chores.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = state.chores[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/choreSetup', arguments: c.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceMuted,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.checklist_rounded,
                                            color: AppTheme.welcomeCta),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.text,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.repeatText ?? 'Weekly',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await context
                                              .read<AppState>()
                                              .removeChore(c.id);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString())));
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canFinish ? AppTheme.welcomeCta : AppTheme.surfaceMuted,
                    foregroundColor: canFinish ? Colors.white : AppTheme.textMuted,
                    elevation: canFinish ? 4 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  onPressed: canFinish
                      ? () {
                          Navigator.of(context).pushNamed('/reviewChores');
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommonChoreChip extends StatelessWidget {
  const _CommonChoreChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: 1.2,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }
}

