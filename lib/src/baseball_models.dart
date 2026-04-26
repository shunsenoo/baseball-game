enum BattingApproach {
  balanced('バランス重視'),
  smallBall('つなぐ野球'),
  power('長打狙い');

  const BattingApproach(this.label);

  final String label;
}

enum BullpenApproach {
  normal('通常運用'),
  quickHook('早めの継投'),
  preserveArms('リリーフ温存');

  const BullpenApproach(this.label);

  final String label;
}

enum PlateAppearanceResult {
  strikeout,
  walk,
  single,
  doubleHit,
  homeRun,
  groundOut,
  flyOut,
  error,
}

class Player {
  const Player({
    required this.name,
    required this.position,
    required this.contact,
    required this.power,
    required this.eye,
    required this.speed,
    required this.defense,
    required this.condition,
  });

  final String name;
  final String position;
  final int contact;
  final int power;
  final int eye;
  final int speed;
  final int defense;
  final int condition;

  int get battingScore => contact + power + eye + condition;
}

class Pitcher {
  const Pitcher({
    required this.name,
    required this.role,
    required this.stuff,
    required this.control,
    required this.stamina,
    required this.groundBall,
    required this.fatigue,
  });

  final String name;
  final String role;
  final int stuff;
  final int control;
  final int stamina;
  final int groundBall;
  final int fatigue;

  int get pitchingScore => stuff + control + stamina + groundBall - fatigue;
}

class Team {
  const Team({
    required this.name,
    required this.shortName,
    required this.ballpark,
    required this.lineup,
    required this.rotation,
    required this.bullpen,
    required this.seasonFocus,
    required this.runEnvironment,
  });

  final String name;
  final String shortName;
  final String ballpark;
  final List<Player> lineup;
  final List<Pitcher> rotation;
  final List<Pitcher> bullpen;
  final List<String> seasonFocus;

  /// Negative values model pitcher-friendly parks such as Vantelin Dome.
  final double runEnvironment;
}

class GamePlan {
  const GamePlan({
    required this.battingApproach,
    required this.bullpenApproach,
  });

  final BattingApproach battingApproach;
  final BullpenApproach bullpenApproach;
}

class InningScore {
  const InningScore({required this.top, required this.bottom});

  final int top;
  final int bottom;
}

class MatchResult {
  const MatchResult({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeRuns,
    required this.awayRuns,
    required this.innings,
    required this.keyMoments,
    required this.report,
    required this.recommendations,
  });

  final Team homeTeam;
  final Team awayTeam;
  final int homeRuns;
  final int awayRuns;
  final List<InningScore> innings;
  final List<String> keyMoments;
  final List<String> report;
  final List<String> recommendations;

  bool get homeWon => homeRuns > awayRuns;

  String get scoreLine =>
      '${awayTeam.shortName} $awayRuns - $homeRuns ${homeTeam.shortName}';
}

class DemoTeams {
  const DemoTeams._();

  static const dragons = Team(
    name: '中日ドラゴンズ重点プロトタイプ',
    shortName: '名古屋D',
    ballpark: 'バンテリンドーム想定',
    runEnvironment: -0.35,
    seasonFocus: ['投手力を活かす', '守備で失点を減らす', '得点力改善', '若手起用'],
    lineup: [
      Player(
        name: '竜のリードオフ',
        position: 'CF',
        contact: 74,
        power: 48,
        eye: 70,
        speed: 78,
        defense: 76,
        condition: 4,
      ),
      Player(
        name: '堅守の二塁手',
        position: '2B',
        contact: 70,
        power: 45,
        eye: 66,
        speed: 67,
        defense: 82,
        condition: 2,
      ),
      Player(
        name: '若き中軸候補',
        position: 'RF',
        contact: 68,
        power: 72,
        eye: 58,
        speed: 61,
        defense: 65,
        condition: 5,
      ),
      Player(
        name: '勝負強い主砲',
        position: '1B',
        contact: 66,
        power: 80,
        eye: 62,
        speed: 38,
        defense: 58,
        condition: 1,
      ),
      Player(
        name: '成長中の三塁手',
        position: '3B',
        contact: 63,
        power: 70,
        eye: 55,
        speed: 52,
        defense: 62,
        condition: 3,
      ),
      Player(
        name: '守備型ショート',
        position: 'SS',
        contact: 62,
        power: 42,
        eye: 60,
        speed: 70,
        defense: 86,
        condition: 2,
      ),
      Player(
        name: '左の代打候補',
        position: 'LF',
        contact: 64,
        power: 58,
        eye: 68,
        speed: 44,
        defense: 54,
        condition: 4,
      ),
      Player(
        name: 'リード重視捕手',
        position: 'C',
        contact: 55,
        power: 44,
        eye: 58,
        speed: 32,
        defense: 84,
        condition: 1,
      ),
      Player(
        name: '投手',
        position: 'P',
        contact: 32,
        power: 24,
        eye: 34,
        speed: 30,
        defense: 60,
        condition: 0,
      ),
    ],
    rotation: [
      Pitcher(
        name: '右のエース',
        role: 'SP',
        stuff: 82,
        control: 76,
        stamina: 86,
        groundBall: 74,
        fatigue: 8,
      ),
    ],
    bullpen: [
      Pitcher(
        name: '勝ちパターン右腕',
        role: 'SU',
        stuff: 84,
        control: 70,
        stamina: 42,
        groundBall: 70,
        fatigue: 18,
      ),
    ],
  );

  static const tokyo = Team(
    name: '東京ライバルズ',
    shortName: '東京R',
    ballpark: 'ビジター球場',
    runEnvironment: 0.1,
    seasonFocus: ['上位打線の出塁', '中軸の長打', '終盤の継投'],
    lineup: [
      Player(
        name: '俊足外野手',
        position: 'CF',
        contact: 72,
        power: 52,
        eye: 70,
        speed: 82,
        defense: 74,
        condition: 3,
      ),
      Player(
        name: '技巧派二塁手',
        position: '2B',
        contact: 69,
        power: 47,
        eye: 72,
        speed: 66,
        defense: 76,
        condition: 2,
      ),
      Player(
        name: '強打の三番',
        position: 'LF',
        contact: 73,
        power: 78,
        eye: 66,
        speed: 55,
        defense: 60,
        condition: 4,
      ),
      Player(
        name: '主砲一塁手',
        position: '1B',
        contact: 68,
        power: 84,
        eye: 64,
        speed: 36,
        defense: 52,
        condition: 3,
      ),
      Player(
        name: '中距離打者',
        position: 'RF',
        contact: 70,
        power: 67,
        eye: 61,
        speed: 58,
        defense: 64,
        condition: 1,
      ),
      Player(
        name: '堅実な遊撃手',
        position: 'SS',
        contact: 64,
        power: 46,
        eye: 60,
        speed: 68,
        defense: 78,
        condition: 2,
      ),
      Player(
        name: '若手三塁手',
        position: '3B',
        contact: 60,
        power: 66,
        eye: 54,
        speed: 50,
        defense: 58,
        condition: 4,
      ),
      Player(
        name: '守備型捕手',
        position: 'C',
        contact: 52,
        power: 40,
        eye: 56,
        speed: 30,
        defense: 80,
        condition: 0,
      ),
      Player(
        name: '投手',
        position: 'P',
        contact: 30,
        power: 20,
        eye: 32,
        speed: 28,
        defense: 58,
        condition: 0,
      ),
    ],
    rotation: [
      Pitcher(
        name: '左の技巧派',
        role: 'SP',
        stuff: 76,
        control: 80,
        stamina: 78,
        groundBall: 62,
        fatigue: 10,
      ),
    ],
    bullpen: [
      Pitcher(
        name: '守護神',
        role: 'CL',
        stuff: 86,
        control: 72,
        stamina: 36,
        groundBall: 64,
        fatigue: 14,
      ),
    ],
  );
}
