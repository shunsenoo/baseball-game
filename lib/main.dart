import 'package:flutter/material.dart';

import 'src/baseball_models.dart';
import 'src/baseball_simulator.dart';

void main() {
  runApp(const BaseballGameApp());
}

enum FrontOfficeMove {
  restBullpen('リリーフ休養', '終盤失点リスクを下げるが、育成ポイントは伸びにくい'),
  trainProspect('若手強化', '短期勝率より将来性。勝てばファン支持が大きく伸びる'),
  boostLineup('得点力テコ入れ', '打線にボーナス。失敗するとオーナー評価が下がる');

  const FrontOfficeMove(this.label, this.description);

  final String label;
  final String description;
}

class BaseballGameApp extends StatelessWidget {
  const BaseballGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    const dragonsBlue = Color(0xFF003B7A);

    return MaterialApp(
      title: 'プロ野球フロントライン 技術検証版',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: dragonsBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFE7E1C4),
        fontFamily: 'monospace',
        cardTheme: CardThemeData(
          color: const Color(0xFFFFF7D6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: Color(0xFF18213A), width: 3),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            backgroundColor: dragonsBlue,
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const PrototypeHomePage(),
    );
  }
}

class PrototypeHomePage extends StatefulWidget {
  const PrototypeHomePage({super.key});

  @override
  State<PrototypeHomePage> createState() => _PrototypeHomePageState();
}

class _PrototypeHomePageState extends State<PrototypeHomePage> {
  static const _seasonLength = 10;

  final BaseballSimulator _simulator = BaseballSimulator();
  GamePlan _gamePlan = const GamePlan(
    battingApproach: BattingApproach.balanced,
    bullpenApproach: BullpenApproach.normal,
  );
  FrontOfficeMove _frontOfficeMove = FrontOfficeMove.restBullpen;
  MatchResult? _result;
  int _game = 0;
  int _wins = 0;
  int _losses = 0;
  int _fanSupport = 52;
  int _ownerTrust = 50;
  int _developmentPoints = 0;
  int _bullpenFatigue = 18;
  List<String> _lastRewards = const ['采配方針を決めて、10試合チャレンジを始めよう。'];

  String get _mission {
    if (_game % 3 == 0) {
      return 'ミッション: 3点以上取って得点力不足を払拭';
    }
    if (_game % 3 == 1) {
      return 'ミッション: 接戦を制してファン支持率+5';
    }
    return 'ミッション: リリーフ疲労を35以下に抑える';
  }

  bool get _seasonFinished => _game >= _seasonLength;

  String get _recommendedPlan {
    if (_bullpenFatigue >= 45) {
      return 'おすすめ: リリーフ温存 + つなぐ野球';
    }
    if (_mission.contains('3点以上')) {
      return 'おすすめ: 得点力テコ入れ + 長打狙い';
    }
    if (_mission.contains('接戦')) {
      return 'おすすめ: 早めの継投 + つなぐ野球';
    }
    return 'おすすめ: 通常運用 + バランス重視';
  }

  List<String> get _decisionFactors {
    return [
      '相手先発: 左の技巧派。制球が高く、長打狙いは三振リスクも上がる。',
      '球場: バンテリンドーム想定。長打より出塁、守備、継投の価値が高い。',
      '自軍状態: リリーフ疲労$_bullpenFatigue%。45%以上なら温存、30%以下なら早めの継投も選びやすい。',
      '今日の目標: $_mission',
    ];
  }

  List<String> get _selectedPlanEffects {
    final batting = switch (_gamePlan.battingApproach) {
      BattingApproach.balanced => '攻撃: 出塁と長打のバランス型。大崩れしにくいが爆発力は中程度。',
      BattingApproach.smallBall => '攻撃: 接戦向き。2点前後を取りに行きやすいが大量点は出にくい。',
      BattingApproach.power => '攻撃: 3点以上ミッション向き。成功時の支持率上昇が大きいが凡退も増える。',
    };
    final bullpen = switch (_gamePlan.bullpenApproach) {
      BullpenApproach.normal => '継投: 消耗と勝率の中間。迷った時の基準方針。',
      BullpenApproach.quickHook => '継投: 接戦勝利向き。終盤失点を抑える代わりにリリーフ疲労が増える。',
      BullpenApproach.preserveArms => '継投: 連戦向き。疲労は下がるが終盤失点リスクが残る。',
    };
    final front = switch (_frontOfficeMove) {
      FrontOfficeMove.restBullpen => '施策: リリーフ疲労を抑える。接戦続きの時に有効。',
      FrontOfficeMove.trainProspect => '施策: 育成ポイント重視。勝てばファン支持も伸びる。',
      FrontOfficeMove.boostLineup => '施策: 得点力ミッション向き。3点未満だと評価が下がりやすい。',
    };
    return [batting, bullpen, front];
  }

  void _updateBattingApproach(BattingApproach? approach) {
    if (approach == null) {
      return;
    }
    setState(() {
      _gamePlan = GamePlan(
        battingApproach: approach,
        bullpenApproach: _gamePlan.bullpenApproach,
      );
    });
  }

  void _updateBullpenApproach(BullpenApproach? approach) {
    if (approach == null) {
      return;
    }
    setState(() {
      _gamePlan = GamePlan(
        battingApproach: _gamePlan.battingApproach,
        bullpenApproach: approach,
      );
    });
  }

  void _updateFrontOfficeMove(FrontOfficeMove? move) {
    if (move == null) {
      return;
    }
    setState(() {
      _frontOfficeMove = move;
    });
  }

  void _simulateGame() {
    if (_seasonFinished) {
      return;
    }

    final result = _simulator.simulate(
      homeTeam: DemoTeams.dragons,
      awayTeam: DemoTeams.tokyo,
      gamePlan: _gamePlan,
    );
    final won = result.homeWon;
    final closeGame = (result.homeRuns - result.awayRuns).abs() <= 1;
    final rewards = <String>[];

    var fanDelta = won ? 4 : -3;
    var ownerDelta = won ? 3 : -2;
    var developmentDelta = won ? 2 : 1;
    var fatigueDelta = switch (_gamePlan.bullpenApproach) {
      BullpenApproach.quickHook => 9,
      BullpenApproach.normal => 5,
      BullpenApproach.preserveArms => -4,
    };

    switch (_frontOfficeMove) {
      case FrontOfficeMove.restBullpen:
        fatigueDelta -= 8;
        ownerDelta += closeGame && won ? 1 : 0;
        rewards.add('リリーフ休養でブルペン疲労を抑えました。');
      case FrontOfficeMove.trainProspect:
        developmentDelta += 5;
        fanDelta += won ? 2 : -1;
        rewards.add('若手強化で育成ポイントを大きく獲得しました。');
      case FrontOfficeMove.boostLineup:
        fanDelta += result.homeRuns >= 3 ? 4 : -2;
        ownerDelta += result.homeRuns >= 3 ? 2 : -3;
        rewards.add(result.homeRuns >= 3 ? '打線テコ入れが成功しました。' : '打線テコ入れは不発でした。');
    }

    final missionCleared =
        (_game % 3 == 0 && result.homeRuns >= 3) ||
        (_game % 3 == 1 && won && closeGame) ||
        (_game % 3 == 2 && _bullpenFatigue + fatigueDelta <= 35);
    if (missionCleared) {
      fanDelta += 5;
      developmentDelta += 2;
      rewards.add('今日のミッション達成。ファン支持率と育成ポイントが上昇。');
    } else {
      rewards.add('ミッション未達。次戦の方針を変える余地があります。');
    }

    setState(() {
      _result = result;
      _game++;
      if (won) {
        _wins++;
      } else {
        _losses++;
      }
      _fanSupport = (_fanSupport + fanDelta).clamp(0, 100);
      _ownerTrust = (_ownerTrust + ownerDelta).clamp(0, 100);
      _developmentPoints = (_developmentPoints + developmentDelta).clamp(
        0,
        999,
      );
      _bullpenFatigue = (_bullpenFatigue + fatigueDelta).clamp(0, 100);
      _lastRewards = rewards;
    });
  }

  void _resetSeason() {
    setState(() {
      _result = null;
      _game = 0;
      _wins = 0;
      _losses = 0;
      _fanSupport = 52;
      _ownerTrust = 50;
      _developmentPoints = 0;
      _bullpenFatigue = 18;
      _lastRewards = const ['采配方針を決めて、10試合チャレンジを始めよう。'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロ野球フロントライン 技術検証版'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            result: _result,
            game: _game,
            seasonLength: _seasonLength,
            wins: _wins,
            losses: _losses,
          ),
          const SizedBox(height: 16),
          _SeasonStatusCard(
            fanSupport: _fanSupport,
            ownerTrust: _ownerTrust,
            developmentPoints: _developmentPoints,
            bullpenFatigue: _bullpenFatigue,
          ),
          const SizedBox(height: 16),
          _MissionCard(mission: _mission, rewards: _lastRewards),
          const SizedBox(height: 16),
          _PixelGameAnimationCard(result: _result),
          const SizedBox(height: 16),
          _DecisionSupportCard(
            recommendedPlan: _recommendedPlan,
            factors: _decisionFactors,
            selectedPlanEffects: _selectedPlanEffects,
          ),
          const SizedBox(height: 16),
          _PlanCard(
            gamePlan: _gamePlan,
            frontOfficeMove: _frontOfficeMove,
            seasonFinished: _seasonFinished,
            onBattingChanged: _updateBattingApproach,
            onBullpenChanged: _updateBullpenApproach,
            onFrontOfficeChanged: _updateFrontOfficeMove,
            onSimulate: _simulateGame,
            onReset: _resetSeason,
          ),
          const SizedBox(height: 16),
          _TeamFocusCard(team: DemoTeams.dragons),
          const SizedBox(height: 16),
          if (_result != null) ...[
            _PixelGameAnimationCard(result: _result!),
            const SizedBox(height: 16),
            _ScoreboardCard(result: _result!),
            const SizedBox(height: 16),
            _ReportCard(result: _result!),
            const SizedBox(height: 16),
          ],
          const _LicenseNoticeCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.result,
    required this.game,
    required this.seasonLength,
    required this.wins,
    required this.losses,
  });

  final MatchResult? result;
  final int game;
  final int seasonLength;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = result == null
        ? '10試合でドラゴンズを立て直せ'
        : result!.homeWon
        ? '采配成功、接戦を制す'
        : '課題が残る敗戦';
    final scoreLine = result?.scoreLine ?? '開幕前: $wins勝$losses敗';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '中日ドラゴンズ風チーム ゲーム検証',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scoreLine,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '第$game/$seasonLength戦  $wins勝$losses敗。ミッションと資源管理で短期シーズンを戦います。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonStatusCard extends StatelessWidget {
  const _SeasonStatusCard({
    required this.fanSupport,
    required this.ownerTrust,
    required this.developmentPoints,
    required this.bullpenFatigue,
  });

  final int fanSupport;
  final int ownerTrust;
  final int developmentPoints;
  final int bullpenFatigue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('球団状態', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(label: 'ファン支持率', value: '$fanSupport%'),
                _MetricTile(label: 'オーナー評価', value: '$ownerTrust%'),
                _MetricTile(label: '育成ポイント', value: '$developmentPoints'),
                _MetricTile(label: 'リリーフ疲労', value: '$bullpenFatigue%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.rewards});

  final String mission;
  final List<String> rewards;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('前回の報酬/結果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final reward in rewards) _BulletText(reward),
          ],
        ),
      ),
    );
  }
}

class _DecisionSupportCard extends StatelessWidget {
  const _DecisionSupportCard({
    required this.recommendedPlan,
    required this.factors,
    required this.selectedPlanEffects,
  });

  final String recommendedPlan;
  final List<String> factors;
  final List<String> selectedPlanEffects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('試合前分析', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              recommendedPlan,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('判断材料', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final factor in factors) _BulletText(factor),
            const Divider(height: 28),
            Text('選択中の方針による予測効果', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final effect in selectedPlanEffects) _BulletText(effect),
          ],
        ),
      ),
    );
  }
}

class _TeamFocusCard extends StatelessWidget {
  const _TeamFocusCard({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${team.ballpark} / チーム課題'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: team.seasonFocus
                  .map((focus) => Chip(label: Text(focus)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.gamePlan,
    required this.frontOfficeMove,
    required this.seasonFinished,
    required this.onBattingChanged,
    required this.onBullpenChanged,
    required this.onFrontOfficeChanged,
    required this.onSimulate,
    required this.onReset,
  });

  final GamePlan gamePlan;
  final FrontOfficeMove frontOfficeMove;
  final bool seasonFinished;
  final ValueChanged<BattingApproach?> onBattingChanged;
  final ValueChanged<BullpenApproach?> onBullpenChanged;
  final ValueChanged<FrontOfficeMove?> onFrontOfficeChanged;
  final VoidCallback onSimulate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日の采配方針', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<BattingApproach>(
              initialValue: gamePlan.battingApproach,
              decoration: const InputDecoration(labelText: '攻撃方針'),
              items: BattingApproach.values
                  .map(
                    (approach) => DropdownMenuItem(
                      value: approach,
                      child: Text(approach.label),
                    ),
                  )
                  .toList(),
              onChanged: onBattingChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BullpenApproach>(
              initialValue: gamePlan.bullpenApproach,
              decoration: const InputDecoration(labelText: '継投方針'),
              items: BullpenApproach.values
                  .map(
                    (approach) => DropdownMenuItem(
                      value: approach,
                      child: Text(approach.label),
                    ),
                  )
                  .toList(),
              onChanged: onBullpenChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FrontOfficeMove>(
              initialValue: frontOfficeMove,
              decoration: const InputDecoration(labelText: '試合前フロント施策'),
              items: FrontOfficeMove.values
                  .map(
                    (move) =>
                        DropdownMenuItem(value: move, child: Text(move.label)),
                  )
                  .toList(),
              onChanged: onFrontOfficeChanged,
            ),
            const SizedBox(height: 8),
            Text(frontOfficeMove.description),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: seasonFinished ? onReset : onSimulate,
                icon: Icon(
                  seasonFinished ? Icons.restart_alt : Icons.sports_baseball,
                ),
                label: Text(seasonFinished ? '10試合チャレンジをリセット' : '次の試合へ進む'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreboardCard extends StatelessWidget {
  const _ScoreboardCard({required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('スコアボード', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Team')),
                  for (var i = 1; i <= result.innings.length; i++)
                    DataColumn(label: Text('$i')),
                  const DataColumn(label: Text('R')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text(result.awayTeam.shortName)),
                      ...result.innings.map((inning) {
                        return DataCell(Text('${inning.top}'));
                      }),
                      DataCell(Text('${result.awayRuns}')),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text(result.homeTeam.shortName)),
                      ...result.innings.map((inning) {
                        return DataCell(Text('${inning.bottom}'));
                      }),
                      DataCell(Text('${result.homeRuns}')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelGameAnimationCard extends StatelessWidget {
  const _PixelGameAnimationCard({required this.result});

  final MatchResult? result;

  @override
  Widget build(BuildContext context) {
    final hasResult = result != null;
    final animationKey = hasResult
        ? '${result!.homeRuns}-${result!.awayRuns}-${result!.innings.hashCode}'
        : 'pregame';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ドット絵リプレイ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              !hasResult
                  ? '試合を進めると、投球、打球、走者進塁をブロック調で再生します。'
                  : result!.homeWon
                  ? '打球が外野へ抜け、ホームが湧く演出です。'
                  : '守備側に抑え込まれた展開を表示します。',
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(animationKey),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.linear,
                builder: (context, progress, _) {
                  final steppedProgress = (progress * 12).floor() / 12;
                  return CustomPaint(
                    painter: _PixelFieldPainter(
                      progress: steppedProgress.clamp(0, 1).toDouble(),
                      homeWon: result?.homeWon ?? true,
                      homeRuns: result?.homeRuns ?? 0,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelFieldPainter extends CustomPainter {
  const _PixelFieldPainter({
    required this.progress,
    required this.homeWon,
    required this.homeRuns,
  });

  final double progress;
  final bool homeWon;
  final int homeRuns;

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = size.shortestSide / 34;
    final borderPaint = Paint()..color = const Color(0xFF18213A);
    final grassPaint = Paint()..color = const Color(0xFF4F8F3A);
    final dirtPaint = Paint()..color = const Color(0xFFC68D4C);
    final linePaint = Paint()
      ..color = const Color(0xFFFFF7D6)
      ..strokeWidth = pixel * 0.45
      ..style = PaintingStyle.stroke;
    final basePaint = Paint()..color = const Color(0xFFFFF7D6);
    final playerPaint = Paint()..color = const Color(0xFF003B7A);
    final rivalPaint = Paint()..color = const Color(0xFFB3261E);
    final ballPaint = Paint()..color = const Color(0xFFFFFFFF);
    final shadowPaint = Paint()..color = const Color(0x55000000);

    canvas.drawRect(Offset.zero & size, borderPaint);
    final field = Rect.fromLTWH(
      pixel,
      pixel,
      size.width - pixel * 2,
      size.height - pixel * 2,
    );
    canvas.drawRect(field, grassPaint);

    final home = Offset(size.width * 0.50, size.height * 0.78);
    final first = Offset(size.width * 0.68, size.height * 0.60);
    final second = Offset(size.width * 0.50, size.height * 0.43);
    final third = Offset(size.width * 0.32, size.height * 0.60);
    final mound = Offset(size.width * 0.50, size.height * 0.62);
    final outfield = homeWon
        ? Offset(size.width * 0.73, size.height * 0.25)
        : Offset(size.width * 0.43, size.height * 0.30);

    final infield = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(first.dx, first.dy)
      ..lineTo(second.dx, second.dy)
      ..lineTo(third.dx, third.dy)
      ..close();
    canvas.drawPath(infield, dirtPaint);
    canvas.drawPath(infield, linePaint);
    canvas.drawLine(
      home,
      Offset(size.width * 0.18, size.height * 0.23),
      linePaint,
    );
    canvas.drawLine(
      home,
      Offset(size.width * 0.82, size.height * 0.23),
      linePaint,
    );

    for (final base in [home, first, second, third]) {
      canvas.drawRect(
        Rect.fromCenter(center: base, width: pixel * 2, height: pixel * 2),
        basePaint,
      );
    }

    void drawPlayer(Offset position, Paint paint) {
      canvas.drawRect(
        Rect.fromCenter(
          center: position + Offset(pixel * 0.35, pixel * 0.35),
          width: pixel * 2.2,
          height: pixel * 2.2,
        ),
        shadowPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: position,
          width: pixel * 2.2,
          height: pixel * 2.2,
        ),
        paint,
      );
    }

    drawPlayer(mound, rivalPaint);
    drawPlayer(Offset(size.width * 0.25, size.height * 0.34), rivalPaint);
    drawPlayer(Offset(size.width * 0.75, size.height * 0.34), rivalPaint);
    drawPlayer(home + Offset(-pixel * 3.2, pixel * 1.4), playerPaint);

    final runnerPath = homeWon
        ? [home, first, second, third, home]
        : [home, first];
    final runner = _pointOnPath(runnerPath, progress);
    drawPlayer(runner, playerPaint);

    final ballPath = progress < 0.35
        ? Offset.lerp(mound, home, progress / 0.35)!
        : Offset.lerp(home, outfield, ((progress - 0.35) / 0.65).clamp(0, 1))!;
    canvas.drawRect(
      Rect.fromCenter(
        center: ballPath,
        width: pixel * (homeRuns >= 3 ? 1.7 : 1.3),
        height: pixel * (homeRuns >= 3 ? 1.7 : 1.3),
      ),
      ballPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: homeWon ? 'HIT!' : 'OUT?',
        style: TextStyle(
          color: const Color(0xFFFFF7D6),
          fontFamily: 'monospace',
          fontSize: pixel * 2.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pixel * 2, pixel * 2));
  }

  Offset _pointOnPath(List<Offset> points, double progress) {
    if (points.length == 1) {
      return points.first;
    }
    final scaled = progress.clamp(0, 1).toDouble() * (points.length - 1);
    final index = scaled.floor().clamp(0, points.length - 2);
    final local = (scaled - index).toDouble();
    return Offset.lerp(points[index], points[index + 1], local)!;
  }

  @override
  bool shouldRepaint(covariant _PixelFieldPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.homeWon != homeWon ||
        oldDelegate.homeRuns != homeRuns;
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('試合後レポート', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final item in result.report) _BulletText(item),
            const Divider(height: 28),
            Text('勝負所', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in result.keyMoments) _BulletText(item),
            const Divider(height: 28),
            Text('次戦への提案', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in result.recommendations) _BulletText(item),
          ],
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・'),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LicenseNoticeCard extends StatelessWidget {
  const _LicenseNoticeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '注: この技術検証版は、実在球団を想起しやすい采配体験を検証するためのものです。'
          '外部公開・商用利用時には、球団名、選手名、ロゴ、写真、ユニフォーム、詳細成績データの権利確認が必要です。',
        ),
      ),
    );
  }
}
