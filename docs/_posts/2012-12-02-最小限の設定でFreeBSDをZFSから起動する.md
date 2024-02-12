---
title: "最小限の設定でFreeBSDをZFSから起動する"
category: PC管理
---

FreeBSDのファイルサーバにZFSを導入しようかなと思っているのですが、ZFSのことを何も知らないので、前回Win7機にインストールしたVirtualBoxでいろいろ試行錯誤しています。

まず知りたいのは、ZFSからFreeBSDを起動するには「最低限」何が必要なのかということ。ウェブで検索するといろんな人がいろんな手順を書いてます。もちろん、実用的に使うにはパフォーマンスとかセキュリティとか考慮していろんな設定が必要なのですが、そういったオプション的なことを一緒にやるとホントの幹が見えにくくなっちゃうので、まずは枝葉抜きの素の設定を知りたいな、なんて思ったわけです。

結論から言うと、下記のコマンド15個を打つだけで、一応動くZFSなFreeBSDを作ることができました(FreeBSD 9.1 RC3のLive CDを使った場合)。

```shell
gpart create -s GPT ada0
gpart add -t freebsd-boot -s 64K ada0
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada0
gpart add -t freebsd-zfs ada0

mdmfs -s 1M md /boot/zfs
zpool create tank ada0p2
zfs create -o mountpoint=/mnt tank/root

tar -xvzf /usr/freebsd-dist/base.txz -C /mnt
tar -xvzf /usr/freebsd-dist/kernel.txz -C /mnt

zpool set bootfs=tank/root tank
echo 'zfs_load="YES"' >> /mnt/boot/loader.conf
echo 'vfs.root.mountfrom="zfs:tank/root"' >> /mnt/boot/loader.conf
echo 'zfs_enable="YES"' >> /mnt/etc/rc.conf
cp /boot/zfs/zpool.cache /mnt/boot/zfs

shutdown -r now
```

以下、やや細かく見ていきます。

## ISOイメージから起動

まず、空のHDDを1個もつPCを、「FreeBSD-9.1-RC3-i386-disc1.iso」から起動します(実際にはVirtualBoxを使って、メモリ256MiB、仮想HDD VDI可変サイズ上限2GiBの環境で試しました)。

FreeBSD Installerが起動したら、&lt;Live CD&gt;を選んでrootでログインします。

## パーティションの作成

必要なら「dmesg \| grep MB」などで対象のデバイスを確かめた上で(今回はada0)、そこにGPTのパーティションテーブルを作ります。

```shell
gpart create -s GPT ada0
```

いわゆる第2ステージのブートストラップコード(MBR時代の/boot/bootに当たるもの)を入れるパーティションを作ります。-sでサイズを指定しますが、ここに書き込む/boot/gptzfsbootのサイズが43,443バイトなので、64KiBとしておきます。

```shell
gpart add -t freebsd-boot -s 64K ada0
```

Protective MBRに/boot/pmbrを書き込み、freebsd-bootパーティション(1番目のパーティション)に/boot/gptzfsbootを書き込みます。

```shell
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada0
```

ZFSを作るための物理パーティションを作ります。

```shell
gpart add -t freebsd-zfs ada0
```

これでGPTの設定は完了。結果は「gpart show」で確認できます。

## プールとファイルシステムの作成

続いてZFSのプールを作りたいのですが、その前に、/boot/zfsを書き込み可能にするため、メモリ上に小さなファイルシステムを作って/boot/zfsにマウントしておきます。というのも、zpool createやzpool importでシステムに新たなプールを認識させると、/boot/zfs/zpool.cacheというファイルが作られて、ここにプールの一覧が保存されるからです。システムは起動時に、/boot/zfs/zpool.cacheに書かれたプールを自動的にimportするようになっています。だから、zpool create時にできたこのファイルは、あとでHDDのルートファイルシステムにコピーしないといけません。このステップはその布石です。

```shell
mdmfs -s 1M md /boot/zfs
```

ada0p2上にZFSのプールを作ります。名前はtankとしておきます。zpool createは、プール名の頭に/をつけたディレクトリを作ってプールをマウントしようとしますが、今回はルートファイルシステムがリードオンリーなので、/tankにマウントできないという警告が出ます。が、特にマウントは必要ないので無視します。

```shell
zpool create tank ada0p2
```

結果は「zpool list」や「zpool status」で確認できます。

zpoolの中にファイルシステムを作ります。あとでこのファイルシステムにOS含めた全ファイルを入れます。名前はtank/rootとしておきます。zfs createも、名前の頭に/をつけたディレクトリを自動で作って(ただし親に独自マウントポイントを設定している場合はそれを継承)、そこにファイルシステムをマウントしようとします。自然体で行くと/tank/rootが作れなくて失敗するのですが、どうせあとでどっかにマウントしてOSのファイルを入れないといけないので、ここでついでに/mntにマウントしてしまうことにします。-oはオプションの指定です。

```shell
zfs create -o mountpoint=/mnt tank/root
```

この場合、上記は「zfs create tank/root; zfs set mountpoint=/mnt tank/root; zfs mount tank/root」とするのと同じです。zfsは、ファイルシステム自体にマウント先の情報が埋め込まれているのがポイントです。そのマウント先も含めて、結果は「zfs list」で確認できます。実際に何がマウントされているかは「zfs mount」で確認できます。

## OSのインストール

先ほど作ったtank/rootの中に、ISOイメージの中のディストリビューションの中から、必要最低限のものとしてbase.txzとkernel.txzを展開します。ちなみにtxzは、tarをxzで圧縮したファイルです。tarのオプションは、-x:展開、-v:ファイル名を出力、-z:圧縮解除、-f:ファイルから読み込み、-C:展開先のディレクトリ、です。

```shell
tar -xvzf /usr/freebsd-dist/base.txz -C /mnt
tar -xvzf /usr/freebsd-dist/kernel.txz -C /mnt
```

## ZFSから起動するための設定

起動時にブートローダーを探しに行く先のファイルシステム名をzpoolに設定します。ここで設定するbootfsの値は、ada0p1に埋め込まれた/boot/gptzfsbootが、ZFS内にある/boot/zfsloaderを探しに行くときに、どのファイルシステムを見にいけばいいかのデフォルト値になります。もしこれを設定しないと、電源投入後に / \| \ -がクルクル回る表示のあと「Can't find /boot/zfsloader」で止まってしまい、boot:に手で「tank:root:/boot/zfsloader」などと指定してやらないといけなくなります。

```shell
zpool set bootfs=tank/root tank
```

(けど、複数プールがあるとき、どのプールを探しに行くかは、……どうやって決めてるんでしょうね?)

/boot/loader.confに、ZFSを有効にする設定と、ZFSのどれをルートファイルシステムとしてマウントするかの設定を書き込みます。

```shell
echo 'zfs_load="YES"' >> /mnt/boot/loader.conf
echo 'vfs.root.mountfrom="zfs:tank/root"' >> /mnt/boot/loader.conf
```

/etc/rc.confに、ZFSを有効にする設定を書き込みます。

```shell
echo 'zfs_enable="YES"' >> /mnt/etc/rc.conf
```

システム内のプールの一覧を記載した/boot/zfs/zpool.cacheを起動ディスク側にもコピーします。前述のとおり、これがないと、システム起動時にどんなプールがあるのかを、OSが把握できません。

```shell
cp /boot/zfs/zpool.cache /mnt/boot/zfs
```

## 補足

以下は必須と言うわけではありませんが、やっておいた方がよさそうな事項です。

/etc/fstabが無いと起動時にfsckが文句を言うので、空でも作っておいた方がいいかもしれません。

```shell
touch /mnt/etc/fstab
```

/etc/rc.confにhostnameが無いと起動時にrcが文句を言うので、何か設定しておいた方がいいかもしれません。

```shell
echo 'hostname="foo"' >> /mnt/etc/rc.conf
```

tank/rootはルートファイルシステムとしてマウントされるので、mountpointオプションが何になっていてもあまり関係はないのですが、このまま放置して/mntのままになっているのも気持ちが悪いので、/tank/rootに戻しておいた方がいいかもしれません。再起動後はtank/rootがルートファイルシステムとなり、もはやzfs umountできなくなるので、やるなら今、ともいえます。逆に/mntからはアンマウントされ、/tank/rootにはマウントされないので(/がリードオンリーだから)、やるなら手順の一番最後でやる方がいいでしょう。

```shell
zfs set mountpoint=/tank/root tank/root
```

## 再起動

これですべての準備が整ったので、システムを再起動します。

```shell
shutdown -r now
```

再起動時にISOイメージを抜くと、HDDのZFSからFreeBSDが起動するはずです。

※バージョンメモ

- Windows 7 Professional Service Pack 1
- VitualBox 4.2.4 r81684
- FreeBSD-9.1-RC3-i386
