import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('MMM d, h:mm a').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final events = <({String choreTitle, String who, String whenIso})>[];
    for (final c in state.chores) {
      for (final h in c.history) {
        final who = state.roommateById(h.completedByRoommateId)?.name ?? 'Someone';
        events.add((choreTitle: c.title, who: who, whenIso: h.completedAtIso));
      }
    }

    events.sort((a, b) => b.whenIso.compareTo(a.whenIso));

    final requestItems = state.requests;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ListView(
        children: [
          const Text(
            'Requests',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Activity and change requests for this space.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (requestItems.isEmpty && events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No requests yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you ask for help or complete duties, they will appear here.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (requestItems.isNotEmpty) ...[
              const Text(
                'Open requests',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...requestItems.map((r) {
                final from = state.roommateById(r.fromRoommateId)?.name ?? 'Someone';
                final to = state.roommateById(r.toRoommateId)?.name ?? 'a roommate';
                final chore = state.chores.where((c) => c.id == r.choreId).isNotEmpty
                    ? state.chores.firstWhere((c) => c.id == r.choreId).title
                    : 'a duty';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$from asked $to to cover',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chore,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(r.createdAtIso),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          if (r.note != null && r.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              r.note!,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            if (events.isNotEmpty) ...[
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...events.take(80).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.who} completed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.text,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.choreTitle,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(e.whenIso),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}
