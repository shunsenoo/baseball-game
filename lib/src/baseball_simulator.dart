import 'dart:math';

import 'baseball_models.dart';

class BaseballSimulator {
  BaseballSimulator({Random? random}) : _random = random ?? Random();

  final Random _random;

  MatchResult simulate({
    required Team homeTeam,
    required Team awayTeam,
    required GamePlan gamePlan,
  }) {
    final innings = <InningScore>[];
    var homeRuns = 0;
    var awayRuns = 0;
    var homeStarterStamina = homeTeam.rotation.first.stamina;
    var awayStarterStamina = awayTeam.rotation.first.stamina;
    final keyMoments = <String>[];

    for (var inning = 1; inning <= 9; inning++) {
      final awayInningRuns = _simulateHalfInning(
        battingTeam: awayTeam,
        pitchingTeam: homeTeam,
        pitcherStamina: homeStarterStamina,
        battingApproach: BattingApproach.balanced,
        bullpenApproach: BullpenApproach.normal,
        inning: inning,
        isBottom: false,
        keyMoments: keyMoments,
      );
      awayRuns += awayInningRuns.runs;
      homeStarterStamina = awayInningRuns.remainingStamina;

      final homeInningRuns = _simulateHalfInning(
        battingTeam: homeTeam,
        pitchingTeam: awayTeam,
        pitcherStamina: awayStarterStamina,
        battingApproach: gamePlan.battingApproach,
        bullpenApproach: gamePlan.bullpenApproach,
        inning: inning,
        isBottom: true,
        keyMoments: keyMoments,
      );
      homeRuns += homeInningRuns.runs;
      awayStarterStamina = homeInningRuns.remainingStamina;

      innings.add(
        InningScore(top: awayInningRuns.runs, bottom: homeInningRuns.runs),
      );
    }

    if (homeRuns == awayRuns) {
      final extraRunForHome =
          _random.nextDouble() <
          (gamePlan.bullpenApproach == BullpenApproach.quickHook ? 0.58 : 0.48);
      if (extraRunForHome) {
        homeRuns++;
        keyMoments.add('延長10回、早めの勝ちパターン投入がサヨナラ機を呼び込みました。');
      } else {
        awayRuns++;
        keyMoments.add('延長10回、リリーフ負荷が出て勝ち越しを許しました。');
      }
    }

    final report = _buildReport(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeRuns: homeRuns,
      awayRuns: awayRuns,
      gamePlan: gamePlan,
    );

    return MatchResult(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeRuns: homeRuns,
      awayRuns: awayRuns,
      innings: innings,
      keyMoments: keyMoments.take(5).toList(),
      report: report,
      recommendations: _buildRecommendations(gamePlan, homeRuns > awayRuns),
    );
  }

  _HalfInningResult _simulateHalfInning({
    required Team battingTeam,
    required Team pitchingTeam,
    required int pitcherStamina,
    required BattingApproach battingApproach,
    required BullpenApproach bullpenApproach,
    required int inning,
    required bool isBottom,
    required List<String> keyMoments,
  }) {
    var outs = 0;
    var runs = 0;
    var bases = 0;
    var remainingStamina = max(0, pitcherStamina - 8 - _random.nextInt(8));
    final usesBullpen =
        inning >= 7 &&
        (bullpenApproach == BullpenApproach.quickHook ||
            remainingStamina < 24 ||
            (bullpenApproach == BullpenApproach.normal && _random.nextBool()));

    final pitcher = usesBullpen
        ? pitchingTeam.bullpen.first
        : pitchingTeam.rotation.first;
    final pitcherScore = usesBullpen
        ? (pitcher.stuff * 0.35 +
              pitcher.control * 0.3 +
              pitcher.groundBall * 0.2 -
              pitcher.fatigue * 0.18)
        : (pitcher.stuff * 0.32 +
              pitcher.control * 0.28 +
              remainingStamina * 0.18 +
              pitcher.groundBall * 0.14);

    if (usesBullpen && isBottom) {
      keyMoments.add(
        '$inning回、${pitchingTeam.shortName}が${pitcher.name}を投入。継投判断が勝負所になりました。',
      );
    }

    var batterIndex = (inning - 1) * 3;
    while (outs < 3) {
      final batter =
          battingTeam.lineup[batterIndex % battingTeam.lineup.length];
      batterIndex++;
      final result = _plateAppearance(
        batter: batter,
        pitcherScore: pitcherScore,
        battingApproach: battingApproach,
        ballpark: battingTeam.ballpark,
      );

      switch (result) {
        case PlateAppearanceResult.strikeout:
        case PlateAppearanceResult.groundOut:
        case PlateAppearanceResult.flyOut:
          outs++;
        case PlateAppearanceResult.walk:
          if (bases == 7) {
            runs++;
          } else {
            bases = ((bases << 1) | 1) & 7;
          }
        case PlateAppearanceResult.single:
          final scored = (bases & 4) != 0 ? 1 : 0;
          runs += scored;
          bases = ((bases << 1) | 1) & 7;
          if (scored == 1 && inning >= 7) {
            keyMoments.add('$inning回、${batter.name}の単打で終盤の1点を取り切りました。');
          }
        case PlateAppearanceResult.doubleHit:
          runs += _countRunners(bases & 6);
          bases = ((bases & 1) << 2) | 2;
          if (inning >= 6) {
            keyMoments.add('$inning回、${batter.name}の長打で得点期待値が跳ね上がりました。');
          }
        case PlateAppearanceResult.homeRun:
          runs += _countRunners(bases) + 1;
          bases = 0;
          keyMoments.add('$inning回、${batter.name}の一発。ロースコア想定を崩す大きな得点でした。');
        case PlateAppearanceResult.error:
          if (bases == 7) {
            runs++;
          }
          bases = ((bases << 1) | 1) & 7;
          keyMoments.add('$inning回、相手守備の乱れを突いてチャンスを広げました。');
      }

      if (runs >= 6) {
        outs = 3;
      }
    }

    return _HalfInningResult(runs: runs, remainingStamina: remainingStamina);
  }

  PlateAppearanceResult _plateAppearance({
    required Player batter,
    required double pitcherScore,
    required BattingApproach battingApproach,
    required String ballpark,
  }) {
    final approachContactBonus = switch (battingApproach) {
      BattingApproach.balanced => 0,
      BattingApproach.smallBall => 7,
      BattingApproach.power => -5,
    };
    final approachPowerBonus = switch (battingApproach) {
      BattingApproach.balanced => 0,
      BattingApproach.smallBall => -8,
      BattingApproach.power => 10,
    };
    final domePowerPenalty = ballpark.contains('バンテリン') ? 4 : 0;
    final contact =
        batter.contact + approachContactBonus + batter.condition * 0.8;
    final power = batter.power + approachPowerBonus - domePowerPenalty;
    final eye = batter.eye + batter.condition * 0.4;
    final matchup =
        contact * 0.42 +
        power * 0.24 +
        eye * 0.2 +
        batter.speed * 0.08 -
        pitcherScore;
    final roll = _random.nextDouble();
    final onBaseBase = (0.30 + matchup / 280).clamp(0.18, 0.46);
    final powerBase = (0.08 + power / 900).clamp(0.04, 0.18);

    if (roll < 0.055 + (80 - eye).clamp(-20, 25) / 1000) {
      return PlateAppearanceResult.strikeout;
    }
    if (roll < 0.11 + eye / 1200) {
      return PlateAppearanceResult.walk;
    }
    if (roll < onBaseBase) {
      final hitRoll = _random.nextDouble();
      if (hitRoll < powerBase * 0.28) {
        return PlateAppearanceResult.homeRun;
      }
      if (hitRoll < powerBase) {
        return PlateAppearanceResult.doubleHit;
      }
      return PlateAppearanceResult.single;
    }
    if (_random.nextDouble() < 0.018) {
      return PlateAppearanceResult.error;
    }
    return _random.nextBool()
        ? PlateAppearanceResult.groundOut
        : PlateAppearanceResult.flyOut;
  }

  int _countRunners(int bases) {
    var count = 0;
    for (var bit = 0; bit < 3; bit++) {
      if ((bases & (1 << bit)) != 0) {
        count++;
      }
    }
    return count;
  }

  List<String> _buildReport({
    required Team homeTeam,
    required Team awayTeam,
    required int homeRuns,
    required int awayRuns,
    required GamePlan gamePlan,
  }) {
    final won = homeRuns > awayRuns;
    final result = won ? '勝利' : '敗戦';
    final runGap = (homeRuns - awayRuns).abs();
    final gameShape = runGap <= 1 ? '接戦' : '点差のある展開';
    final battingText = switch (gamePlan.battingApproach) {
      BattingApproach.balanced => '打線はバランス型。出塁と長打の両方を狙いました。',
      BattingApproach.smallBall => '打線は小技重視。バンテリンドームで1点を取りに行く設計です。',
      BattingApproach.power => '打線は長打狙い。得点力不足を一発で補う狙いです。',
    };
    final bullpenText = switch (gamePlan.bullpenApproach) {
      BullpenApproach.normal => '継投は通常運用。先発と勝ちパターンの消耗を抑えます。',
      BullpenApproach.quickHook => '継投は早め。終盤の1点勝負に寄せました。',
      BullpenApproach.preserveArms => '継投は温存。連戦を意識しますが、終盤失点リスクは残ります。',
    };

    return [
      '${homeTeam.shortName}は${awayTeam.shortName}に$homeRuns-$awayRunsで$result。$gameShapeでした。',
      battingText,
      bullpenText,
      '${homeTeam.ballpark}想定のため、長打よりも守備、走塁、継投判断が勝敗に出やすい設計です。',
    ];
  }

  List<String> _buildRecommendations(GamePlan gamePlan, bool won) {
    if (won) {
      return ['次戦も同じ方針で入り、疲労が高いリリーフだけ入れ替える。', '若手の途中出場枠を1つ増やし、勝ちながら育成する。'];
    }

    return [
      gamePlan.battingApproach == BattingApproach.power
          ? '長打狙いで三振が増えたため、次戦は小技重視も試す。'
          : '得点期待値が低いため、上位打線に出塁型を固める。',
      gamePlan.bullpenApproach == BullpenApproach.preserveArms
          ? '温存采配で終盤失点が増えたため、接戦では早めの継投へ寄せる。'
          : '勝ちパターンの連投を避けるため、二軍から新しい中継ぎ候補を試す。',
    ];
  }
}

class _HalfInningResult {
  const _HalfInningResult({required this.runs, required this.remainingStamina});

  final int runs;
  final int remainingStamina;
}
