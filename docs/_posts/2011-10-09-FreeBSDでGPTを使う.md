---
title: "FreeBSDでGPTを使う"
categories: PC管理
---

3TBのHDDがかなり安くなってきました。[サハロフの秋葉原レポート](http://www2s.biglobe.ne.jp/~sakharov/)によると、今週の最安値は8,670円です。2TBまでならHDDのパーティショニングはMBR(Master Boot Record)でしのげましたが、それを超えるとGPT(GUID Partition Table)にする必要があります。Windowsだと、GPTのドライブからブートするにはマザーボードがEFI(Extensible Firmware Interface)でないとだめですが、FreeBSDではBIOS経由でもGPTのドライブからブートできるようなので、試してみました。

テストに用意するのは、以前も使った次の2つです。

- DVD-ROMドライブをもつ古いノートPC (CPUはIntel Core Solo、HDDは60GB)
- FreeBSD-8.2-RELEASE-i386-dvd1.isoを焼いたDVD-R

では作業開始。FreeBSD-8.2のDVD-RからPCを起動したあと、[Fixit]→[CDROM/DVD]でlive filesystemからシェルを立ち上げます。パーティションの操作はすべてgpartコマンドで行います。

まずはgpartのcreateサブコマンドでパーティションテーブルを作ります。-sオプションでGPTを指定します。

```console
Fixit# gpart create -s GPT ad0
gpart: geom 'ad0': File exists
```

おっと、いきなり怒られてしまいました。このディスクは、以前にMBRでパーティショニングしたままなので、不用意に上書きされないようになっているのでしょう。

```console
Fixit# gpart show ad0
=>       63  117210177  ad0  MBR  (56G)
         63    4192902    1  freebsd  [active]  (2.0G)
    4192965  113017275    2  freebsd  (54G)
```

destroyサブコマンドで既存のパーティションテーブルを破棄します。

```console
Fixit# gpart destroy ad0
gpart: Device busy
```

これでもまだダメなようです。-Fをつけて、パーティションテーブルが空でなくても強制的に破棄されるようにします。

```console
Fixit# gpart destroy -F ad0
ad0 destroyed
```

やっとうまく行きました。では改めてcreateを。

```console
Fixit# gpart create -s GPT ad0
ad0 created
Fixit# gpart show ad0
=>       34  117210173  ad0  GPT  (56G)
         34  117210173       - free -  (56G)
```

今度はうまくいきました。ここで、Protective MBRに/boot/pmbrを書きこんでおきます。マシンの起動時、BIOSからは、この/boot/pmbrを書き込んだセクタ0が実行されます。

```console
Fixit# gpart bootcode -b /dist/boot/pmbr ad0
bootcode written to ad0
```

freebsd-bootタイプのパーティションを作り、/boot/gptbootを書き込みます。これがセクタ0のコードから呼び出されます。従来のBSDパーティションの最初のトラックにbsdlabel -wで書きこんでいた/boot/bootに相当するものです。freebsd-bootパーティションのサイズは、/boot/gptboot(13,851バイト)が入ればよいので28ブロックあればよさそうですが、今後の拡張(ZFS用のブートコードをインストールする場合とか)に備え、128ブロック(64KB)を確保しておきます。

```console
Fixit# gpart add -s 128 -t freebsd-boot ad0
ad0p1 added
Fixit# gpart show ad0
=>       34  117210173  ad0  GPT  (56G)
         34        128    1  freebsd-boot  (64K)
        162  117210045       - free -  (56G)
Fixit# gpart bootcode -p /dist/boot/gptboot -i 1 ad0
```

2番目のパーティションには、スワップを1GBほど取ってみます。

```console
Fixit# gpart add -s 1G -t freebsd-swap ad0
ad0p2 added
Fixit# gpart show ad0
=>       34  117210173  ad0  GPT  (56G)
         34        128    1  freebsd-boot  (64K)
        162    2097152    2  freebsd-swap  (1.0G)
    2097314  115112893       - free -  (55G)
```

残りは全部UFSにしてみます。

```console
Fixit# gpart add -t freebsd-ufs ad0
ad0p3 added
Fixit# gpart show ad0
=>       34  117210173  ad0  GPT  (56G)
         34        128    1  freebsd-boot  (64K)
        162    2097152    2  freebsd-swap  (1.0G)
    2097314  115112893    3  freebsd-ufs  (55G)
```

これでパーティションが3つできました。デバイスファイルもうまく作成されているようです。

```console
Fixit# ls /dev/ad0*
/dev/ad0        /dev/ad0p1      /dev/ad0p2      /dev/ad0p3
```

UFSのパーティションにファイルシステムを作成し、/mntにマウントします。

```console
Fixit# newfs -U ad0p3
/dev/ad0p3: 56207.5MB (115112892 sectors) block size 16384, fragment size 2048
        using 306 cylinder groups of 183.77MB, 11761 blks, 23552 inodes.
        with soft updates
super-block backups (for fsck -b #) at:
 160, 376512, 752864, 1129216, 1505568, 1881920, 2258272, 2634624, 3010976,
 (以下省略)
Fixit# mount /dev/ad0p3 /mnt
```

DVD-Rから、baseとkernelを/mntにインストールします。

```console
Fixit# export DESTDIR=/mnt
Fixit# cd /dist/8.2-RELEASE/base
Fixit# ./install.sh
You are about to extract the base distribution into /mnt - are you SURE
you want to do this over installed system (y/n)? y
Fixit# cd ../kernels
Fixit# ./install.sh GENERIC
Fixit# cd /mnt/boot
Fixit# rmdir kernel
Fixit# mv GENERIC kernel
```

最後に、/etcにfstabを作ります。

```console
Fixit# cd /mnt/etc
Fixit# vi fstab
/dev/ad0p3  /     ufs   rw  1  1
/dev/ad0p2  none  swap  sw  0  0
```

これで準備完了。exitでFixitを抜け、HDDから再起動すると、無事に立ち上がりました。

GPTといっても特に難しいことはなく、むしろMBRよりシンプルで扱いやすいように感じました。

※バージョンメモ

- FreeBSD 8.2-RELEASE
