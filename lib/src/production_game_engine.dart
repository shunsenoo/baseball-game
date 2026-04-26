import 'dart:math';

import 'baseball_models.dart';

enum BaseOccupancy {
  empty('走者なし'),
  first('一塁'),
  second('二塁'),
  third('三塁'),
  firstSecond('一二塁'),
  firstThird('一三塁'),
  secondThird('二三塁'),
  loaded('満塁');

  const BaseOccupancy(this.label);

  final String label;

  bool get hasRunnerInScoringPosition =>
      this == second ||
      this == third ||
      this == firstSecond ||
      this == firstThird ||
      this == secondThird ||
      this == loaded;

  int get runnerCount => switch (this) {
    empty => 0,
    first || second || third => 1,
    firstSecond || firstThird || secondThird => 2,
    loaded => 3,
  };
}

enum AtBatOutcome {
  strikeout('三振'),
  walk('四球'),
  single('単打'),
  doubleHit('二塁打'),
  homeRun('本塁打'),
  groundOut('ゴロアウト'),
  flyOut('フライアウト'),
  sacrifice('犠打/犠飛'),
  doublePlay('併殺'),
  error('失策');

  const AtBatOutcome(this.label);

  final String label;
}

enum LineupIntent {
  onBaseFirst('出塁型上位'),
  powerFirst('長打型中軸'),
  developProspects('若手起用');

  const LineupIntent(this.label);

  final String label;
}

enum RunningIntent {
  conservative('無理しない'),
  aggressive('積極走塁'),
  smallBall('小技徹底');

  const RunningIntent(this.label);

  final String label;
}

enum DefensiveAlignment {
  standard('標準守備'),
  noDoubles('長打警戒'),
  infieldIn('内野前進');

  const DefensiveAlignment(this.label);

  final String label;
}

enum ClutchIntent {
  saveBullpen('ブルペン温存'),
  pinchHit('代打勝負'),
  fourOutCloser('抑え回跨ぎ');

  const ClutchIntent(this.label);

  final String label;
}

class ProductionGamePlan {
  const ProductionGamePlan({
    required this.battingApproach,
    required this.bullpenApproach,
    required this.lineupIntent,
    required this.runningIntent,
    required this.defensiveAlignment,
    required this.clutchIntent,
  });

  final BattingApproach battingApproach;
  final BullpenApproach bullpenApproach;
  final LineupIntent lineupIntent;
  final RunningIntent runningIntent;
  final DefensiveAlignment defensiveAlignment;
  final ClutchIntent clutchIntent;

  GamePlan get basicGamePlan => GamePlan(
    battingApproach: battingApproach,
    bullpenApproach: bullpenApproach,
  );
}

class GameSituation {
  const GameSituation({
    required this.inning,
    required this.isBottom,
    required this.outs,
    required this.bases,
    required this.homeRuns,
    required this.awayRuns,
  });

  final int inning;
  final bool isBottom;
  final int outs;
  final BaseOccupancy bases;
  final int homeRuns;
  final int awayRuns;

  int get runDifferential => homeRuns - awayRuns;

  bool get isLateCloseGame => inning >= 7 && runDifferential.abs() <= 2;

  bool get isHighLeverage =>
      isLateCloseGame || (bases.hasRunnerInScoringPosition && outs < 2);

  String get halfLabel => isBottom ? '裏' : '表';

  String get label =>
      '$inning回$halfLabel $outs死 ${bases.label} / $awayRuns-$homeRuns';
}

class AtBatResult {
  const AtBatResult({
    required this.batter,
    required this.pitcher,
    required this.situationBefore,
    required this.outcome,
    required this.runsScored,
    required this.outsRecorded,
    required this.basesAfter,
    required this.explanation,
  });

  final Player batter;
  final Pitcher pitcher;
  final GameSituation situationBefore;
  final AtBatOutcome outcome;
  final int runsScored;
  final int outsRecorded;
  final BaseOccupancy basesAfter;
  final String explanation;

  bool get changedGameState =>
      runsScored > 0 ||
      situationBefore.isHighLeverage ||
      outcome == AtBatOutcome.doublePlay;
}

class ProductionGameEvent {
  const ProductionGameEvent({
    required this.inning,
    required this.isBottom,
    required this.outsBefore,
    required this.basesBefore,
    required this.batterName,
    required this.pitcherName,
    required this.outcome,
    required this.runsScored,
    required this.explanation,
  });

  final int inning;
  final bool isBottom;
  final int outsBefore;
  final BaseOccupancy basesBefore;
  final String batterName;
  final String pitcherName;
  final AtBatOutcome outcome;
  final int runsScored;
  final String explanation;

  bool get isLeverage =>
      inning >= 7 || basesBefore.hasRunnerInScoringPosition || runsScored > 0;
}

class ProductionGameResult {
  const ProductionGameResult({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeRuns,
    required this.awayRuns,
    required this.innings,
    required this.events,
    required this.highlights,
    required this.recommendations,
  });

  final Team homeTeam;
  final Team awayTeam;
  final int homeRuns;
  final int awayRuns;
  final List<InningScore> innings;
  final List<ProductionGameEvent> events;
  final List<String> highlights;
  final List<String> recommendations;

  bool get homeWon => homeRuns > awayRuns;

  List<ProductionGameEvent> get leverageEvents =>
      events.where((event) => event.isLeverage).toList();

  String get scoreLine =>
      '${awayTeam.shortName} $awayRuns - $homeRuns ${homeTeam.shortName}';
}

class HalfInningResult {
  const HalfInningResult({
    required this.runs,
    required this.atBats,
    required this.keyMoments,
  });

  final int runs;
  final List<AtBatResult> atBats;
  final List<String> keyMoments;
}

class ProductionGameEngine {
  ProductionGameEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ProductionGameResult simulate({
    required Team homeTeam,
    required Team awayTeam,
    required ProductionGamePlan plan,
  }) {
    final innings = <InningScore>[];
    final events = <ProductionGameEvent>[];
    final highlights = <String>[];
    var homeRuns = 0;
    var awayRuns = 0;
    var homeLineupIndex = _lineupStartIndex(plan.lineupIntent);
    var awayLineupIndex = 0;

    for (var inning = 1; inning <= 9; inning++) {
      final awayHalf = simulateHalfInning(
        battingTeam: awayTeam,
        pitchingTeam: homeTeam,
        inning: inning,
        isBottom: false,
        homeRuns: homeRuns,
        awayRuns: awayRuns,
        gamePlan: _opponentPlan(plan),
        lineupStartIndex: awayLineupIndex,
      );
      awayRuns += awayHalf.runs;
      awayLineupIndex += awayHalf.atBats.length;
      events.addAll(_eventsFromAtBats(awayHalf.atBats));
      highlights.addAll(awayHalf.keyMoments);

      final homeHalf = simulateHalfInning(
        battingTeam: homeTeam,
        pitchingTeam: awayTeam,
        inning: inning,
        isBottom: true,
        homeRuns: homeRuns,
        awayRuns: awayRuns,
        gamePlan: plan.basicGamePlan,
        lineupStartIndex: homeLineupIndex,
      );
      homeRuns += homeHalf.runs;
      homeLineupIndex += homeHalf.atBats.length;
      events.addAll(_eventsFromAtBats(homeHalf.atBats));
      highlights.addAll(homeHalf.keyMoments);

      final adjusted = _applyStrategicAdjustments(
        plan: plan,
        inning: inning,
        homeRuns: homeRuns,
        awayRuns: awayRuns,
      );
      homeRuns = adjusted.homeRuns;
      awayRuns = adjusted.awayRuns;
      highlights.addAll(adjusted.highlights);

      innings.add(InningScore(top: awayHalf.runs, bottom: homeHalf.runs));
    }

    if (homeRuns == awayRuns) {
      final clutchChance = switch (plan.clutchIntent) {
        ClutchIntent.pinchHit => 0.58,
        ClutchIntent.fourOutCloser => 0.55,
        ClutchIntent.saveBullpen => 0.46,
      };
      if (_random.nextDouble() < clutchChance) {
        homeRuns++;
        highlights.add('延長戦、${plan.clutchIntent.label}の方針が勝ち越し機を作りました。');
      } else {
        awayRuns++;
        highlights.add('延長戦、勝負所のリスクが出て勝ち越しを許しました。');
      }
    }

    return ProductionGameResult(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeRuns: homeRuns,
      awayRuns: awayRuns,
      innings: innings,
      events: events,
      highlights: highlights.take(8).toList(),
      recommendations: _buildProductionRecommendations(
        plan,
        homeRuns > awayRuns,
      ),
    );
  }

  int _lineupStartIndex(LineupIntent lineupIntent) => switch (lineupIntent) {
    LineupIntent.onBaseFirst => 0,
    LineupIntent.powerFirst => 2,
    LineupIntent.developProspects => 4,
  };

  GamePlan _opponentPlan(ProductionGamePlan plan) {
    final awayBatting = switch (plan.defensiveAlignment) {
      DefensiveAlignment.noDoubles => BattingApproach.smallBall,
      DefensiveAlignment.infieldIn => BattingApproach.power,
      DefensiveAlignment.standard => BattingApproach.balanced,
    };
    return GamePlan(
      battingApproach: awayBatting,
      bullpenApproach: BullpenApproach.normal,
    );
  }

  List<ProductionGameEvent> _eventsFromAtBats(List<AtBatResult> atBats) {
    return atBats.map((atBat) {
      final situation = atBat.situationBefore;
      return ProductionGameEvent(
        inning: situation.inning,
        isBottom: situation.isBottom,
        outsBefore: situation.outs,
        basesBefore: situation.bases,
        batterName: atBat.batter.name,
        pitcherName: atBat.pitcher.name,
        outcome: atBat.outcome,
        runsScored: atBat.runsScored,
        explanation: atBat.explanation,
      );
    }).toList();
  }

  _StrategicAdjustment _applyStrategicAdjustments({
    required ProductionGamePlan plan,
    required int inning,
    required int homeRuns,
    required int awayRuns,
  }) {
    var adjustedHomeRuns = homeRuns;
    var adjustedAwayRuns = awayRuns;
    final highlights = <String>[];

    if (inning >= 7 &&
        plan.defensiveAlignment == DefensiveAlignment.noDoubles) {
      if (_random.nextDouble() < 0.18) {
        adjustedAwayRuns = max(0, adjustedAwayRuns - 1);
        highlights.add('$inning回、長打警戒シフトで外野の頭を越される打球を防ぎました。');
      }
    }

    if (inning >= 7 &&
        plan.defensiveAlignment == DefensiveAlignment.infieldIn) {
      if (_random.nextDouble() < 0.16) {
        adjustedAwayRuns += 1;
        highlights.add('$inning回、前進守備の裏を突かれて追加点を許しました。');
      }
    }

    if (plan.runningIntent == RunningIntent.aggressive &&
        _random.nextDouble() < 0.12) {
      adjustedHomeRuns += 1;
      highlights.add('積極走塁で一つ先の塁を奪い、得点に結びつけました。');
    }

    if (plan.runningIntent == RunningIntent.smallBall &&
        inning >= 6 &&
        (adjustedHomeRuns - adjustedAwayRuns).abs() <= 1 &&
        _random.nextDouble() < 0.15) {
      adjustedHomeRuns += 1;
      highlights.add('$inning回、小技で接戦の1点をもぎ取りました。');
    }

    if (plan.lineupIntent == LineupIntent.powerFirst &&
        adjustedHomeRuns < 3 &&
        _random.nextDouble() < 0.12) {
      adjustedHomeRuns += 1;
      highlights.add('中軸集中の打順が終盤に長打を呼び込みました。');
    }

    if (plan.lineupIntent == LineupIntent.developProspects &&
        _random.nextDouble() < 0.08) {
      adjustedHomeRuns += 1;
      highlights.add('若手起用がサプライズの一打につながりました。');
    }

    return _StrategicAdjustment(
      homeRuns: adjustedHomeRuns,
      awayRuns: adjustedAwayRuns,
      highlights: highlights,
    );
  }

  List<String> _buildProductionRecommendations(
    ProductionGamePlan plan,
    bool won,
  ) {
    final recommendations = <String>[];
    if (won) {
      recommendations.add('勝てた方針を軸にしつつ、次戦は疲労が高い役割だけ入れ替える。');
    } else {
      recommendations.add('敗戦要因を打順、走塁、守備、勝負所のどこで取り返すか再設定する。');
    }

    switch (plan.lineupIntent) {
      case LineupIntent.onBaseFirst:
        recommendations.add('出塁型上位を継続し、3番以降の長打役を厚くする。');
      case LineupIntent.powerFirst:
        recommendations.add('長打型中軸で三振が増える場合、2番に出塁型を挟む。');
      case LineupIntent.developProspects:
        recommendations.add('若手起用日は守備シフトを保守的にして失点リスクを抑える。');
    }

    switch (plan.runningIntent) {
      case RunningIntent.conservative:
        recommendations.add('無理しない走塁で得点が伸びない時は、終盤だけ盗塁許可にする。');
      case RunningIntent.aggressive:
        recommendations.add('積極走塁は接戦向き。大量点狙いの日は長打型打順と組み合わせる。');
      case RunningIntent.smallBall:
        recommendations.add('小技徹底はバンテリンドーム向き。1点差の終盤に使う価値が高い。');
    }

    switch (plan.clutchIntent) {
      case ClutchIntent.saveBullpen:
        recommendations.add('ブルペン温存時は先発続投ラインを明確にし、炎上前に切り替える。');
      case ClutchIntent.pinchHit:
        recommendations.add('代打勝負はベンチ消費が重いので、相手左腕時に優先する。');
      case ClutchIntent.fourOutCloser:
        recommendations.add('抑え回跨ぎは連投管理とセットで使う。翌日は温存方針が必要。');
    }

    return recommendations;
  }

  HalfInningResult simulateHalfInning({
    required Team battingTeam,
    required Team pitchingTeam,
    required int inning,
    required bool isBottom,
    required int homeRuns,
    required int awayRuns,
    required GamePlan gamePlan,
    int lineupStartIndex = 0,
  }) {
    var outs = 0;
    var runs = 0;
    var bases = BaseOccupancy.empty;
    var batterIndex = lineupStartIndex;
    final atBats = <AtBatResult>[];
    final keyMoments = <String>[];
    final pitcher =
        inning >= 7 && gamePlan.bullpenApproach == BullpenApproach.quickHook
        ? pitchingTeam.bullpen.first
        : pitchingTeam.rotation.first;

    while (outs < 3 && atBats.length < 14) {
      final batter =
          battingTeam.lineup[batterIndex % battingTeam.lineup.length];
      batterIndex++;
      final situation = GameSituation(
        inning: inning,
        isBottom: isBottom,
        outs: outs,
        bases: bases,
        homeRuns: homeRuns + (isBottom ? runs : 0),
        awayRuns: awayRuns + (isBottom ? 0 : runs),
      );
      final result = simulateAtBat(
        batter: batter,
        pitcher: pitcher,
        situation: situation,
        gamePlan: gamePlan,
        ballpark: battingTeam.ballpark,
      );

      atBats.add(result);
      runs += result.runsScored;
      outs += result.outsRecorded;
      bases = result.basesAfter;

      if (result.changedGameState) {
        keyMoments.add(
          '${situation.label}: ${batter.name} ${result.outcome.label} - ${result.explanation}',
        );
      }
    }

    return HalfInningResult(
      runs: runs,
      atBats: atBats,
      keyMoments: keyMoments.take(4).toList(),
    );
  }

  AtBatResult simulateAtBat({
    required Player batter,
    required Pitcher pitcher,
    required GameSituation situation,
    required GamePlan gamePlan,
    required String ballpark,
  }) {
    final matchupScore = _matchupScore(
      batter: batter,
      pitcher: pitcher,
      gamePlan: gamePlan,
      ballpark: ballpark,
      situation: situation,
    );
    final roll = _random.nextDouble();
    final walkChance = (0.075 + batter.eye / 1800 - pitcher.control / 2500)
        .clamp(0.04, 0.13);
    final strikeoutChance =
        (0.12 + pitcher.stuff / 1600 - batter.contact / 1800).clamp(0.06, 0.22);
    final hitChance = (0.25 + matchupScore / 520).clamp(0.16, 0.42);
    final homerChance =
        (0.025 +
                batter.power / 2600 +
                (gamePlan.battingApproach == BattingApproach.power ? 0.018 : 0))
            .clamp(0.015, 0.09);

    late final AtBatOutcome outcome;
    if (roll < strikeoutChance) {
      outcome = AtBatOutcome.strikeout;
    } else if (roll < strikeoutChance + walkChance) {
      outcome = AtBatOutcome.walk;
    } else if (roll < strikeoutChance + walkChance + hitChance) {
      final hitRoll = _random.nextDouble();
      if (hitRoll < homerChance) {
        outcome = AtBatOutcome.homeRun;
      } else if (hitRoll < 0.20 + batter.power / 900) {
        outcome = AtBatOutcome.doubleHit;
      } else {
        outcome = AtBatOutcome.single;
      }
    } else if (_shouldAttemptSacrifice(situation, gamePlan)) {
      outcome = AtBatOutcome.sacrifice;
    } else if (situation.bases.runnerCount >= 1 &&
        situation.outs <= 1 &&
        _random.nextDouble() < 0.11) {
      outcome = AtBatOutcome.doublePlay;
    } else if (_random.nextDouble() < 0.018) {
      outcome = AtBatOutcome.error;
    } else {
      outcome = pitcher.groundBall + _random.nextInt(30) > 78
          ? AtBatOutcome.groundOut
          : AtBatOutcome.flyOut;
    }

    final advancement = _advanceRunners(
      situation.bases,
      outcome,
      situation.outs,
    );
    return AtBatResult(
      batter: batter,
      pitcher: pitcher,
      situationBefore: situation,
      outcome: outcome,
      runsScored: advancement.runs,
      outsRecorded: min(3 - situation.outs, advancement.outs),
      basesAfter: advancement.bases,
      explanation: _explainOutcome(outcome, situation, gamePlan),
    );
  }

  double _matchupScore({
    required Player batter,
    required Pitcher pitcher,
    required GamePlan gamePlan,
    required String ballpark,
    required GameSituation situation,
  }) {
    final approachBonus = switch (gamePlan.battingApproach) {
      BattingApproach.balanced => 0,
      BattingApproach.smallBall =>
        situation.bases.hasRunnerInScoringPosition ? 8 : 3,
      BattingApproach.power => situation.isHighLeverage ? 10 : 4,
    };
    final domePenalty = ballpark.contains('バンテリン') ? 5 : 0;
    final leverageBonus = situation.isHighLeverage
        ? batter.condition * 1.4
        : batter.condition * 0.7;
    return batter.contact * 0.44 +
        batter.power * 0.26 +
        batter.eye * 0.20 +
        batter.speed * 0.08 +
        approachBonus +
        leverageBonus -
        pitcher.stuff * 0.30 -
        pitcher.control * 0.24 -
        pitcher.groundBall * 0.10 -
        pitcher.fatigue * 0.20 -
        domePenalty;
  }

  bool _shouldAttemptSacrifice(GameSituation situation, GamePlan gamePlan) {
    return gamePlan.battingApproach == BattingApproach.smallBall &&
        situation.outs == 0 &&
        situation.bases.runnerCount > 0 &&
        situation.runDifferential.abs() <= 2;
  }

  _BaseAdvance _advanceRunners(
    BaseOccupancy bases,
    AtBatOutcome outcome,
    int outsBefore,
  ) {
    final runners = _baseOccupancyToBits(bases);
    switch (outcome) {
      case AtBatOutcome.strikeout:
      case AtBatOutcome.groundOut:
      case AtBatOutcome.flyOut:
        return _BaseAdvance(bases: bases, runs: 0, outs: 1);
      case AtBatOutcome.doublePlay:
        return _BaseAdvance(
          bases: BaseOccupancy.empty,
          runs: 0,
          outs: outsBefore == 0 ? 2 : 1,
        );
      case AtBatOutcome.sacrifice:
        return _advanceBy(runners, 1, batterReaches: false, outs: 1);
      case AtBatOutcome.walk:
      case AtBatOutcome.error:
        return _advanceBy(
          runners,
          1,
          batterReaches: true,
          outs: 0,
          forceOnly: true,
        );
      case AtBatOutcome.single:
        return _advanceBy(runners, 1, batterReaches: true, outs: 0);
      case AtBatOutcome.doubleHit:
        return _advanceBy(runners, 2, batterReaches: true, outs: 0);
      case AtBatOutcome.homeRun:
        return _BaseAdvance(
          bases: BaseOccupancy.empty,
          runs: bases.runnerCount + 1,
          outs: 0,
        );
    }
  }

  _BaseAdvance _advanceBy(
    int runners,
    int basesToAdvance, {
    required bool batterReaches,
    required int outs,
    bool forceOnly = false,
  }) {
    var runs = 0;
    var next = 0;
    for (var base = 2; base >= 0; base--) {
      if ((runners & (1 << base)) == 0) {
        continue;
      }
      final destination = forceOnly ? base + 1 : base + basesToAdvance;
      if (destination >= 3) {
        runs++;
      } else {
        next |= 1 << destination;
      }
    }
    if (batterReaches) {
      if ((next & 1) != 0 && forceOnly) {
        next |= 2;
      }
      next |= 1;
    }
    return _BaseAdvance(
      bases: _bitsToBaseOccupancy(next),
      runs: runs,
      outs: outs,
    );
  }

  int _baseOccupancyToBits(BaseOccupancy bases) => switch (bases) {
    BaseOccupancy.empty => 0,
    BaseOccupancy.first => 1,
    BaseOccupancy.second => 2,
    BaseOccupancy.third => 4,
    BaseOccupancy.firstSecond => 3,
    BaseOccupancy.firstThird => 5,
    BaseOccupancy.secondThird => 6,
    BaseOccupancy.loaded => 7,
  };

  BaseOccupancy _bitsToBaseOccupancy(int bits) => switch (bits & 7) {
    0 => BaseOccupancy.empty,
    1 => BaseOccupancy.first,
    2 => BaseOccupancy.second,
    3 => BaseOccupancy.firstSecond,
    4 => BaseOccupancy.third,
    5 => BaseOccupancy.firstThird,
    6 => BaseOccupancy.secondThird,
    _ => BaseOccupancy.loaded,
  };

  String _explainOutcome(
    AtBatOutcome outcome,
    GameSituation situation,
    GamePlan gamePlan,
  ) {
    if (situation.isHighLeverage) {
      return switch (outcome) {
        AtBatOutcome.homeRun || AtBatOutcome.doubleHit => '勝負所で長打が出て試合が動きました。',
        AtBatOutcome.single || AtBatOutcome.walk => '高レバレッジで走者を進める判断が効きました。',
        AtBatOutcome.sacrifice => '1点を取りに行く小技が状況に合いました。',
        AtBatOutcome.doublePlay => '勝負所で併殺となり、采配リスクが表面化しました。',
        _ => '重要局面でしたが、相手バッテリーに抑えられました。',
      };
    }
    return switch (gamePlan.battingApproach) {
      BattingApproach.smallBall => '小技重視の方針が打席結果に反映されました。',
      BattingApproach.power => '長打狙いの方針で打球結果の振れ幅が大きくなりました。',
      BattingApproach.balanced => '標準方針でリスクを抑えた打席になりました。',
    };
  }
}

class _BaseAdvance {
  const _BaseAdvance({
    required this.bases,
    required this.runs,
    required this.outs,
  });

  final BaseOccupancy bases;
  final int runs;
  final int outs;
}

class _StrategicAdjustment {
  const _StrategicAdjustment({
    required this.homeRuns,
    required this.awayRuns,
    required this.highlights,
  });

  final int homeRuns;
  final int awayRuns;
  final List<String> highlights;
}
