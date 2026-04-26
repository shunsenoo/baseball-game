# baseball-game

Flutterで作るプロ野球シミュレーションゲームの技術検証リポジトリです。

## Prototype

中日ドラゴンズを初期重点球団にした技術検証版を実装しています。

- ドラゴンズ風チームとセ・リーグ対戦相手の簡易データ
- 打撃方針と継投方針の選択
- 打順構成、走塁/小技、守備シフト、勝負所采配の選択
- 10試合チャレンジ形式の短期シーズン進行
- 勝敗、ファン支持率、オーナー評価、育成ポイント、リリーフ疲労の変動
- 日替わりミッションと試合後報酬
- 相手先発、球場特性、自軍疲労、ミッションに基づく試合前分析
- ドット絵風UIと、電光掲示板/観客/打球軌道/走者進塁を表すハイライトリプレイ
- バンテリンドーム想定のロースコア補正
- 9イニングの簡易確率シミュレーション
- 本番化に向けた打席単位の試合エンジン基盤
- 試合後の勝因/敗因レポートと次戦提案

実在球団・選手データの商用利用には権利確認が必要です。現段階では企画検証用の近似データとして扱います。

## Development

```sh
flutter pub get
flutter test
flutter analyze
flutter run
```

### Browser preview

Web対応済みなので、Flutterが入っている環境ではブラウザで確認できます。

```sh
flutter pub get
flutter run -d chrome
```

Gitを入れられないWindows環境では、GitHubのブランチ画面からZIPをダウンロードして解凍してください。

1. `https://github.com/shunsenoo/baseball-game/tree/cursor/baseball-sim-game-plan-87e2` を開く
2. `Code` -> `Download ZIP` を選ぶ
3. ZIPを解凍する
4. PowerShellで解凍したフォルダに移動する
5. `flutter run -d chrome` を実行する

Flutterも入れられない場合は、Cloud側でWebビルドまたは一時プレビューを用意して確認します。

### No-install browser preview

GitやFlutterを入れられない環境でも、簡易版はブラウザだけで確認できます。

1. GitHubのブランチ画面から `Code` -> `Download ZIP` を選ぶ
2. ZIPを解凍する
3. `preview/index.html` をダブルクリックする

この簡易版はFlutter実装そのものではなく、画面体験を確認するためのHTMLプロトタイプです。

### GitHub Pages preview

GitHub Pagesを有効化すると、`main` ブランチ更新時に `preview/index.html` が自動公開されます。

Repository settingsで以下を設定してください。

1. `Settings` -> `Pages` を開く
2. `Build and deployment` の `Source` を `GitHub Actions` にする
3. `main` ブランチへマージ後、Actionsの `Deploy no-install preview` が完了するのを待つ
4. `https://shunsenoo.github.io/baseball-game/` を開く

## Documents

- [Flutterスマホゲーム企画書: プロ野球フロントライン](docs/pro-baseball-sim-game-proposal.md)
