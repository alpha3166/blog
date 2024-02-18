---
title: "MavenのDockerでUID/GIDを変える"
categories: パソコン
---

## MavenをDocker公式イメージで実行する

MavenをDockerで実行したい場合、公式イメージを使うと便利。

```shell
docker run --rm -it maven mvn archetype:generate
```

プロジェクトをコンテナ内ではなくDockerホスト側に置きたいなら、ホスト側のディレクトリを適当な場所にバインドマウントして(-vでもいいけど、最近は--mount推奨とのこと)、ワーキングディレクトリをそこに移して実行する。

```shell
docker run --rm -it \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn archetype:generate
```

ローカルリポジトリもDockerホスト側のものを使いまわしたいなら、$HOME/.m2をコンテナの/root/.m2にバインドマウントする。

```shell
docker run --rm -it \
    --mount type=bind,src=$HOME/.m2,dst=/root/.m2 \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn archetype:generate
```

これで一応動くんだけど、Linuxの場合はMavenが作るファイルのオーナー:グループが全部root:rootになっちゃって、ちょっと扱いづらい(macOSではこの問題は無いらしい)。

## MavenのUID/GIDを変える

DockerでMavenのUID/GIDをrootじゃなくするには、[公式イメージの説明](https://hub.docker.com/_/maven)にもあるとおり、下記の指定を行う。

- docker runの-uオプションでUID/GIDを指定する(なお、指定したUID/GIDがコンテナ側の/etc/passwdや/etc/groupに存在しなくても、Mavenの場合は特に問題ないようだ)
- 環境変数MAVEN_CONFIGで、コンテナ内の.m2の場所を指定する
- Javaのシステムプロパティuser.homeで、コンテナ内の.m2の親ディレクトリを指定する

コマンドラインのサンプルは下記。

```shell
docker run --rm -it \
    -u $(id -u):$(id -g) \
    --mount type=bind,src=$HOME/.m2,dst=/myhome/.m2 \
    -e MAVEN_CONFIG=/myhome/.m2 \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn -Duser.home=/myhome archetype:generate
```

結論としては、これでMavenがちゃんと動くし、オーナー:グループもDockerホストの実効UID:GIDになる。

あとは、これをシェルの関数にでもしておけばいい。

```shell
function mvn() {
    docker run --rm -it \
        -u $(id -u):$(id -g) \
        --mount type=bind,src=$HOME/.m2,dst=/myhome/.m2 \
        -e MAVEN_CONFIG=/myhome/.m2 \
        --mount type=bind,src=$PWD,dst=/myproj \
        -w /myproj \
        maven mvn -Duser.home=/myhome $@
}
```

そうすれば、ローカルにインストールされているのと同じような感覚でMavenを使える。

```shell
mvn clean
```

## 以下、いろいろ試したメモ

### -uだけ指定すると?

まず、-uだけ指定してみた。

```shell
docker run --rm -it \
    -u $(id -u):$(id -g) \
    --mount type=bind,src=$HOME/.m2,dst=/root/.m2 \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn archetype:generate
```

この場合、実行時に下記のエラーが出る。/root/.m2はコンテナ内にもともと存在するディレクトリで、root以外には書き込み権限がないためこのエラーになる。

```console
mkdir: cannot create directory ‘/root’: Permission denied
Can not write to /root/.m2/copy_reference_file.log. Wrong volume permissions? Carrying on ...
```

ただし、メッセージに`Carrying on ...`とあるとおり、エラーが出たあとも処理はそのまま続き、正常に終わる。では.m2/repositoryに格納されるべきアーティファクトがどこに行ったのかというと、ワーキングディレクトリの直下に?というディレクトリ(文字化けではなくて、本当にクエスチョンマーク1文字からなるディレクトリ)ができており、その中の.m2/repositoryに格納されていた。ファイルのオーナーは、ちゃんとDockerホストの実効ユーザになっていた。

### .m2を新規ディレクトリにすると?

/root/.m2に書き込み権限が無いのがダメなのであれば、ということで、コンテナには存在しない/myrepoに.m2をバインドマウントして、環境変数MAVEN_CONFIGでそのディレクトリを指定してみた。

```shell
docker run --rm -it \
    -u $(id -u):$(id -g) \
    --mount type=bind,src=$HOME/.m2,dst=/myrepo \
    -e MAVEN_CONFIG=/myrepo \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn archetype:generate
```

この場合、先の`cannot create directory ‘/root’`のエラーは出なくなったが、.m2はやはりワーキングディレクトリの?の中にできていた。

### user.homeを指定すると?

さらに、公式説明にあるとおり、Javaのシステムプロパティuser.homeで.m2の親ディレクトリを指定してみた。これが全てうまくいったケースで、前述の結論に相当する。

```shell
docker run --rm -it \
    -u $(id -u):$(id -g) \
    --mount type=bind,src=$HOME/.m2,dst=/myhome/.m2 \
    -e MAVEN_CONFIG=/myhome/.m2 \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn -Duser.home=/myhome archetype:generate
```

### 環境変数MAVEN_CONFIGを抜くと?

ここで指定している環境変数MAVEN_CONFIGは、コンテナのエントリポイントになっている/usr/local/bin/mvn-entrypoint.shを見る限り、/usr/share/maven/refに置かれたファイルのコピー先(およびその処理のログの格納先)として使っているだけだ。コピーの後はunset MAVEN_CONFIGで消され、それからdocker runに渡されたコマンドラインの処理(つまりmvnコマンドの実行)に移るので、結局mvnコマンドにMAVEN_CONFIGの値は伝わっていない。ということは、別に-e MAVEN_CONFIG=/myhome/.m2が無くても動くのではないかと思い、抜いてみた。

```shell
docker run --rm -it \
    -u $(id -u):$(id -g) \
    --mount type=bind,src=$HOME/.m2,dst=/myhome/.m2 \
    --mount type=bind,src=$PWD,dst=/myproj \
    -w /myproj \
    maven mvn -Duser.home=/myhome archetype:generate
```

結果は、また下記のエラーが出るようになったが(これはまあ当然)、それ以外はすべてうまくいった。

```console
mkdir: cannot create directory ‘/root’: Permission denied
Can not write to /root/.m2/copy_reference_file.log. Wrong volume permissions? Carrying on ...
```

### 分かったこと

ということで、分かったことは次のとおり。

- docker runの-uオプションでUID/GIDを指定すれば、Mavenはその通りに動く。指定したUID/GIDがコンテナ側の/etc/passwdや/etc/groupに存在しなくても、Mavenの場合は特に問題なし。
- 環境変数MAVEN_CONFIGは(/usr/share/maven/refに物を置かない限りは)不要だが、mvn-entrypoint.shがエラーを吐かないようにするためには一応指定が必要。
- mvnに渡すuser.homeは、mvnが書き込む.m2の位置を教えるために必要。もしこれが無くて、かつ/root/.m2に書き込み権限がなければ、ワーキングディレクトリの直下に?が作られ、その中に.m2が作られる。

※バージョンメモ

- Ubuntu Server 19.04
- Docker 18.09.5
- Apache Maven 3.6.1
