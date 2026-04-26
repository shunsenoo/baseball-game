import 'dart:math';

import 'package:baseball_game/main.dart';
import 'package:baseball_game/src/baseball_models.dart';
import 'package:baseball_game/src/baseball_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulator produces a nine inning result and report', () {
    final result = BaseballSimulator(random: Random(1)).simulate(
      homeTeam: DemoTeams.dragons,
      awayTeam: DemoTeams.tokyo,
      gamePlan: const GamePlan(
        battingApproach: BattingApproach.balanced,
        bullpenApproach: BullpenApproach.quickHook,
      ),
    );

    expect(result.innings, hasLength(9));
    expect(result.report, isNotEmpty);
    expect(result.keyMoments, isNotEmpty);
    expect(result.scoreLine, contains('名古屋D'));
  });

  testWidgets('prototype can run a simulated Dragons game', (tester) async {
    await tester.pumpWidget(const BaseballGameApp());

    expect(find.text('プロ野球フロントライン 技術検証版'), findsOneWidget);
    expect(find.text('中日ドラゴンズ重点プロトタイプ'), findsOneWidget);

    final simulateButton = find.widgetWithText(FilledButton, '1試合をシミュレーション');
    await tester.dragUntilVisible(
      simulateButton,
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(simulateButton);
    await tester.pump();

    await tester.ensureVisible(find.text('試合後レポート'));
    expect(find.textContaining('試合後レポート'), findsOneWidget);
    expect(find.byIcon(Icons.sports_baseball), findsWidgets);
  });
}
