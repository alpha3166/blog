---
title: "GitHub Pagesの中の絶対パス"
update: 2024-02-10 00:00:00 +0900
---

GitHub Pagesで、サイト内のリンクを**絶対パスで**張るときは、変数`site.baseurl`を使う必要がある。そうしないと、公開サイトとローカルの両方で有効なパスにならないからだ。前回書いたように、[GitHub Pagesをローカルでテストする]({{ site.baseurl }}{% post_url 2019-04-13-GitHub-Pagesをローカルでテストする %})ためには、この考慮が必要になる。

例えば、サイトのトップにindex.htmlがあって、ディレクトリの深いところからトップに戻るリンクを張るとする。ここで絶対パスを

```markdown
[サイトのトップ](/index.html)
```

と書くと、ローカルでは動くが、公開サイトでは動かない。なぜなら、公開サイトのURLは、リポジトリ名を含んだ`https://alpha3166.github.io/blog`のような形をしているので、`/index.html`は、`https://alpha3166.github.io/index.html`と解釈されてしまうからだ。かといって、リンクにリポジトリ名を含めて

```markdown
[サイトのトップ](/blog/index.html)
```

と書くと、今度はローカルで動かなくなる。ローカルでは、`http://localhost:4000/index.html`のように、リポジトリ名がないURLが必要だからだ。

そこで、こういう場合は、サイトの基準パスを変数`site.baseurl`を使って書くようにする。

```markdown
[サイトのトップ]({% raw %}{{ site.baseurl }}{% endraw %}/index.html)
```

GitHub Pagesのサイトでは、_config.ymlに`baseurl`を書いておかなくても、勝手に`https://alpha3166.github.io/blog`のような値が注入されるようだ。

ローカルで動かす場合は、`jekyll serve`のオプションに`--baseurl ""`で空文字列を渡してやる。なので、前回書いたDockerファイルも、最後のCMDにこのオプションを付けるようにする。

```docker
FROM    jekyll/jekyll
RUN     echo "source 'https://rubygems.org'" > Gemfile && \
        echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile && \
        bundle install && \
        rm -f Gemfile Gemfile.lock
RUN     mkdir /srv/src
EXPOSE  4000
WORKDIR /srv/src
CMD     ["bundle", "exec", "jekyll", "serve", "--destination", "/srv/jekyll", "--host", "0.0.0.0", "--baseurl", ""]
```

Dockerイメージのビルドと実行手順は前回と同じ。

```shell
vi Dockerfile
docker build -t gh-pages .
cd サイトのトップディレクトリ
docker run --rm -it -v "$PWD:/srv/src" -p 4000:4000 gh-pages
```

※バージョンメモ

- Ubuntu Server 18.10
- Docker 18.09.3

※更新履歴

- 2020-06-11 誤記訂正。
- 2024-02-10 Jekyll(というか、正確にはLiquid)の[変数展開をエスケープする手段](https://stackoverflow.com/questions/3330979/outputting-literal-curly-braces-in-liquid-templates)を見つけたので、例の中の全角波括弧を半角に修正。

※関連エントリ

- [2019-04-13 GitHub Pagesをローカルでテストする]({{ site.baseurl }}{% post_url 2019-04-13-GitHub-Pagesをローカルでテストする %})
- [2022-10-23 GitHub Pagesにwebrickが必要になった]({{ site.baseurl }}{% post_url 2022-10-23-GitHub-Pagesにwebrickが必要になった %})
