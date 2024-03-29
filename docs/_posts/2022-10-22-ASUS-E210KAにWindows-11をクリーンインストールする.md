---
title: "ASUS E210KAにWindows 11をクリーンインストールする"
categories: パソコン
---

## やりたいこと

- ASUS E210KAにWindows 11 22H2をクリーンインストールしたい
- ローカルアカウントで使いたい(Microsoftアカウントに紐づけたくない)
- Sモードを解除したい

## Windows 11 22H2をクリーンインストールする

Windows 11のクリーンインストール自体は特に難しいことはなく、下記の通常手順でできる。

1. Microsoftの「Windows 11 をダウンロードする」ページの手順でUSBメモリにインストールメディアを作成
2. USBメモリを刺した状態でPCを再起動
3. F2を連打してBIOS画面へ
4. USBメモリのBoot Priorityを1番上にしてSave & Exit
5. あとは手順に従ってインストール

注意点として、インストール後にWindows Updateでドライバが入るまではタッチパッドが使えないので、マウスをつなぐか、全てキーボードで操作する必要がある。

もともとあったパーティションは、気にせず全部削除したが、特に問題は出ていない。

インストール直後はデバイスマネージャにいくつか警告が出ていたが、Windows Updateをすべて完了させたら警告は消えた。Windows UpdateによりASUSのアプリがいくつか導入されるが、これは仕方ないと割り切る。

## ローカルアカウントで使う

Windows 11 22H2から、セットアップ時にMicrosoftアカウントが強制されるようになった。が、以下の手順でそれを回避し、ローカルアカウントを作ることができる。

1. Windows 11インストール後の初期セットアップで、Microsoftアカウントに「`no@thankyou.com`」と入力する
2. 適当なパスワードで認証を失敗させる
3. 「問題が発生しました」の画面で「次へ」を押し、ローカルアカウントの作成画面へ

以下余談。

Windows 10ではセットアップ時にローカルアカウントの作成を選べていたが、いつからかHomeではこれが選べなくなった。その場合、ネットワークの設定をスキップしてセットアップを進めれば、ローカルアカウントの作成を選べた。

しかしWindows 11では、ネットワークの設定をしないと次へ進めなくなり、この手も使えなくなった。なお、ネットワーク接続の画面でShift+F10でコマンドプロンプトを呼び出し、各種コマンドでネットワーク接続を回避する手段も紹介されているが、E210KAではShift+F10を押しても何も起こらなかった(E210KAのデフォルトでは、ファンクションキーを使うためにFnを押す必要があるため、実際にはShift+Fn+F10を押すが、それでも何も起こらなかった)。

Microsoft様には、ぜひ最初からローカルアカウントを作れるオプションを残してもらいたいものである。

## Sモードを解除する

E210KAには、Windows 11 Home 21H1のSモードがプリインストールされていた。この状態でWindows 11をクリーンインストールしても、Sモードは引き継がれる。一度Sモードを解除すると、その後はクリーンインストールしてもSモードは解除されたままになる。

Sモードの解除手順は次のとおり、なのだが……

1. 「設定」→「システム」→「ライセンス認証」で、「Windows 11 Homeに切り替える」の中にある「Microsoft Storeに移動」をクリック
2. 「Sモードから切り替える」の画面で「入手」を押す
3. Microsoftアカウントでログインして、しばらく待つと完了する

問題は「Microsoftアカウントでログイン」という箇所で、これでは「ローカルアカウントで使いたい(Microsoftアカウントに紐づけたくない)」という要望が満たされないが、回避手段はない。そこで今回は、一時的なメールアカウントを作り、それを使って一時的なMicrosoftアカウントを作ってSモードを解除し、その後もういちどクリーンインストールしてローカルアカウントで使うようにした(Microsoftアカウントからサインオフするだけでは、内部的にアカウントの情報は残ったままになる)。

## Windows Updateのエラー

一時的な現象だとは思うが、クリーンインストール後のWindows Updateでエラーになる場合があった。

■パターン1: KB5018427が0x80070000bで失敗する

この場合、Microsoft Updateカタログからダウンロードして手動でインストールするか、もう一度クリーンインストールからやり直す。

■パターン2: Intelのドライバ9個の適用が失敗する

この場合、理由は分からないが、何時間か置くことで、自然に解消した。

## おわりに

ブラウザとLibreOfficeぐらいしか使わないサブ機として、もともと[ASUS VivoBook E203NAを使っていた](20171117.html)のだが、購入から5年経ってさすがに限界が見えてきたので、ASUS E210KAに乗り換えた。別にASUSのネットブックに思い入れは無いが、価格.comでWindows 11のノートPCを検索したら、たまたまこれが最安だった。ちなみに購入価格は32,200円。

E210KAは、一時期流行ったネットブックの末裔で、Celeron N4500、メモリ4GB、eMMC 128GB、11.6型というローエンドもローエンドだが、ブラウザとLibreOfficeぐらいしか使わないのであれば速度的には全然問題ない(けど、メイン機としてはあまりおすすめしない)。前のE203NAがこれよりずっと低いスペックだったこともあり、それに比べれば断然速い! ストレージも広大! と快適に使えている。
