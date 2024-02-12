---
title: "VirtualBoxでFreeBSDを使ってみる"
category: OS仮想化
update: 2012-12-22 00:00:00 +0900
---

FreeBSDで構築しているファイルサーバにそろそろZFSを導入しようかなと思っているのですが、ZFSの経験値がゼロなので、作業に入る前にいろいろ試してみたい、ということで、Windows 7機に今流行りのVirtualBoxを入れて、そこでFreeBSDを動かしてみました。結論から言うと、これはとっても簡単・快適で、一度味をしめると病みつきになります(笑)。

VirtualBoxのインストールは、難しいことは何もありません。[VirtualBoxのサイト](https://www.virtualbox.org/)からVirtualBox 4.2.4 for Windows hostsをダウンロードして、Windows 7マシンにインストールします。設定はすべてデフォルトでもOK。途中「Oracle Corporation ユニバーサル シリアル バス コントローラ」「Oracle Corporation Network Service」「Oracle Corporation ネットワーク アダプター」をインストールするか訊かれるので、すべて「インストール」を選択します。終わったら、そのまま「Oracle VM VirtualBox」を起動します。

新規の仮想マシンを作成して、名前に「FreeBSD」と打つと、タイプとバージョンが自動的に「BSD」と「FreeBSD」になるんですね。これは分かりやすい。メモリはデフォルトの128MB、仮想ハードドライブもデフォルトのVDI(VirtualBox Disk Image)可変サイズ上限2GBのままで作成します。そして早速「起動」!

初回はHDDに何も入っていないので、起動ディスクの選択を促すダイアログが出ます。そこで、FreeBSDのミラーサイトから落とした「FreeBSD-9.1-RC3-i386-disc1.iso」を選択して起動すると、FreeBSDインストーラの画面にたどり着きました(9.0から導入されたbsdinstallの画面、実はこのとき初めて目にしました。いつもISOイメージからファイルを手動で展開してインストールしていたので……)。

![img](img/20121125-001.png)

その先も全てデフォルト設定で進めていくと、あれ!? base.txzの展開中に突然再起動がかかってしまいました。ISOイメージも入れたままの状態なので、再起動後は再びFreeBSDインストーラの画面が立ち上がります。もしかしてメモリ不足? 特に根拠はありませんが、なんとなくそんな気がしたので、一旦「仮想マシン ＞ 閉じる」で「仮想マシンの電源オフ」状態にしてから、メモリを倍の256MBにしてもう一度やってみます。すると、base.txzの展開は無事通過しました。

が、こんどはports.txzの展開中に「Extract Error」が出ます。「Error while extracting ports.txz: Can't create 'なんちゃら'」と言っています。

![img](img/20121125-002.png)

また画面には、inodeが足りなくなったというメッセージも出ています。

    /mnt: create/symlink failed, no inode
    Nov 25 07:56:34  kernel: pid 810 (distextract), uid 0 inumber 45876 on /mnt: out of inodes

仮想ディスクのVDIファイルを見ると1.77GBに膨らんでいたので、今度はディスク不足のようです。再び仮想マシンの電源をオフにし、2GBの仮想ディスクは一旦除去して、上限4GBにしたディスクを新たに割り当てます(もちろん、portsのインストールをやめるという手もありますが、今回はなるべくデフォルトのままで行きたいので……)。

するとインストールは無事終了。ここで仮想マシンを再起動します。本当は、再起動時にVirtualBoxがISOイメージを自動的に割り当て除去してくれるはずなんですが、途中で電源オフにしたためか、今回はISOイメージが割り当てられたままです。放っておくとまたCDから起動してしまうので、起動時のVirtualBoxスプラッシュ画面でF12を押して一旦起動を止めておき、画面下のCD/DVDデバイスアイコンを右クリックして「仮想ドライブからディスクを除去」します。bを押して起動を再開すると、やりました! 今度はHDDにインストールしたFreeBSDが立ち上がりました。

![img](img/20121125-003.png)

以下は補足です。

実は最初、amd64のISOイメージで試したのですが、仮想サーバのバージョンを「FreeBSD」にすると32bit環境になるので、「CPU doesn't support long mode」と怒られて、起動しませんでした(これは当たり前)。

そこで、仮想サーバのバージョンを「FreeBSD (64 bit)」にすると、今度は起動時に、ACPIのあたりでエラーになってpanicしまいました。

    acpi0: could not allocate interrupt
    ACPI Exception: AE_ALREADY_EXISTS, Unable to install System Control Interrupt handler (20110527/evevent-137)
    acpi0: Could not enable ACPI: AE_ALREADY_EXISTS
    (中略)
    Fatal trap 12: page fault while in kernel mode
    (中略)
    panic: page fault

ブート時のオプションでACPI Supportをoffにして起動してみましたが、今度は下記のようなメッセージが出て、やはりpanicしてしまうので、今回amd64を使うのは諦めました(9.0-RELEASEや8.2-RELEASEのISOイメージも試してみましたが、どれも同じでした)。

    ata0: unable to allocate interrupt
    (中略)
    ata1: unable to allocate interrupt
    (中略)
    em0: Unable to allocate bus resource: interrupt
    (中略)
    panic: No usable event timer found!

※バージョンメモ

- Windows 7 Professional Service Pack 1
- VitualBox 4.2.4 r81684
- FreeBSD-9.1-RC3-i386

---
■2012年12月22日追記

2012年12月19日にVirtualBox 4.2.6がリリースされ、FreeBSDのamd64も問題なく起動できるようになっていました。FreeBSD-9.0-RELEASE-amd64とFreeBSD-9.1-RELEASE-amd64で確認しました。ChangeLogにそれらしい記述は見当たりませんが、何かが修正されたようです。

※バージョンメモ

- Windows 7 Professional Service Pack 1 (32bit)
- VitualBox 4.2.6 r82870
- FreeBSD-9.0-RELEASE-amd64
- FreeBSD-9.1-RELEASE-amd64
