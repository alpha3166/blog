---
title: "FreeBSDのxtermでIBusを使う"
categories: パソコン
---

わりと昔からFreeBSDを使っているのですが、最近の事情にぜんぜんついていってないもので、日本語環境と言えばktermにkinput2にCannaにJVimという組み合わせで使っていました。もちろん日本語ファイル名や、テキストファイルの中身のエンコーディングはeucJPです。

ところが、最近のLinuxの日本語入力はIBus+Anthyだとか、Google日本語入力のオープンソース版となるMozc(モズク)が出たとか聞き、Cannaより賢そうなので使ってみると、UTF-8のエンコーディングを前提にしているものがだんだん増えていることに気づきました。例えば、IBusの設定ツールibus-setupをja_JP.eucJPのロケールで起動するとセグメンテーション違反で落ちますし、フォントの一覧を出すfc-listも結果をUTF-8で返してくるので、eucJPでは文字化けしてしまいます。

そこで、ここらでロケールをja_JP.UTF-8にしてはどうかと思い、まずはktermをやめて、UTF-8が通る端末エミュレータへの置き換えを考えました。世の中にはすごい数の端末エミュレータがあるようですが、実は昔ながらのxtermも結構メンテナンスされていて、UTF-8も立派に通るようになっているそうです。できればシンプルなものを使いたいので、用が足りるならxtermで済ませたいところです。また、前述のJVimというのはVimを日本語化したものですが、こちらも本家Vimの対応が進んでいて、JVimなんてとっくに過去の遺物になっていたようです。

なので、kterm、kinput2、Canna、JVimという組み合わせをやめて、xterm、IBus、Mozc、Vimへの置き換えを決行しました。

その中で特に、xtermでIBusを使うところでたくさんつまずいたので、ここに考慮点をメモしておきます。

FreeBSD+Xorg上のxtermでIBusを使って日本語入力するための最低条件は、下記の3点です。

- その1: IBusデーモンを起動していること。
- その2: IBus設定ツールで、IBusにインプットメソッドを組み込んでいること。
- その3: xtermの起動時に、環境変数LANGとXMODIFIERSが設定されていること。

ではここで、まっさらのPCにFreeBSDをインストールしたあと、下記のパッケージをインストールしてまだ何の設定もしていない状態を想定し、Mozcで日本語入力できるようになるまでの手順を考えます。

- xorg (x11/xorg)
- ja-ibus-mozc (japanese/ibus-mozc)
- vim (editors/vim)

まず、startxでX Window Systemを立ち上げます。(デフォルトのxinitrcが使われると、twmの上でxtermが3枚立ち上がります。)

次に、

```shell
ibus-daemon --daemonize --xim
```

でIBusデーモンを立ち上げます。長いオプションが嫌なら、

```shell
ibus-daemon -d -x
```

でも構いません。なお、ibus-daemonは--daemonizeオプションにより勝手にバックグラウンドに回るので、末尾に&を付ける必要はありません。

本当に起動したかどうかは、psで確認しましょう。このとき、ibus-daemonプロセスは起動した端末から切り離されているので、-xオプションを付けないと見えません。

```shell
ps -x | grep ibus
```

として、さっき起動したibus-daemonが表示されればOKです。

次に、

```shell
ibus-setup &
```

でIBus設定ツールを立ち上げます。前述のとおり、もしすでに環境変数LANGを設定済の場合、それがja_JP.eucJPやja_JP.SJISだとセグメンテーション違反で落ちてしまうので、

```shell
env LANG= ibus-setup &
```

とします(LANG=の後ろはスペースです)。ツールの表示を日本語にしたければ、

```shell
env LANG=ja_JP.UTF-8 ibus-setup &
```

でも良いでしょう。

ツールが起動したら、Input Method(インプットメソッド)タブでMozcを選び、Addボタンで追加し、ツールを閉じます。

IBusの状態を示すバーを画面に出しておきたい場合は、General(一般)タブのShow language panel(言語パネルの表示)をAlways(常に表示する)にしておくと良いでしょう。

ちなみに、ここで設定した内容は、ホームディレクトリの中の下記のようなファイルに格納されるようです。

```plaintext
.cache/ibus/bus/registry.xml
.config/ibus/bus/ 0123456789abcdef0123456789abcdef-unix-0
.dbus/session-bus/ 0123456789abcdef0123456789abcdef-0
.gconf/desktop/%gconf.xml
.gconf/desktop/ibus/%gconf.xml
.gconf/desktop/ibus/general/%gconf.xml
.gconf/desktop/ibus/panel/%gconf.xml
.gconfd/saved_state
```

最後に、環境変数LANGとXMODIFIERSを指定してxtermを起動します。

```shell
env LANG=ja_JP.UTF-8 XMODIFIERS=@im=ibus xterm &
```

この状態で起動したxtermの中では、Ctrl+Spaceなどで日本語変換が開始されます。LANGの値は、ja_JP.eucJPやja_JP.SJISでも構いませんし、メッセージを英語にしたいのならen_US.UTF-8でも構いません。

さて、上記の手順はIBus設定ツールの設定を除いて永続性がないので、次回のX起動時には失われてしまいます。
そこで、X起動時の設定ファイルに設定を追加しておく必要があります。

xinitを使う場合だと、(本当に素のままから始めるなら、ですが)例えば/usr/local/lib/X11/xinit/xinitrcをホームディレクトリに.xinitrcとしてコピーし、xtermを起動している行より前に下記の行を挿入します。GTK+やQtのimmoduleでもIBusが使えるよう、ついでに環境変数を設定しておきましょう。

```shell
export LANG=ja_JP.UTF-8
export XMODIFIERS=@im=ibus
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
ibus-daemon --daemonize --xim
```

これでxtermでIBusを使ってvimで日本語のテキストを編集が可能になりました。

……が、早速問題が2点ほど出てしまいました。

1つ目の問題は、startxで.xinitrcから起動したxtermでIBusが有効にならない場合があること。これはどうやら、ibus-daemonがバックグラウンドで完全に起動し終わる前にxtermが起動することで発生するようです。なので、対処として(原始的ですが).xinitrcのibus-daemonの直後にsleep 1を入れることで、発生しなくなりました。

2つ目の問題は、ユニコードで文字の横幅が曖昧な文字(例えば■や→など)が半角の幅で表示されてしまうこと。これは、xtermの起動時に-cjk_widthオプションを指定することで解消します。このオプション指定はXTermのcjkWidthリソースをtrueにすることと等価ですので、~/.Xresourcesに

```properties
XTerm*cjkWidth: true
```

と書くことでも有効にできます。これで表示上は■や→もいわゆる全角の幅で表示されるようになります。ただしこのままでは、Vimがこれらの文字を扱うときにカーソルの移動幅を1桁とカウントするので表示と不一致になります。
そこで、~/.vimrcに

```shell
set ambiwidth=double
```

と書くことで、移動幅も2桁にあわせることができます。

※[FreeBSDでMozcを使う](20120506.html)に関連記事を書きました。

※バージョンメモ

- FreeBSD 8.2-RELEASE
- xorg-7.5.1
- xterm-269_3
- ibus-1.3.9
- ja-ibus-mozc-0.13.523.102_1
- vim-7.3.121
