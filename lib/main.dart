import 'package:flutter/material.dart';

import 'src/baseball_models.dart';
import 'src/baseball_simulator.dart';

void main() {
  runApp(const BaseballGameApp());
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
  final BaseballSimulator _simulator = BaseballSimulator();
  late MatchResult _result = _simulator.simulate(
    homeTeam: DemoTeams.dragons,
    awayTeam: DemoTeams.tokyo,
    gamePlan: _gamePlan,
  );

  static GamePlan _gamePlan = const GamePlan(
    battingApproach: BattingApproach.balanced,
    bullpenApproach: BullpenApproach.normal,
  );

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

  void _simulateGame() {
    setState(() {
      _result = _simulator.simulate(
        homeTeam: DemoTeams.dragons,
        awayTeam: DemoTeams.tokyo,
        gamePlan: _gamePlan,
      );
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
          _HeroCard(result: _result),
          const SizedBox(height: 16),
          _TeamFocusCard(team: DemoTeams.dragons),
          const SizedBox(height: 16),
          _PlanCard(
            gamePlan: _gamePlan,
            onBattingChanged: _updateBattingApproach,
            onBullpenChanged: _updateBullpenApproach,
            onSimulate: _simulateGame,
          ),
          const SizedBox(height: 16),
          _ScoreboardCard(result: _result),
          const SizedBox(height: 16),
          _ReportCard(result: _result),
          const SizedBox(height: 16),
          const _LicenseNoticeCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = result.homeWon ? '采配成功、接戦を制す' : '課題が残る敗戦';

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
              '中日ドラゴンズ風チーム 技術検証',
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
              result.scoreLine,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'バンテリンドーム想定の低得点環境で、得点力改善と継投判断を検証します。',
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
    required this.onBattingChanged,
    required this.onBullpenChanged,
    required this.onSimulate,
  });

  final GamePlan gamePlan;
  final ValueChanged<BattingApproach?> onBattingChanged;
  final ValueChanged<BullpenApproach?> onBullpenChanged;
  final VoidCallback onSimulate;

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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSimulate,
                icon: const Icon(Icons.sports_baseball),
                label: const Text('1試合をシミュレーション'),
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
