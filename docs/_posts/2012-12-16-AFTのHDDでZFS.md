---
title: "AFTのHDDでZFS"
categories: PC管理
---

そんなわけで、FreeBSD機のZFS化をいよいよ決行です。

3TBのHDDを2個つないでミラーリングし、古いHDDからデータを移し始めたんですが、どうにも遅い。10MiB/sぐらいしか出てない感じです。4～5年前のポンコツ機だし、ZFSだと多少は遅くなる覚悟はしてたけど、さすがにこれは遅すぎ。なので一旦コピーは中断して、ちょっと原因を探ってみることにしました。

今回買ったHDDは[Western DigitalのWD30EZRX](http://www.wdc.com/global/products/specs/?driveID=927&language=6)で、物理セクタは4KiBですが、OSに対しては512Bセクタであるかのように振る舞うタイプ、いわゆるAFT(Advanced Format Technology)を採用したモデルです。

このタイプはパーティション境界が4KiBでないと性能が落ちるので、

```console
# gpart add -t freebsd-zfs '''-a 4K''' -l d1 ada0
```

のようにgpartの-aオプションでアラインメントは指定していたのですが、これだけでは十分でなかったようです。

試しにddで1000MiBのファイルをゼロで埋めてみると、やはり11KiB/s弱しか出ていません。

```console
# dd if=/dev/zero of=test bs=1m count=1000
1000+0 records in
1000+0 records out
1048576000 bytes transferred in 92.314542 secs (11358730 bytes/sec)
```

ところで、今回はHDDの一部をGEOM ELIで暗号化していました。そっちはgeli initするときに-s 4096オプションをつけて、セクタサイズを4KiBにしていたので、同じことをやってみると――、

```console
# dd if=/dev/zero of=test bs=1m count=1000
1000+0 records in
1000+0 records out
1048576000 bytes transferred in 33.435481 secs (31361176 bytes/sec)
```

なんと、3倍の30KiB/s程度出ています。間に暗号化の処理がはさまっているにもかかわらず。ということは、やはり何かセクタサイズに関係があるのは間違いないようです。

ここでハタと、zpoolの認識しているセクタサイズに関する[Hiroki Satoさんの日記](https://www.allbsd.org/~hrs/diary/201109.html)のことを思い出しました。それによると、zdbでashiftを調べれば、zpoolが認識しているセクタサイズが分かるとのこと。

早速zdbでセクタサイズを調べてみると、暗号化していない方は「ashift: 9」(つまり2の9乗=512B)、暗号化している方は「ashift: 12」(つまり2の12乗=4KiB)となっていました。やはりこれか……。

そこで、前述の日記で紹介されている、gnopを使ってセクタサイズを強制的に4KiBにする方法を試してみます。

```console
# gnop create -S 4096 /dev/gpt/d1
# gnop create -S 4096 /dev/gpt/d2
# zpool create tank mirror gpt/d1.nop gpt/d2.nop
# zpool export tank
# gnop destroy /dev/gpt/d1.nop
# gnop destroy /dev/gpt/d2.nop
# zpool import -d /dev/gpt tank
```

ふたたびzdbで調べると、今度はばっちり「ashift: 12」になりました。

本当に早くなったか試してみると――、

```console
# dd if=/dev/zero of=test bs=1m count=1000
1000+0 records in
1000+0 records out
1048576000 bytes transferred in 16.747891 secs (62609436 bytes/sec)
```

おお、6倍も早くなったではないですか!

というわけで、AFTのHDDでZFS使うときはセクタサイズに注意、というお話でした。

※バージョンメモ

- FreeBSD 9.0-RELEASE-p3 amd64
