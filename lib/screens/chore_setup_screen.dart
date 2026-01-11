import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ChoreSetupScreen extends StatefulWidget {
  final String choreId;

  const ChoreSetupScreen({super.key, required this.choreId});

  @override
  State<ChoreSetupScreen> createState() => _ChoreSetupScreenState();
}

class _ChoreSetupScreenState extends State<ChoreSetupScreen> {
  String _frequency = 'weekly'; // daily, weekly, custom
  final Set<String> _selectedRoommateIds = {};
  String? _firstTurnRoommateId;
  bool _initializedFromChore = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chore = state.chores.firstWhere(
      (c) => c.id == widget.choreId,
      orElse: () => throw StateError('Chore not found'),
    );
    final roommates = state.roommates;

    if (!_initializedFromChore) {
      _initializedFromChore = true;

      // Seed frequency from existing repeatText.
      final rt = (chore.repeatText ?? '').toLowerCase();
      if (rt == 'daily') {
        _frequency = 'daily';
      } else if (rt == 'custom') {
        _frequency = 'custom';
      } else {
        _frequency = 'weekly';
      }

      // Seed participants from chore-specific participants or all roommates.
      final existingParticipants = chore.participantRoommateIds;
      if (existingParticipants.isNotEmpty) {
        _selectedRoommateIds
          ..clear()
          ..addAll(existingParticipants);
      } else {
        _selectedRoommateIds
          ..clear()
          ..addAll(roommates.map((r) => r.id));
      }

      // Seed first turn from currentTurnRoommateId or first participant.
      if (chore.currentTurnRoommateId.isNotEmpty) {
        _firstTurnRoommateId = chore.currentTurnRoommateId;
      } else if (_selectedRoommateIds.isNotEmpty) {
        _firstTurnRoommateId = _selectedRoommateIds.first;
      } else if (roommates.isNotEmpty) {
        _firstTurnRoommateId = roommates.first.id;
      }
    }

    String frequencyDescription;
    switch (_frequency) {
      case 'daily':
        frequencyDescription = 'Repeats every day';
        break;
      case 'weekly':
        frequencyDescription = 'Repeats every week';
        break;
      default:
        frequencyDescription = 'Custom schedule';
    }

    final selectedIds = _selectedRoommateIds.isEmpty
        ? roommates.map((r) => r.id).toSet()
        : _selectedRoommateIds;

    if (_firstTurnRoommateId == null && roommates.isNotEmpty) {
      _firstTurnRoommateId = roommates.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          chore.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How often?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FrequencyPill(
                    label: 'Daily',
                    isSelected: _frequency == 'daily',
                    onTap: () => setState(() => _frequency = 'daily'),
                  ),
                  const SizedBox(width: 8),
                  _FrequencyPill(
                    label: 'Weekly',
                    isSelected: _frequency == 'weekly',
                    onTap: () => setState(() => _frequency = 'weekly'),
                  ),
                  const SizedBox(width: 8),
                  _FrequencyPill(
                    label: 'Custom',
                    isSelected: _frequency == 'custom',
                    onTap: () => setState(() => _frequency = 'custom'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                frequencyDescription,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Who is involved?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: roommates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final r = roommates[index];
                    final selected = selectedIds.contains(r.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedRoommateIds.contains(r.id)) {
                            _selectedRoommateIds.remove(r.id);
                          } else {
                            _selectedRoommateIds.add(r.id);
                          }
                          if (_selectedRoommateIds.isNotEmpty &&
                              !_selectedRoommateIds.contains(_firstTurnRoommateId)) {
                            _firstTurnRoommateId = _selectedRoommateIds.first;
                          }
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppTheme.primary : AppTheme.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: AvatarChip(
                              name: r.name,
                              imageUrl: r.avatarUrl,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.name.split(' ').first,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${selectedIds.length} selected',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Whose turn is first?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: roommates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = roommates[index];
                    final isFirst = r.id == _firstTurnRoommateId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _firstTurnRoommateId = r.id;
                          if (_selectedRoommateIds.isNotEmpty &&
                              !_selectedRoommateIds.contains(r.id)) {
                            _selectedRoommateIds.add(r.id);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFirst ? AppTheme.primary : AppTheme.border,
                            width: isFirst ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            AvatarChip(
                              name: r.name,
                              imageUrl: r.avatarUrl,
                              size: 34,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Starts first in rotation',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isFirst
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isFirst ? AppTheme.primary : AppTheme.border,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ids = selectedIds.toList();
                    if (ids.isEmpty) return;

                    var first = _firstTurnRoommateId;
                    if (first == null || !ids.contains(first)) {
                      first = ids.first;
                    }

                    final repeatText = switch (_frequency) {
                      'daily' => 'Daily',
                      'custom' => 'Custom',
                      _ => 'Weekly',
                    };

                    try {
                      await context.read<AppState>().configureChore(
                            choreId: widget.choreId,
                            repeatText: repeatText,
                            participantRoommateIds: ids,
                            firstTurnRoommateId: first,
                          );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                      return;
                    }

                    if (!context.mounted) return;
                    Navigator.of(context).maybePop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.welcomeCta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Save Chore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }
}
