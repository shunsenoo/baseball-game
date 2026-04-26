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

  testWidgets('prototype advances the Dragons season loop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BaseballGameApp());

    expect(find.text('プロ野球フロントライン 技術検証版'), findsOneWidget);
    expect(find.textContaining('10試合チャレンジ'), findsWidgets);
    await tester.ensureVisible(find.text('球団状態'));
    expect(find.text('球団状態'), findsOneWidget);
    await tester.ensureVisible(find.text('試合前分析'));
    expect(find.text('試合前分析'), findsOneWidget);
    expect(find.textContaining('おすすめ:'), findsWidgets);
    expect(find.textContaining('相手先発:'), findsWidgets);

    final simulateButton = find.widgetWithText(FilledButton, '次の試合へ進む');
    expect(simulateButton, findsOneWidget);
    expect(find.text('ミッション: 3点以上取って得点力不足を払拭'), findsOneWidget);
    expect(find.text('前回の報酬/結果'), findsOneWidget);
    expect(find.textContaining('育成ポイント'), findsWidgets);
    expect(find.byIcon(Icons.sports_baseball), findsWidgets);
  });
}
