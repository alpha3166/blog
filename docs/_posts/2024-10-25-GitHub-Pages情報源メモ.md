---
title: "GitHub Pages情報源メモ"
categories: ウェブ
series: github-pages
---

## プロダクト一次情報

プロダクト|ホーム|GitHub|Gem
-|-|-|-
GitHub Pages|[Home](https://pages.github.com/), [Docs](https://docs.github.com/ja/pages)|[GitHub](https://github.com/github/pages-gem)|[Gem](https://rubygems.org/gems/github-pages)
Jekyll|[Home](https://jekyllrb.com/), [Docs](https://jekyllrb.com/docs/)|[GitHub](https://github.com/jekyll/jekyll)|[Gem](https://rubygems.org/gems/jekyll)
Jekyll Docs日本語訳|[Docs](https://jekyllrb-ja.github.io/)|[GitHub](https://github.com/jekyllrb-ja/jekyllrb-ja.github.io)|-
Liquid|[Home](https://shopify.github.io/liquid/)|[GitHub](https://github.com/Shopify/liquid)|[Gem](https://rubygems.org/gems/liquid)
Kramdown|[Home](https://kramdown.gettalong.org/)|[GitHub](https://github.com/gettalong/kramdown)|[Gem](https://rubygems.org/gems/kramdown)
Rouge|[Home](https://rouge.jneen.net/)|[GitHub](https://github.com/rouge-ruby/rouge)|[Gem](https://rubygems.org/gems/rouge)
Ruby Sass|[Home](https://sass-lang.com/)|[GitHub](https://github.com/sass/ruby-sass)|[Gem](https://rubygems.org/gems/sass)
Jekyll Feed|-|[GitHub](https://github.com/jekyll/jekyll-feed)|[Gem](https://rubygems.org/gems/jekyll-feed)
Jekyll SEO Tag|[Home](https://jekyll.github.io/jekyll-seo-tag/)|[GitHub](https://github.com/jekyll/jekyll-seo-tag)|[Gem](https://rubygems.org/gems/jekyll-seo-tag)
Jekyll Sitemap|-|[GitHub](https://github.com/jekyll/jekyll-sitemap)|[Gem](https://rubygems.org/gems/jekyll-sitemap)
Jekyll GitHub Metadata|[Home](https://jekyll.github.io/github-metadata/)|[GitHub](https://github.com/jekyll/github-metadata)|[Gem](https://rubygems.org/gems/jekyll-github-metadata)
Bundler|[Home](https://bundler.io/)|[GitHub](https://github.com/rubygems/bundler)|[Gem](https://rubygems.org/gems/bundler)
RubyGems|[Home](https://rubygems.org/)|[GitHub](https://github.com/rubygems/rubygems)|-
Ruby|[Home](https://www.ruby-lang.org/), [Docs](https://docs.ruby-lang.org/ja/latest/doc/index.html)|[GitHub](https://github.com/ruby/ruby)|-

## Gemホワイトリスト

- [GitHub Pagesで使用できるGemとバージョン](https://pages.github.com/versions/)

## テーマ

- [GitHub Pagesで使用できるテーマ](https://pages.github.com/themes/)

テーマ|プレビュー|GitHub|Gem
-|-|-|-
Minima|[Preview](https://jekyll.github.io/minima/)|[GitHub](https://github.com/jekyll/minima)|[Gem](https://rubygems.org/gems/minima)
Architect|[Preview](https://pages-themes.github.io/architect/)|[GitHub](https://github.com/pages-themes/architect)|[Gem](https://rubygems.org/gems/jekyll-theme-architect)
Cayman|[Preview](https://pages-themes.github.io/cayman/)|[GitHub](https://github.com/pages-themes/cayman)|[Gem](https://rubygems.org/gems/jekyll-theme-cayman)
Dinky|[Preview](https://pages-themes.github.io/dinky/)|[GitHub](https://github.com/pages-themes/dinky)|[Gem](https://rubygems.org/gems/jekyll-theme-dinky)
Hacker|[Preview](https://pages-themes.github.io/hacker/)|[GitHub](https://github.com/pages-themes/hacker)|[Gem](https://rubygems.org/gems/jekyll-theme-hacker)
Leap Day|[Preview](https://pages-themes.github.io/leap-day/)|[GitHub](https://github.com/pages-themes/leap-day)|[Gem](https://rubygems.org/gems/jekyll-theme-leap-day)
Merlot|[Preview](https://pages-themes.github.io/merlot/)|[GitHub](https://github.com/pages-themes/merlot)|[Gem](https://rubygems.org/gems/jekyll-theme-merlot)
Mdnight|[Preview](https://pages-themes.github.io/midnight/)|[GitHub](https://github.com/pages-themes/midnight)|[Gem](https://rubygems.org/gems/jekyll-theme-midnight)
Minimal|[Preview](https://pages-themes.github.io/minimal/)|[GitHub](https://github.com/pages-themes/minimal)|[Gem](https://rubygems.org/gems/jekyll-theme-minimal)
Modernist|[Preview](https://pages-themes.github.io/modernist/)|[GitHub](https://github.com/pages-themes/modernist)|[Gem](https://rubygems.org/gems/jekyll-theme-modernist)
Primer|[Preview](https://pages-themes.github.io/primer/)|[GitHub](https://github.com/pages-themes/primer)|[Gem](https://rubygems.org/gems/jekyll-theme-primer)
Slate|[Preview](https://pages-themes.github.io/slate/)|[GitHub](https://github.com/pages-themes/slate)|[Gem](https://rubygems.org/gems/jekyll-theme-slate)
Tactile|[Preview](https://pages-themes.github.io/tactile/)|[GitHub](https://github.com/pages-themes/tactile)|[Gem](https://rubygems.org/gems/jekyll-theme-tactile)
Time Machine|[Preview](https://pages-themes.github.io/time-machine/)|[GitHub](https://github.com/pages-themes/time-machine)|[Gem](https://rubygems.org/gems/jekyll-theme-time-machine)

## 変数

- [GitHub Pagesの変数](https://jekyll.github.io/github-metadata/site.github/)
- [Jekyllの変数](https://jekyllrb.com/docs/variables/)

## シンタックスハイライト

- [Rougeで指定可能な言語](https://rouge-ruby.github.io/docs/file.Languages.html)

## フィルター

- [Jekyllのフィルター](https://jekyllrb.com/docs/liquid/filters/)
- [Liquidのフィルター](https://shopify.github.io/liquid/filters/)

### Liquidのフィルター分類

■文字列操作

- `prepend`, `append`: {先頭、末尾}に文字列を付加

- `remove`, `remove_first`: {全ての、最初の}文字列を除去
- `slice`: n番目(0始まり)からm文字切り出し
- `strip`, `lstrip`, `rstrip`： {先頭と末尾、先頭、末尾}の空白を除去
- `strip_newlines`: 改行を除去
- `strip_html`: HTMLタグを除去

- `replace`, `replace_first`: {全ての、最初の}文字列を置換
- `upcase`, `downcase`, `capitalize`: {大文字に、小文字に、センテンスケースに}
- `truncate`, `truncatewords`: 末尾を...に置換して全体を{n文字、n語}に
- `newline_to_br`: 改行を&lt;br /&gt;に
- `escape`, `escape_once`: HTMLエスケープ(_onceは元からエスケープ済の個所はそのまま)
- `url_encode`, `url_decode`: URLエンコード、URLデコード

- `split`: 文字列を分割して配列に
- `size`: 文字数

■算術演算

- `plus`, `minus`, `times`, `divided_by`: 加減乗除
- `modulo`: 剰余
- `ceil`, `floor`, `round`: 切り上げ、切り捨て、四捨五入
- `abs`: 絶対値
- `at_least`, `at_most`: nより{小さければ、大きければ}nに

■配列操作

- `join`: 配列の要素を結合して文字列に
- `first`, `last`: {先頭、末尾}の要素
- `sort`, `sort_natural`: ソート(_naturalは大文字小文字を無視)
- `uniq`: 重複要素を除去
- `reverse`: 要素を逆順に
- `compact`: nil要素を除去
- `concat`: 2つの配列の要素を結合
- `map`: 要素から指定属性を取り出した配列を作成
- `where`: 条件に合致する要素を取り出した配列を作成
- `size`: 要素数
- `sum`: 合計

■日付時刻操作

- `date`: タイムスタンプを[strftime形式](https://docs.ruby-lang.org/ja/latest/method/Time/i/strftime.html)指定でフォーマット(フィルタ対象が"now"か"today"ならページ生成時刻を使用)

■変数操作

- `default`: 変数がnilかfalseなら指定値を代入
