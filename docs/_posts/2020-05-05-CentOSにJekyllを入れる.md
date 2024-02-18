---
title: "CentOSにJekyllを入れる"
categories: ウェブ
---

CentOS 8にJekyllを入れようとしたら、依存関係などが意外と面倒だったので、ちょっと整理。

やりたいことは、ただこれだけ。

- 素のCentOSにRubyを入れて、
- JekyllのGemを入れて、
- jekyll new mysiteでサイトひな形を生成して、
- bundle exec jekyll serveで動かす。

確認にはVagrantのcentos/8(VirtualBox版)を使用した。

VM構築直後に下記でパッケージ全体を最新化して再起動しているので、CentOSのバージョンは8.1.1911。

```shell
sudo dnf upgrade
```

## dnfでRubyを入れ、gemでJekyllを入れる場合

- Rubyは古いバージョン(2.5.5)が入る。
- Bundlerが自動では入らないので(Rubyに標準添付されるようになったのは2.6から)、自分でgem installする。最新版が入る。sudo無しでgem installすると、Gemは~/.gem/rubyに入る。
- Jekyllをgem installするには、native extensionsのビルドのためにruby-devel、make、gcc、rpm-build、gcc-c++が必要。
- Jekyllは最新版が入る。

Rubyのインストール:

```shell
sudo dnf install ruby
```

Bundlerのインストール:

```shell
gem install bundler
```

Jekyllのインストール:

```shell
sudo dnf install ruby-devel make gcc rpm-build gcc-c++
gem install jekyll
```

入るコマンドのバージョンとインストール先:

|コマンド|バージョン|インストール先|
|-|-|-|
|ruby|2.5.5p157 (古い)|/usr/bin/ruby|
|gem|2.7.6.2 (古い)|/usr/bin/gem|
|bundle|2.1.4 (最新)|~/bin/bundle|
|jekyll|4.0.0 (最新)|~/bin/jekyll|

Gemのインストール先:

- ~/.gem/ruby

## snapでRubyを入れ、gemでJekyllを入れる場合

- snapdを入れるには、Extra Packages for Enterprise Linux (EPEL)リポジトリの追加が必要。dnf installでsnapdを入れたら、snapの通信ソケットを有効にして、classic snap用にシンボリックリンクを作成し、PATH反映のためにログインし直す。これでsnapコマンドが使えるようになる。
- snap install rubyには--classicをつける必要あり。初回はなぜか「error: too early for operation, device not yet seeded or device model not acknowledged」と言われて止まるが、2回目はうまくいった。snapで最新版のRubyを入れるとなぜかgemやbundleがエラーになるので(詳細は後述)、やむなくひとつ前のバージョン2.6/stableにした。
- Jekyllをgem installするには、native extensionsのビルドのためにmake、gcc、gcc-c++が必要。
- Jekyllは最新版が入る。

snapdのインストールと設定:

```shell
sudo dnf install epel-release
sudo dnf install snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
# ここでPATH反映のため再ログイン
```

Rubyのインストール:

```shell
sudo snap install ruby --classic --channel=2.6/stable    # 初回はエラーになるが2回目は成功
```

Jekyllのインストール:

```shell
sudo dnf install make gcc gcc-c++
gem install jekyll
```

入るコマンドのバージョンとインストール先:

|コマンド|バージョン|インストール先|
|-|-|-|
|ruby|2.6.6p146 (1つ前)|/var/lib/snapd/snap/bin/ruby|
|gem|3.0.3 (1つ前)|/var/lib/snapd/snap/bin/gem|
|bundle|2.1.4 (最新)|/var/lib/snapd/snap/bin/bundle|
|jekyll|4.0.0 (最新)|~/.gem/bin/jekyll|

Gemのインストール先:

- ~/.gem

## rbenvでRubyを入れ、gemでJekyllを入れる場合

- gitを入れ、rbenvをgit cloneで入れ、PATHと環境設定コマンドを.bash_profileに追加してsourceする。
- Rubyのインストール用に、ruby-buildをgit cloneで入れる。
- Rubyのインストールにはgcc、make、openssl-develが必要。
- rbenv installでRubyのバージョンを指定してインストールする。ここでは現時点で最新の2.7.1を指定。
- インストールできたら、使用するRubyバージョンをrbenv localで指定すると、設定が./.ruby-versionに保存される。
- Jekyllをgem installするには、native extensionsのビルドのためにmake、gcc、gcc-c++が必要。
- インストールするGemは~/.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0に入るので、gem installにsudoは不要。

rbenvのインストールと設定:

```shell
sudo dnf install git
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
sudo dnf install gcc make openssl-devel
rbenv install 2.7.1
```

Rubyの使用バージョン指定:

```shell
rbenv local 2.7.1
```

Jekyllのインストール:

```shell
sudo dnf install gcc-c++
gem install jekyll
```

入るコマンドとインストール先:

|コマンド|インストール先|
|-|-|
|ruby|~/.rbenv/shims/ruby|
|gem|~/.rbenv/shims/gem|
|bundle|~/.rbenv/shims/bundle|
|jekyll|~/.rbenv/shims/jekyll|

上記は、現在使用中のバージョンのコマンドに飛ばすためのラッパー。コマンドの実体は下記。

|コマンド|バージョン|インストール先|
|-|-|-|
|ruby|2.7.1p83 (最新)|~/.rbenv/versions/2.7.1/bin/ruby|
|gem|3.1.2 (最新)|~/.rbenv/versions/2.7.1/bin/gem|
|bundle|2.1.4 (最新)|~/.rbenv/versions/2.7.1/bin/bundle|
|jekyll|4.0.0 (最新)|~/.rbenv/versions/2.7.1/bin/jekyll|

Gemのインストール先:

- ~/.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0

## 補足: snapで最新版のRubyを入れるとなぜかgemやbundleがエラーになる

これを書いている時点では、snapで最新版(--channel=stable、Ruby 2.7.1)のRubyをインストールすると、rubyコマンドは実行できるのに、そのほかの付属コマンドであるbundle、gem、irb、rake、rdoc、riなどを実行すると下記のようなエラーが出る。--channel=2.6/stable (Ruby 2.6.6)ではこの事象は出ない。ちなみにCentOS 7でも同様。

```console
$ ruby -v
ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-linux]
$ gem -v
/snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:12: warning: already initialized constant Gem::VERSION
/var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:12: warning: previous definition of VERSION was here
/snap/ruby/181/lib/ruby/2.7.0/rubygems/compatibility.rb:15: warning: already initialized constant Gem::RubyGemsVersion
/var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/compatibility.rb:15: warning: previous definition of RubyGemsVersion was here
[...]
Traceback (most recent call last):
        5: from /var/lib/snapd/snap/ruby/181/bin/gem:8:in `<main>'
        4: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
        3: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
        2: from /snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:1397:in `<top (required)>'
        1: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
/var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require': cannot load such file -- rubygems/defaults/operating_system (LoadError)
        14: from /var/lib/snapd/snap/ruby/181/bin/gem:8:in `<main>'
        13: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
        12: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
        11: from /snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:1397:in `<top (required)>'
        10: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:156:in `require'
        9: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:161:in `rescue in require'
        8: from /snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:204:in `try_activate'
        7: from /snap/ruby/181/lib/ruby/2.7.0/rubygems/specification.rb:996:in `find_by_path'
        6: from /snap/ruby/181/lib/ruby/2.7.0/rubygems/specification.rb:815:in `stubs'
        5: from /snap/ruby/181/lib/ruby/2.7.0/rubygems/specification.rb:932:in `dirs'
        4: from /snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:420:in `path'
        3: from /snap/ruby/181/lib/ruby/2.7.0/rubygems.rb:374:in `paths'
        2: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
        1: from /var/lib/snapd/snap/ruby/181/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:72:in `require'
/snap/ruby/181/lib/ruby/2.7.0/rubygems/path_support.rb:7:in `<top (required)>': uninitialized constant Gem::PathSupport (NameError)
```

※バージョンメモ

- VirtualBox 6.1.6
- Vagrant 2.2.7
- CentOS 8.1.1911 (vagrant box centos/8 (virtualbox, 1905.1))
