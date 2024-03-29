---
title: "UbuntuにJekyllを入れる"
categories: ウェブ
---

Ubuntu 18.04にJekyllを入れようとしたら、依存関係などが意外と面倒だったので、ちょっと整理。

やりたいことは、ただこれだけ。

- 素のUbuntuにRubyを入れて、
- JekyllのGemを入れて、
- jekyll new mysiteでサイトひな形を生成して、
- bundle exec jekyll serveで動かす。

確認にはVagrantのubuntu/bionic64(VirtualBox版)を使用した。

## aptでJekyllを入れる場合

- aptでJekyllを入れるだけで、勝手にRubyも入る。いずれもバージョンは古い(Ruby 2.5.1、Jekyll 3.1.6)。
- Bundlerは自動では入らないので(Rubyに標準添付されるようになったのは2.6から)、これもaptで入れると、やっぱり古いバージョンが入る(1.16.1)。ただし、Jekyll 3.1.6はBundlerが無くともjekyll newやjekyll serveができるようなので、入れなくてもよさそう。
- 依存関係を気にしなくて済むのでこれが一番手軽だが、如何せんすべてのバージョンが古い……。

Jekyll(とRuby)のインストール:

```shell
sudo apt update
sudo apt install jekyll
```

Bundlerのインストール:

```shell
sudo apt install ruby-bundler
```

入るコマンドのバージョンとインストール先:

コマンド|バージョン|インストール先
-|-|-
ruby|2.5.1p57 (古い)|/usr/bin/ruby
gem|2.7.6 (古い)|/usr/bin/gem
bundle|1.16.1 (古い)|/usr/bin/bundle
jekyll|3.1.6 (古い)|/usr/bin/jekyll

Gemのインストール先:

- /var/lib/gems/2.5.0

## aptでRubyを入れ、gemでJekyllを入れる場合

- Rubyは古いバージョン(2.5.1)が入る。
- Bundlerが自動では入らないので、自分でgem installする。最新版が入る。
- Jekyllをgem installするには、native extensionsのビルドのためにruby-dev、make、gcc、g++が必要。
- Jekyllは最新版が入る。

Rubyのインストール:

```shell
sudo apt update
sudo apt install ruby
```

Bundlerのインストール:

```shell
sudo gem install bundler
```

Jekyllのインストール:

```shell
sudo apt install ruby-dev make gcc g++
sudo gem install jekyll
```

入るコマンドのバージョンとインストール先:

コマンド|バージョン|インストール先
-|-|-
ruby|2.5.1p57 (古い)|/usr/bin/ruby
gem|2.7.6 (古い)|/usr/bin/gem
bundle|2.1.4 (最新)|/usr/local/bin/bundle
jekyll|4.0.0 (最新)|/usr/local/bin/jekyll

Gemのインストール先:

- /var/lib/gems/2.5.0

## snapでRubyを入れ、gemでJekyllを入れる場合

- snap install rubyには--classicをつける必要あり。
- 最新のRubyが/snap/binに入る。
- Jekyllをgem installするには、native extensionsのビルドのためにmake、gcc、g++が必要。
- インストールするGemは~/.gemに入るので、gem installにsudoは不要。
- Jekyllは最新版が入る。jekyll newのようにコマンドとして実行する場合は、~/.gem/binにPATHを通すか、フルパスで実行する必要あり。

Rubyのインストール:

```shell
sudo snap install ruby --classic
```

Jekyllのインストール:

```shell
sudo apt update
sudo apt install make gcc g++
gem install jekyll
```

入るコマンドのバージョンとインストール先:

コマンド|バージョン|インストール先
-|-|-
ruby|2.7.1p83 (最新)|/snap/bin/ruby
gem|3.1.2 (最新)|/snap/bin/gem
bundle|2.1.4 (最新)|/snap/bin/bundle
jekyll|4.0.0 (最新)|~/.gem/bin/jekyll

Gemのインストール先:

- ~/.gem

## rbenvでRubyを入れ、gemでJekyllを入れる場合

- rbenvをgit cloneで入れ、PATHと環境設定コマンドを.bash_profileに追加してsourceする。
- Rubyのインストール用に、ruby-buildをgit cloneで入れる。
- Rubyのインストールにはgcc、make、libssl-dev、zlib1g-devが必要。
- rbenv installでRubyのバージョンを指定してインストールする。ここでは現時点で最新の2.7.1を指定。
- インストールできたら、使用するRubyバージョンをrbenv localで指定すると、設定が./.ruby-versionに保存される。
- Jekyllをgem installするには、native extensionsのビルドのためにmake、gcc、g++が必要。
- インストールするGemは~/.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0に入るので、gem installにsudoは不要。

rbenvのインストールと設定:

```shell
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
~/.rbenv/bin/rbenv init    # 指示が表示される
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
. ~/.bash_profile
```

ruby-buildプラグインのインストール:

```shell
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
```

Rubyのインストール:

```shell
sudo apt update
sudo apt install gcc make libssl-dev zlib1g-dev
rbenv install 2.7.1
```

Rubyの使用バージョン指定:

```shell
rbenv local 2.7.1
```

Jekyllのインストール:

```shell
sudo apt install g++
gem install jekyll
```

入るコマンドとインストール先:

コマンド|インストール先
-|-
ruby|~/.rbenv/shims/ruby
gem|~/.rbenv/shims/gem
bundle|~/.rbenv/shims/bundle
jekyll|~/.rbenv/shims/jekyll

上記は、現在使用中のバージョンのコマンドに飛ばすためのラッパー。コマンドの実体は下記。

コマンド|バージョン|インストール先
-|-|-
ruby|2.7.1p83 (最新)|~/.rbenv/versions/2.7.1/bin/ruby
gem|3.1.2 (最新)|~/.rbenv/versions/2.7.1/bin/gem
bundle|2.1.4 (最新)|~/.rbenv/versions/2.7.1/bin/bundle
jekyll|4.0.0 (最新)|~/.rbenv/versions/2.7.1/bin/jekyll

Gemのインストール先:

- ~/.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0

## 所感

用途にもよるが、この中だと最新版が使えて導入も手軽な「snapでRubyを入れ、gemでJekyllを入れる」方式がいちばんよさそう。Ubuntuの新しめのバージョンを使う場合は、全部aptで入れるのもありか。

※バージョンメモ

- VirtualBox 6.1.6
- Vagrant 2.2.7
- Utuntu 18.04 (vagrant box ubuntu/bionic64 (virtualbox, 20200429.0.0))
