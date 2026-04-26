import 'dart:math';

import 'package:baseball_game/src/baseball_models.dart';
import 'package:baseball_game/src/production_game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production engine simulates full innings and plate appearances', () {
    final result = ProductionGameEngine(random: Random(7)).simulate(
      homeTeam: DemoTeams.dragons,
      awayTeam: DemoTeams.tokyo,
      plan: const ProductionGamePlan(
        battingApproach: BattingApproach.smallBall,
        bullpenApproach: BullpenApproach.quickHook,
        lineupIntent: LineupIntent.onBaseFirst,
        runningIntent: RunningIntent.aggressive,
        defensiveAlignment: DefensiveAlignment.noDoubles,
        clutchIntent: ClutchIntent.pinchHit,
      ),
    );

    expect(result.innings, hasLength(9));
    expect(result.events.length, greaterThan(54));
    expect(result.scoreLine, contains('名古屋D'));
    expect(result.highlights, isNotEmpty);
    expect(result.decisionCards, isNotEmpty);
    expect(result.decisionCards.first.recommendedCall, isNotEmpty);
    expect(
      result.events.every(
        (event) => event.outsBefore >= 0 && event.outsBefore <= 2,
      ),
      isTrue,
    );
  });

  test('production engine exposes leverage situations', () {
    final result = ProductionGameEngine(random: Random(2)).simulate(
      homeTeam: DemoTeams.dragons,
      awayTeam: DemoTeams.tokyo,
      plan: const ProductionGamePlan(
        battingApproach: BattingApproach.power,
        bullpenApproach: BullpenApproach.preserveArms,
        lineupIntent: LineupIntent.powerFirst,
        runningIntent: RunningIntent.conservative,
        defensiveAlignment: DefensiveAlignment.standard,
        clutchIntent: ClutchIntent.saveBullpen,
      ),
    );

    expect(
      result.leverageEvents.length,
      lessThanOrEqualTo(result.events.length),
    );
    expect(result.recommendations, isNotEmpty);
  });
}
