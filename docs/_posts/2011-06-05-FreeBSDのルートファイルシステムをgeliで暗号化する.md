---
title: "FreeBSDのルートファイルシステムをgeliで暗号化する"
categories: パソコン
---

FreeBSDではgeliでハードディスク(HDD)の暗号化ができますが、ルートファイルシステムも含めて暗号化するためには、別途ブート用のカーネルだけを暗号化の外に出すなど、多少工夫が必要なようです。

今回、次のような制約の上で、HDDの暗号化ができるか試してみた結果、うまく動いたので手順をメモしておきます。

- PC1台(内蔵ハードディスクは1台)だけで作業が完結すること
- ルートファイルシステム、スワップ領域なども含めて、まるごと暗号化すること(ブート用のカーネルは除く)
- キーファイルは使わずに、パスフレーズのみで認証すること

用意したものは、次の2つです。

- DVD-ROMドライブをもつ古いノートPC (CPUはIntel Core Solo、HDDは60GB)
- FreeBSD-8.2-RELEASE-i386-dvd1.isoを焼いたDVD-R

HDDは2つのスライスに分け、s1にブート用のカーネルを置き、s2をgeliで暗号化することにします。
各スライスにはBSDパーティションを下図のように切ることにします。

- ad0
  - MBR (63セクタ)
  - ad0s1 (2GB)
    - ad0s1a (←ブート用のカーネルを入れる)
  - ad0s2 (容量は残り全部、平文デバイスはad0s2.eliになる)
    - ad0s2.elia (←ルートファイルシステム)
    - ad0s2.elib (←スワップ領域 4GB)

では具体的な手順です。

まずFreeBSD-8.2-RELEASE-i386-dvd1.isoのDVDからPCを起動します。

最初に[Configure]→[Fdisk]でスライスの設定をします。今回は、上記の通りad0s1に2GB、残り全部をad0s2という割り当てにしました。Cでスライスを作ったら、ad0s1でSを押してBootableにします。そのあと、(コマンド一覧にはありませんが)Wを押して内容をディスクに書き込みます。Boot Managerをインストールするかどうか聞かれるので、お好みでどうぞ。今回はs1からしか起動できない設定にするので、Standardを選んでおきます。書き込みが終わったら、Qでメニューに戻り、[Exit]でメインメニューに戻ります。

次に[Fixit]→[CDROM/DVD]と選び、DVDのlive filesystemからFixitのシェルを立ち上げます。

ad0s2をランダムバイトで塗りつぶします。この作業は時間がかかりますし必須ではありませんが、やっておいた方が安全性は高まると思います。

```console
Fixit# dd if=/dev/random of=/dev/ad0s2 bs=4m
dd: /dev/ad0s2: short write on character device
dd: /dev/ad0s2: end of device
13797+0 records in
13796+1 records out
57864844800 bytes trnsferred in 1950.968798 secs (29659544 bytes/sec)
```

ad0s2の暗号化設定をします。-bを付けるとブート時にパスフレーズを聞いてくるようになります。-B noneはメタデータのバックアップファイルを作らないという意味です (これを付けないと、geli: Cannot open /var/backups/ad0s2.eli: No such file or directory. というエラーが出ます)。パスフレーズはここで入力します。

```console
Fixit# geli init -b -B none /dev/ad0s2
Enter new passphrase:
Reenter new passphrase:
```

ad0s2にアタッチし、平文デバイスを使えるようにします。ただ、アタッチするためにはモジュールgeom_eli.koをカーネルにロードする必要があり、ロードするためにはgeom_eli.koのパスをkern.module_pathに設定しておかないといけないので、実際には下記のステップになります。

```console
Fixit# sysctl kern.module_path=/dist/boot/kernel
kern.module_path: /boot/kernel;/boot/modules -> /dist/boot/kernel
Fixit# kldload geom_eli
Fixit# geli attach /dev/ad0s2
Enter passphrase:
```

これで/dev/ad0s2.eliというデバイスファイルができ上がります。

今度は、/dev/ad0s2.eliの中にBSDパーティションを作ります。
-wでデフォルトのラベルを書き込んだあと、-eで編集します。

```console
Fixit# bsdlabel -w /dev/ad0s2.eli
Fixit# bsdlabel -e /dev/ad0s2.eli
```

viでディスクラベルを編集する状態になるので、今回は下記のように編集します。

```plaintext
a: * 16 4.2BSD
b: 4G * swap
c: *  * unused
```

viを:qで終了すると、編集後のラベルが書きこまれます。

/dev/ad0s2.eliaにファイルシステムをつくってマウントします。

```console
Fixit# newfs -U /dev/ad0s2.elia
Reduced frags per cylinder group from 94088 to 94072 to enlarge last cyl group
/dev/ad0s2.elia: 51088.2MB (104628648 sectors) block size 16384, fragment size 2048
        using 279 cylinder groups of 183.73MB, 11759 blks, 23552 inodes.
        with soft updates
super-block backups (for fsck -b #) at:
    160, 376448, 752736, 1129024, 1505312, 1881600, 2257888, 2634176, 3010464,
    (以下省略)
Fixit# mount /dev/ad0s2.elia /mnt
```

ここから、ルートファイルシステムの中身を作っていきます。
baseとkernelをインストールします。

```console
Fixit# export DESTDIR=/mnt
Fixit# cd /dist/8.2-RELEASE/base
Fixit# ./install.sh
You are about to extract the base distribution into /mnt - are you SURE
you want to do this over your installed sysem (y/n)? y
Fixit# cd ../kernels
Fixit# ./install.sh GENERIC
```

カーネルは/mnt/bootのGENERICに作られるので、kernelにリネームしておきます。

```console
Fixit# cd /mnt/boot
Fixit# rmdir kernel
Fixit# mv GENERIC kernel
```

/mnt/bootにloader.confをつくって、起動時にgeom_eliを読み込むようにします。

```console
Fixit# vi loader.conf
```

中身は下記。

```shell
geom_eli_load="YES"
```

次に、/mnt/etcにfstabを作ります。

```console
Fixit# cd /mnt/etc
Fixit# vi fstab
```

中身は次のようにしました。

```plaintext
/dev/ad0s2.elia /    ufs  rw 1 1
/dev/ad0s2.elib none swap sw 0 0
```

これでルートファイルシステムの中身は完成です。

今度は/dev/ad0s1aにブート用のカーネルをコピーします。まず/dev/ad0s1の中にBSDパーティションを作ります。aパーティションだけなので、デフォルトのラベルで良いでしょう。一緒に-Bをつけてブートコードをインストールしておきます。

```console
Fixit# bsdlabel -w -B /dev/ad0s1
```

次にファイルシステムを作成します。

```console
Fixit# newfs -U /dev/ad0s1a
/dev/ad0s1a: 2047.3MB (4192884 sectors) block size 16384, fragment size 2048
        using 12 cylinder groups of 183.77MB, 11761 blks, 23552 inodes.
        with soft updates
super-block backups (for fsck -b #) at:
 160, 376512, 752864, 1129216, 1505568, 1881920, 2558272, 2634624, 3010976,
 3387328, 3763680, 4140032
```

適当にマウントポイントを作って(ここでは/mnt3とします)マウントします。

```console
Fixit# mkdir /mnt3
Fixit# mount /dev/ad0s1a /mnt3
```

/mnt/bootをまるごと/mnt3にコピーします。

```console
Fixit# cp -Rpv /mnt/boot /mnt3
```

/mnt3にもetcを作ってfstabをコピーします。

```console
Fixit# mkdir /mnt3/etc
Fixit# cp /mnt/etc/fstab /mnt3/etc
```

コピーしたfstabはそのままでも構いませんが、実際にはルートファイルシステムの情報だけあれば十分なので、それ以外の行は削除しておきます。

```console
Fixit# cd /mnt3/etc
Fixit# vi fstab
```

中身は下記。

```plaintext
/dev/ad0s2.elia /    ufs  rw 1 1
```

ここまでくれば、HDDから起動可能になっているはずですので、exitでFixitを抜けて、再起動してください。起動時にad0s2のパスフレーズを聞かれます。「Enter passphrase for ad0s2: 」というプロンプトが出たら、パスフレーズを入力してください (直後にUSB関連のメッセージが出てプロンプトが分かりにくくなることがありますが、カーネルはちゃんと入力を待っているので気にせず入力すれば大丈夫です)

これ以降はrootでログインし、sysinstallなどで通常と同じく設定を進められます。

ちなみに、ad0s2のパスフレーズはgeli setkeyで変更できます(umountやgeli detachなどは特に必要ないようです)。

```console
# geli setkey /dev/ad0s2
Enter new passphrase:
Reenter new passphrase:
Note, that the master key encrypted with old keys and/or passphrase may still
exists in a metadata backup file.
```

※バージョンメモ

- FreeBSD 8.2-RELEASE
