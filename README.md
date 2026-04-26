# baseball-game

Flutterで作るプロ野球シミュレーションゲームの技術検証リポジトリです。

## Prototype

中日ドラゴンズを初期重点球団にした技術検証版を実装しています。

- ドラゴンズ風チームとセ・リーグ対戦相手の簡易データ
- 打撃方針と継投方針の選択
- バンテリンドーム想定のロースコア補正
- 9イニングの簡易確率シミュレーション
- 試合後の勝因/敗因レポートと次戦提案

実在球団・選手データの商用利用には権利確認が必要です。現段階では企画検証用の近似データとして扱います。

## Development

```sh
flutter pub get
flutter test
flutter analyze
flutter run
```

## Documents

- [Flutterスマホゲーム企画書: プロ野球フロントライン](docs/pro-baseball-sim-game-proposal.md)
