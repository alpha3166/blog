---
title: "FreeBSDでMozcを使う"
categories: パソコン
---

FreeBSD機で とあるスクリプトを編集していた時のこと。コメントを日本語で書こうとして気づきました。あれ、かな漢字変換ができない。え、なんで急に!? 前は普通に使えてたんだけど……。

うちのFreeBSD機では、かな漢字変換にIBusとMozc(モズク、Google日本語入力のオープンソース版)を使っていて、その設定の話は前に「[FreeBSDのxtermでIBusを使う](20110424.html)」で書きました。それ以来、特に問題も無く使えていたのに、今日いきなり使えなくなっていました。切り替えキーを押すと、言語パネルではちゃんとMozcが現れるのに、んで入力モードもちゃんと「ひらがな」になっているのに、実際の動作は「直接入力」な感じで、打ったキーがそのまま出てきてしまいます。あー、考えてみればFreeBSDで日本語書くことは滅多になくて、最後にかな漢字変換したのはいつのことか、はっきり思い出せないぐらい。しかしたまにしか使わないとはいえ、このままでは不便です。しゃあない、ちょっと調べるか。

まずホームディレクトリを空っぽのディレクトリに変えて、なんの設定もない状態から、前に書いた手順をそのまま繰り返してみたものの、症状は変わらず。次にja-ibus-anthy(japanese/ibus-anthy)をインストールして、インプットメソッドをMozcからAnthyに切り替えてみると、こちらはうまくかな漢字変換できるので、IBusの問題ではなさそう。じゃあ一回Mozcを強制リビルドしてみるかってことで、ja-ibus-mozc(japanese/ibus-mozc)とその依存パッケージを全部ビルドし直してみたけど、症状は変わらず。依存パッケージ150個のビルドに2時間もかかったのに……。

ここでようやくGoogle検索することを思いつき(アホ?)、"freebsd mozc"とかで検索してみると、[後藤大地さんのFreeBSD Daily Topics](https://gihyo.jp/admin/clip/01/fdt/201112/05)で、最近のMozcには「手書き文字認識機能」や「文字パレット」なんかが追加されてるってことを知りました。へえー、これは便利そう。ぜひ使いたい。でもこれ、どっからどうやって起動するんだ? 試しにコマンドラインからmozcと打って補完させてみると、こんなのが出てきました。

```console
$ mozc【タブ】
mozc_server
mozc_server_restart
mozc_server_start
mozc_server_stop
mozc_tool
mozc_tool_character_palette
mozc_tool_config
mozc_tool_dictionary
mozc_tool_hand_writing
mozc_tool_word_register
```

おお、きっとこのmozc_toolなんちゃらが追加されたツール群に違いない。やや、その前のmozc_serverって何だ? Mozcにサーバなんてあるんだっけ? こんなの起動した覚えないぞ。これは臭い、プンプン臭うぞー!!

というわけで、ずいぶん回り道をしてmozc_serverにたどり着きました。改めて[FreshPorts](https://www.freshports.org/japanese/ibus-mozc/)とかでコミット履歴を見てみると、2010年5月29日のログに「ibus-daemonを起動する前にmozc_server_startコマンドでmozc_serverを上げないとダメよ」と書かれてるではないですか。で、pkg-messageをよく読めと書かれてるので読んでみると……、

```console
$ pkg_info -D ja-ibus-mozc\*
Information for ja-ibus-mozc-1.5.1053.102_1:

Install notice:
ibus-mozc installation finished. To use ibus-mozc, please do the following:

If you are using bash or zsh, please add following lines to your $HOME/.bashrc or
$HOME/.zshrc:

mozc_server_start
export XIM=ibus
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=xim
export XMODIFIERS=@im=ibus
export XIM_PROGRAM="ibus-daemon"
export XIM_ARGS="-r --daemonize --xim"
(後略)
```

あ、ほんとだ、mozc_server_startも書かれてますね。ところで、それはそれとして、この説明ホントにあってるんですかね。この設定を.bashrcに書けばOKってなってますけど、少なくともtwmやe16ではこれだけを書いてもIBusは動かないと思います。だって誰もibus-daemon起動してくれないんだもん。

結論としては、$HOME/.xinitrcに

```shell
export LANG=ja_JP.UTF-8
mozc_server_start
export XMODIFIERS=@im=ibus
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
ibus-daemon --daemonize --xim
sleep 1
```

と書くことで、無事またMozcを使えるようになりました。

また便利なツール群ですが、コマンド名から想像できる通り、それぞれ下記が起動しました。

- mozc_tool_character_palette: Mozc文字パレット
- mozc_tool_config: Mozcプロパティ
- mozc_tool_dictionary: Mozc辞書ツール
- mozc_tool_hand_writing: Mozc手書き文字認識
- mozc_tool_word_register: Mozc単語登録

これでもう、ほとんどWindows版と同じ使い勝手ですね。とかいいつつ、やっぱりFreeBSDで日本語入力は滅多にやらないんですけどね……。

※バージョンメモ

- FreeBSD 9.0-RELEASE
- xorg-7.5.2
- ibus-1.4.0_3
- ja-ibus-anthy-1.2.7,1
- ja-ibus-mozc-1.5.1053.102_1
