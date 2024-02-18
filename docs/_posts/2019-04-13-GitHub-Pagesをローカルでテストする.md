---
title: "GitHub Pagesをローカルでテストする"
categories: ウェブページ作り
update: 2020-06-11 00:00:00 +0900
series: github-pages
---

GitHub Pagesをローカルでテストする方法は、公式ページの[Testing your GitHub Pages site locally with Jekyll](https://help.github.com/en/github/working-with-github-pages/testing-your-github-pages-site-locally-with-jekyll)で説明されてるんだけど、これが結構分かりにくい。初心者の自分には、何が必須で何がオプションなのか、よくわからなかったのですよ。

## 実験

なので、いろいろ試してみた。ここではDocker Hubの`jekyll/jekyll:latest`を使ってみる。

### 実験1: 素のJekyllだとどうなるか

`index.md`だけがあるディレクトリで、Bundlerを使わない素のJekyllにて`jekyll serve`すると、どうなるか。なお、途中で`cd /srv/jekyll`してるのは、ここじゃないとJekyllさんが「_siteの書き込み権限ないよ」と怒るため。Jekyllさんはrootじゃなくてjekyllっていうユーザで動くんですね。`/srv/jekyll`はあらかじめオーナーがjekyllになってるので問題なし。

```shell
docker run --rm -it -p 4000:4000 jekyll/jekyll bash
cd /srv/jekyll
echo "# Hello World!" > index.md
jekyll serve
```

これだと、ブラウザでアクセスしても、ディレクトリのファイル一覧が出るだけ。index.mdをクリックしても、mdファイルがそのまま流れてくるだけ。

### 実験2: Bundler経由のJekyllだとどうなるか

公式説明にあるとおり、Gemfileにgithub-pagesのGemを書いて、Bundler経由で起動してみる。なお、`bundle install`ではかなりの数のGemが落ちてくるので、結構時間がかかる。

```shell
echo "source 'https://rubygems.org'" > Gemfile
echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile
bundle install
bundle exec jekyll serve
```

で、この状態だと「GitHubのリポジトリの名前が分からん」というエラーになって、サーバが起動しない。

```console
Configuration file: none
            Source: /srv/jekyll
       Destination: /srv/jekyll/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
   GitHub Metadata: No GitHub API authentication could be found. Some fields may be missing or have incorrect data.
   GitHub Metadata: Error processing value 'title':
  Liquid Exception: No repo name found. Specify using PAGES_REPO_NWO environment variables, 'repository' in your configuration, or set up an 'origin' git remote pointing to your github.com repository. in /_layouts/default.html
             ERROR: YOUR SITE COULD NOT BE BUILT:
                    ------------------------------------
                    No repo name found. Specify using PAGES_REPO_NWO environment variables, 'repository' in your configuration, or set up an 'origin' git remote pointing to your github.com repository.
```

エラーメッセージに書かれてるとおり、「環境変数`PAGES_REPO_NWO`」か「`_config.yml`の`repository`」か「gitの`origin`」のどれかで、GitHubのリポジトリ名に相当するものを指定してやらないとダメ。

ここでは`_config.yml`の`repository`でGitHubのリポジトリ名を指定してみる。なお、`serve`に`--host 0.0.0.0`を付けてるのは、Bundler経由だとデフォルトが127.0.0.1だけにバインドされてしまい、外からアクセスできなくなるから。

```shell
echo "repository: alpha3166/blog" > _config.yml
bundle exec jekyll serve --host 0.0.0.0
```

これでサーバーは起動し、ちゃんとmdはHTMLに変換されて表示されるようになった。でも、出てくるのはそっけない、何の装飾もないページ。

### 実験3: テーマを指定するとどうなるか

`_config.yml`の`theme`で、[GitHub Pagesがサポートしているテーマ](https://pages.github.com/themes/)を指定してみる。この例ではCaymanを使用。

```shell
echo "theme: jekyll-theme-cayman" >> _config.yml
bundle exec jekyll serve --host 0.0.0.0
```

おお、ようやく出ましたよ。GitHub Pagesと同じ画面が。

## テストしやすい環境を作る

というわけで、ロカールのJekyllでGitHub Pagesと同じ表示を再現する条件は、次のとおり。

- Bundler経由でJekyllを起動すること。
- Gemfileにgithub-pagesのGemを書くこと。
- 「環境変数`PAGES_REPO_NWO`」か「`_config.yml`の`repository`」か「gitの`origin`」のどれかで、GitHubのリポジトリ名を指定すること。
- `_config.yml`の`theme`で、[GitHub Pagesがサポートしているテーマ](https://pages.github.com/themes/)を指定すること。

となると、github-pagesのGemを指定して`bundle install`までやった状態のDockerイメージを作っておくのがよさげ。ソースはコンテナ作成時に外から供給することにして、出力先はソースからは分離しておこう。こんな感じかな。

```docker
FROM    jekyll/jekyll
RUN     echo "source 'https://rubygems.org'" > Gemfile && \
        echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile && \
        bundle install && \
        rm -f Gemfile Gemfile.lock
RUN     mkdir /srv/src
EXPOSE  4000
WORKDIR /srv/src
CMD     ["bundle", "exec", "jekyll", "serve", "--destination", "/srv/jekyll", "--host", "0.0.0.0"]
```

上記の内容をDockerfileに書いて、あらかじめ`docker build`しておく。イメージ名は、例えば`gh-pages`で。

```shell
docker build -t gh-pages .
```

ページの確認をするときは、ソースの入ったディレクトリをコンテナの/srv/srcにマッピングしてから起動する感じで。

```shell
echo "# Hello World!" > index.md
echo "source 'https://rubygems.org'" > Gemfile
echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile
echo "repository: alpha3166/blog" > _config.yml
echo "theme: jekyll-theme-cayman" >> _config.yml
docker run --rm -it -v "$PWD:/srv/src" -p 4000:4000 gh-pages
```

※バージョンメモ

- Ubuntu Server 18.10
- Docker 18.09.3

※更新履歴

- 2020-06-11 外部リンク最新化、表現修正、誤記訂正。
