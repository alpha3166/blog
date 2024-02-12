---
title: "AlpineでGoからビルドしたバイナリがUbuntuで動かない理由と回避策"
category: プログラミング
---

GoのプログラムをDocker HubのAlpine公式イメージでビルドし、できあがったバイナリをUbuntuなどに持っていって起動すると、ファイルはちゃんとあるのに「No such file or directory」と言われることがある。なぜだろうか。

## 機序

`go build`で作った実行ファイルは、デフォルトでは**スタティックリンク**になる。

ただしGoには、C言語で書いた既存のライブラリを呼び出す**cgo**という機能があって、これを使う場合は**ダイナミックリンク**になる。

Goには標準ライブラリーが付属しているが、そのうちの「**os/user**」か「**net**」を使ったプログラムをビルドすると、cgoを使ってダイナミックリンクで**標準Cライブラリ**(libc)の機能を呼び出す実行ファイルができあがる。たとえ自分のプログラムが直接「os/user」か「net」を使っていなくとも、別のパッケージが間接的に使っていたら、やはりダイナミックリンクになる。

Ubuntuなど多くのLinuxディストリビューションは、標準Cライブラリとして**GNU Cライブラリ**(glibc)を使っているが、Alpine Linuxは軽量化のため**musl**を使っている。そのため、「os/user」か「net」を使っているGoプログラムを、Docker HubのAlpine公式イメージ(`alpine:latest`)に`apk add go`した環境で`go build`すると、muslのso(たとえば`/lib/ld-musl-x86_64.so.1`)にダイナミックリンクされた実行ファイルができあがる。

この実行ファイルを、Ubuntuなど標準ではmuslが入っていない環境に持ち込んで起動すると、muslのsoが見つけられず「No such file or directory」のエラーになる。起動しようとした実行ファイル自体が無かったときと同じメッセージなのでちょっと混乱するが、この場合は「soが無かったよ」という意味だ。

## 回避策

機序を考えれば、主な回避策としては、「cgoを使わずスタティックリンクにする」方向か、「実行環境にmuslを入れる」方向かのどちらかになるだろう。

### 回避策1: cgoを使わずスタティックリンクにする

「os/user」も「net」も、デフォルトでは標準Cライブラリを呼ぶ動きをするものの、実は同じ機能をピュアGo実装としても持っている。ただ、標準Cライブラリを使ったほうが、LDAPやNISのユーザ情報も取れたり、`/etc/gai.conf`で`getaddrinfo()`が返すIPアドレスの優先度を設定できたりと、ピュアGo実装より少し機能が豊富なので、デフォルトでは標準Cライブラリを使うようになっている。

`go build`のときに`osusergo`と`netgo`のビルドタグを指定してやれば、ピュアGo実装の方が使われるようになり、cgoを使わないスタティックリンクな実行ファイルができあがる。

```console
$ go build -tags osusergo
$ go build -tags netgo
$ go build -tags osusergo,netgo
```

あるいは、環境変数`CGO_ENABLED`を`0`にしてやると、cgoを全く使わなくなる。

```console
$ CGO_ENABLED=0 go build
```

なお、Docker HubのGoの公式イメージのAlpine版である`golang:alpine`では、イメージビルド時にcgoを使わない設定がされているらしく、最初から`CGO_ENABLED`が`0`なので、このイメージを使ってビルドする手もある(一方で、Debian版の`golang:latest`の方は`CGO_ENABLED`が`1`になっている)。

### 回避策2: 実行環境にmuslを入れる

実行環境のUbuntuなどに、aptでmuslをインストールしてやれば、Alpineでビルドしたmuslへのダイナミックリンクの実行ファイルでも実行できるようになる。

```console
# apt install musl
```

## 動作確認

上で書いた理屈が正しいのか、実際に動作確認してみる。自己満足なので、別に読む必要はない。

まず、母艦(Win 11上のWSL2上のUbuntu 22.04)にて、「Hello, World!」(`hello.go`)と、「net/httpでどっかのサイトをGET」(`http-get.go`)の2本のGoプログラムを作る。

```console
$ ls
hello.go  http-get.go
$ cat hello.go
package main
import "fmt"
func main() {
  fmt.Println("Hello, World!")
}
$ cat http-get.go
package main
import (
  "fmt"
  "net/http"
)
func main() {
  res, _ := http.Get("http://example.com/")
  fmt.Println(res.StatusCode)
}
```

`alpine:latest`でコンテナを作り、goをインストールする。`CGO_ENABLED`は`1`。

```console
$ docker run -it --rm -v $PWD:/go -w /go alpine
/go # apk -U add go
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/community/x86_64/APKINDEX.tar.gz
(1/12) Installing libgcc (12.2.1_git20220924-r4)
(2/12) Installing libstdc++ (12.2.1_git20220924-r4)
(3/12) Installing binutils (2.39-r2)
(4/12) Installing libgomp (12.2.1_git20220924-r4)
(5/12) Installing libatomic (12.2.1_git20220924-r4)
(6/12) Installing gmp (6.2.1-r2)
(7/12) Installing isl25 (0.25-r1)
(8/12) Installing mpfr4 (4.1.0-r0)
(9/12) Installing mpc1 (1.2.1-r1)
(10/12) Installing gcc (12.2.1_git20220924-r4)
(11/12) Installing musl-dev (1.2.3-r4)
(12/12) Installing go (1.19.8-r0)
Executing busybox-1.35.0-r29.trigger
OK: 560 MiB in 27 packages
/go # go env CGO_ENABLED
1
```

`go build`すると、helloはスタティックリンクだが、http-getはダイナミックリンクになっている。

```console
/go # go build -o hello@alpine:latest hello.go
/go # ldd hello@alpine:latest
/lib/ld-musl-x86_64.so.1: hello@alpine:latest: Not a valid dynamic program
/go # ./hello@alpine:latest
Hello, World!
/go # go build -o http-get@alpine:latest http-get.go
/go # ldd http-get@alpine:latest
        /lib/ld-musl-x86_64.so.1 (0x7f3c09b49000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f3c09b49000)
/go # ./http-get@alpine:latest
200
```

`netgo`のビルドタグを指定すると、http-getもスタティックリンクになる。`CGO_ENABLED=0`でも同じ。

```console
/go # go build -tags netgo -o http-get@alpine:latest@netgo http-get.go
/go # ldd http-get@alpine:latest@netgo
/lib/ld-musl-x86_64.so.1: http-get@alpine:latest@netgo: Not a valid dynamic program
/go # ./http-get@alpine:latest@netgo
200
/go # CGO_ENABLED=0 go build -o http-get@alpine:latest@cgo0 http-get.go
/go # ldd http-get@alpine:latest@cgo0
/lib/ld-musl-x86_64.so.1: http-get@alpine:latest@cgo0: Not a valid dynamic program
/go # ./http-get@alpine:latest@cgo0
200
/go # exit
```

`golang:alpine`でコンテナを作ると、`CGO_ENABLED`は`0`。`go build`すると、helloもhttp-getもスタティックリンクになる。

```console
$ docker run -it --rm -v $PWD:/go golang:alpine
/go # go env CGO_ENABLED
0
/go # go build -o hello@golang:alpine hello.go
/go # ldd hello@golang:alpine
/lib/ld-musl-x86_64.so.1: hello@golang:alpine: Not a valid dynamic program
/go # ./hello@golang:alpine
Hello, World!
/go # go build -o http-get@golang:alpine http-get.go
/go # ldd http-get@golang:alpine
/lib/ld-musl-x86_64.so.1: http-get@golang:alpine: Not a valid dynamic program
/go # ./http-get@golang:alpine
200
/go # exit
```

参考として`golang:latest`(=`golang:bullseye`なのでDebian)でコンテナを作ると、`CGO_ENABLED`は`1`。`go build`すると、helloはスタティックリンクだが、http-getはglibcへのダイナミックリンクになっている。

```console
$ docker run -it --rm -v $PWD:/go golang
root@25ea964d3e47:/go# go env CGO_ENABLED
1
root@25ea964d3e47:/go# go build -o hello@golang:latest hello.go
root@25ea964d3e47:/go# ldd hello@golang:latest
        not a dynamic executable
root@25ea964d3e47:/go# ./hello@golang:latest
Hello, World!
root@25ea964d3e47:/go# go build -o http-get@golang:latest http-get.go
root@25ea964d3e47:/go# ldd http-get@golang:latest
        linux-vdso.so.1 (0x00007ffd52bfb000)
        libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007ffaa2300000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007ffaa22de000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ffaa2109000)
        /lib64/ld-linux-x86-64.so.2 (0x00007ffaa2320000)
root@25ea964d3e47:/go# ./http-get@golang:latest
200
root@25ea964d3e47:/go# exit
exit
```

各環境でビルドした実行ファイルを`ubuntu:latest`のコンテナで動かしてみる。

```console
$ docker run -it --rm -v $PWD:/go -w /go ubuntu
root@d22626dfe684:/go# ls -1
hello.go
hello@alpine:latest
hello@golang:alpine
hello@golang:latest
http-get.go
http-get@alpine:latest
http-get@alpine:latest@cgo0
http-get@alpine:latest@netgo
http-get@golang:alpine
http-get@golang:latest
```

スタティックリンクなもの、glibcへのダイナミックリンクなものは問題なく動く。

```console
root@d22626dfe684:/go# ./hello@alpine:latest
Hello, World!
root@d22626dfe684:/go# ./hello@golang:alpine
Hello, World!
root@d22626dfe684:/go# ./hello@golang:latest
Hello, World!
root@d22626dfe684:/go# ./http-get@alpine:latest@cgo0
200
root@d22626dfe684:/go# ./http-get@alpine:latest@netgo
200
root@d22626dfe684:/go# ./http-get@golang:alpine
200
root@d22626dfe684:/go# ./http-get@golang:latest
200
```

が、`alpine:latest`の素でビルドしたものだけは、muslへのダイナミックリンクなので、動かない。

```console
root@d22626dfe684:/go# ./http-get@alpine:latest
bash: ./http-get@alpine:latest: No such file or directory
```

明示的にmuslをインストールしてやると、動くようになる。

```console
root@d22626dfe684:/go# sed -i.bak -e "s/archive.ubuntu.com/jp.archive.ubuntu.com/" /etc/apt/sources.list
root@d22626dfe684:/go# apt update
Get:1 http://jp.archive.ubuntu.com/ubuntu jammy InRelease [270 kB]
Get:2 http://security.ubuntu.com/ubuntu jammy-security InRelease [110 kB]
Get:3 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 Packages [41.2 kB]
Get:4 http://jp.archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
Get:5 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [1073 kB]
Get:6 http://jp.archive.ubuntu.com/ubuntu jammy-backports InRelease [108 kB]
Get:7 http://jp.archive.ubuntu.com/ubuntu jammy/main amd64 Packages [1792 kB]
Get:8 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [1004 kB]
Get:9 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages [925 kB]
Get:10 http://jp.archive.ubuntu.com/ubuntu jammy/multiverse amd64 Packages [266 kB]
Get:11 http://jp.archive.ubuntu.com/ubuntu jammy/restricted amd64 Packages [164 kB]
Get:12 http://jp.archive.ubuntu.com/ubuntu jammy/universe amd64 Packages [17.5 MB]
Get:13 http://jp.archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages [46.6 kB]
Get:14 http://jp.archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages [1166 kB]
Get:15 http://jp.archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages [1350 kB]
Get:16 http://jp.archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 Packages [1126 kB]
Get:17 http://jp.archive.ubuntu.com/ubuntu jammy-backports/main amd64 Packages [49.4 kB]
Get:18 http://jp.archive.ubuntu.com/ubuntu jammy-backports/universe amd64 Packages [25.6 kB]
Fetched 27.1 MB in 24s (1141 kB/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
5 packages can be upgraded. Run 'apt list --upgradable' to see them.
root@d22626dfe684:/go# apt install musl
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  musl
0 upgraded, 1 newly installed, 0 to remove and 5 not upgraded.
Need to get 407 kB of archives.
After this operation, 779 kB of additional disk space will be used.
Get:1 http://jp.archive.ubuntu.com/ubuntu jammy/universe amd64 musl amd64 1.2.2-4 [407 kB]
Fetched 407 kB in 2s (225 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package musl:amd64.
(Reading database ... 4395 files and directories currently installed.)
Preparing to unpack .../musl_1.2.2-4_amd64.deb ...
Unpacking musl:amd64 (1.2.2-4) ...
Setting up musl:amd64 (1.2.2-4) ...
root@d22626dfe684:/go# ./http-get@alpine:latest
200
```

## おわりに

分かってしまえばどうということはないが、Go素人の自分は原因をよく理解してなかったので、調べてみた。

なお、これを書くにあたって「[Statically compiling Go programs](https://www.arp242.net/static-go.html)」を大いに参考にさせていただいた。というか、ほとんどこの内容を焼き直しただけなので、詳しくは本家を参照して欲しい。

※バージョンメモ

- Docker Desktop Engine 20.10.24
- alpine:latest = alpine:3.17.3、go 1.19.8
- golang:alpine = golang:1.20.3-alpine3.17
- golang:latest = golang:1.20.3-bullseye
- ubuntu:latest = ubuntu:22.04
