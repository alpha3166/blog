---
title: "GitHub Pagesにwebrickが必要になった"
categories: ウェブページ作り
series: github-pages
---

ひさびさに、[GitHub Pagesをローカルでテストする](20190413.html)に書いた手順でJekyllを立ち上げてみたら、こんなエラーが出て起動に失敗した。

```console
bundler: failed to load command: jekyll (/usr/gem/bin/jekyll)
/usr/gem/gems/jekyll-3.9.2/lib/jekyll/commands/serve/servlet.rb:3:in `require': cannot load such file -- webrick (LoadError)
```

どうやらRuby 3.0からwebrickというGemの追加が必要になったらしく、`bundle add webrick`したら元通り動くようになった。

というわけで、Dockerファイルにも、Gemfileの依存Gemとしてwebrickを書き足すことにした。

```docker
FROM    jekyll/jekyll
RUN     echo "source 'https://rubygems.org'" > Gemfile && \
        echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile && \
        echo "gem 'webrick'" >> Gemfile && \
        bundle install && \
        rm -f Gemfile Gemfile.lock
RUN     mkdir /srv/src
EXPOSE  4000
WORKDIR /srv/src
CMD     ["bundle", "exec", "jekyll", "serve", "--destination", "/srv/jekyll", "--host", "0.0.0.0", "--baseurl", ""]
```
