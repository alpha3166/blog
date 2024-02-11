#!/bin/bash -e

cd docs

# remove dinky files
rm _layouts/default.html
rm assets/css/style.scss

# modify _config.yml
sed -i -f - << 'EOF' _config.yml
s/jekyll-theme-dinky/minima/
/github:/ d
/owner_name:/ d
/owner_url:/ d
EOF
cat << 'EOF' >> _config.yml
author: alpha3166
twitter_username: alpha3166
bluesky_username: alpha3166.bsky.social
github_username: alpha3166
timezone: Asia/Tokyo
minima:
  date_format: "%Y-%m-%d"
defaults:
- scope:
    type: posts
  values:
    layout: post
    permalink: /:year:month:day:output_ext
EOF

# move posts
mkdir _posts
mv 2*.md _posts

# add front matter to posts
(
  cd _posts
  for file in *; do
    sed -r -i -f - <<EOF $file
1 s/^# (.*)$/---\ntitle: \"\\1\"/
2 d
3 s/^[0-9-]{10}作成$/---/
3 s/^([0-9-]{10})最終更新.*$/update: \\1 00:00:00 +0900\n---/
EOF
  done
  for file in *a.md; do
    sed -r -i -e "3 a permalink: /${file/.md/:output_ext}" $file
  done
)

# rename posts
cat /dev/null > ../replace_post_links.sed
(
  cd _posts
  for file in *; do
    new_file=${file:0:4}-${file:4:2}-${file:6:2}-$(sed -r -e "1 d" -e "3,$ d" -e "s/^title: \"(.*)\"/\\1/" -e "s/[ ()?!/:]/-/g" $file)
    echo "s!(${file})!({% post_url ${new_file} %})!g" >> ../../replace_post_links.sed
    mv $file ${new_file}.md
  done
)

# fix links to posts
(
  cd _posts
  for file in *; do
    sed -i -f ../../replace_post_links.sed $file
  done
)
sed -i -f ../replace_post_links.sed index_by_category.md

# replace index.md
cat << 'EOF' > index.md
---
layout: home
title: ""
date: 2019-04-13 00:00:00 +0900
---

## 倉庫

- [カテゴリ別リスト](index_by_category.md)
- [FontConfig User Documentationの日本語化](resources/fontconfig-user_ja.html)
- [iOS 5.0.1 Special Characters](resources/ios501specialchars.html)
- [iPhone待受画面用カレンダー画像(2012年)](resources/iPhoneCal2012.png) (png, 1120×1680, 36KB)
- [EBPocket for iOSの「三修社 12か国語大辞典」用外字マップ](resources/SANDICxx.zip) (zip, 1KB)
- [Software Design 2018.01～2024.03 総目次](resources/software-design-index.html)
- [響け!ユーフォニアム(アニメ版)部員名簿 改訂版](resources/kitauji-members.html)
EOF

# modify index_by_category.md
sed -r -i -e "1 s/^# (.*)$/---\ntitle: \\1\ndate: 2019-04-13 00:00:00 +0900\n---/" index_by_category.md

# clone minima
if [[ ! -d ~/minima ]]; then
  (
    cd
    git clone --branch 2.5-stable https://github.com/jekyll/minima
  )
fi

# prepare jekyll directories
mkdir _includes
mkdir _sass
mkdir _sass/minima

# replace header.html
cat << 'EOF' > _includes/header.html
<header class="my-site-header" role="banner">
  <div class="wrapper">
    <div>
      <div><a class="my-site-title" href="{{ "/" | relative_url }}">{{ site.title }}</a></div>
      <div class="my-site-description">{{ site.description }}</div>
    </div>
    <div>
      <div class="my-site-author">
        <img class="my-site-author-icon" src="{{ site.baseurl}}/img/{{ site.author }}.jpg" />{{ site.author }}
      </div>
      <div class="my-social">
        {%- if site.twitter_username -%}
        <a href="https://twitter.com/{{ site.twitter_username }}/">
          <svg class="my-social-icon" viewBox="0 -0.5 16 16" version="1.1" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M16 3.038c-.59.26-1.22.437-1.885.517.677-.407 1.198-1.05 1.443-1.816-.634.37-1.337.64-2.085.79-.598-.64-1.45-1.04-2.396-1.04-1.812 0-3.282 1.47-3.282 3.28 0 .26.03.51.085.75-2.728-.13-5.147-1.44-6.766-3.42C.83 2.58.67 3.14.67 3.75c0 1.14.58 2.143 1.46 2.732-.538-.017-1.045-.165-1.487-.41v.04c0 1.59 1.13 2.918 2.633 3.22-.276.074-.566.114-.865.114-.21 0-.41-.02-.61-.058.42 1.304 1.63 2.253 3.07 2.28-1.12.88-2.54 1.404-4.07 1.404-.26 0-.52-.015-.78-.045 1.46.93 3.18 1.474 5.04 1.474 6.04 0 9.34-5 9.34-9.33 0-.14 0-.28-.01-.42.64-.46 1.2-1.04 1.64-1.7z" />
          </svg>
        </a>
        {%- endif -%}
        {%- if site.bluesky_username -%}
        <a href="https://bsky.app/profile/{{ site.bluesky_username }}">
          <svg class="my-social-icon" viewBox="10 9 35 35" version="1.1" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M27.5,25.73c-1.6-3.1-5.94-8.89-9.98-11.74c-3.87-2.73-5.35-2.26-6.31-1.82c-1.12,0.51-1.32,2.23-1.32,3.24c0,1.01,0.55,8.3,0.92,9.51c1.2,4.02,5.45,5.38,9.37,4.94c0.2-0.03,0.4-0.06,0.61-0.08c-0.2,0.03-0.41,0.06-0.61,0.08c-5.74,0.85-10.85,2.94-4.15,10.39c7.36,7.62,10.09-1.63,11.49-6.33c1.4,4.69,3.01,13.61,11.35,6.33c6.27-6.33,1.72-9.54-4.02-10.39c-0.2-0.02-0.41-0.05-0.61-0.08c0.21,0.03,0.41,0.05,0.61,0.08c3.92,0.44,8.18-0.92,9.37-4.94c0.36-1.22,0.92-8.5,0.92-9.51c0-1.01-0.2-2.73-1.32-3.24c-0.97-0.44-2.44-0.91-6.31,1.82C33.44,16.85,29.1,22.63,27.5,25.73z" />
          </svg>
        </a>
        {%- endif -%}
        {%- if site.github_username -%}
        <a href="https://github.com/{{ site.github_username }}/">
          <svg class="my-social-icon" viewBox="0 -0.3 16 16" version="1.1" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M8 0C3.58 0 0 3.582 0 8c0 3.535 2.292 6.533 5.47 7.59.4.075.547-.172.547-.385 0-.19-.007-.693-.01-1.36-2.226.483-2.695-1.073-2.695-1.073-.364-.924-.89-1.17-.89-1.17-.725-.496.056-.486.056-.486.803.056 1.225.824 1.225.824.714 1.223 1.873.87 2.33.665.072-.517.278-.87.507-1.07-1.777-.2-3.644-.888-3.644-3.953 0-.873.31-1.587.823-2.147-.09-.202-.36-1.015.07-2.117 0 0 .67-.215 2.2.82.64-.178 1.32-.266 2-.27.68.004 1.36.092 2 .27 1.52-1.035 2.19-.82 2.19-.82.43 1.102.16 1.915.08 2.117.51.56.82 1.274.82 2.147 0 3.073-1.87 3.75-3.65 3.947.28.24.54.73.54 1.48 0 1.07-.01 1.93-.01 2.19 0 .21.14.46.55.38C13.71 14.53 16 11.53 16 8c0-4.418-3.582-8-8-8" />
          </svg>
        </a>
        {%- endif -%}
      </div>
    </div>
  </div>
</header>
EOF

# replace footer.html
cat << 'EOF' > _includes/footer.html
<footer class="my-site-footer h-card">
  <div class="wrapper">
    <div>
      © {{ page.date | date: "%Y" }} {{ site.author | escape }}
    </div>
  </div>
</footer>
EOF

# replace home.html
cat << 'EOF' > _layouts/home.html
---
layout: default
---

<div class="home">
  {%- if site.posts.size > 0 -%}
    <ul class="post-list">
      {%- for post in site.posts -%}
      <li>
        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
        <span class="post-meta">{{ post.date | date: date_format }}
          {%- if post.update -%}
          &#x20;({{ post.update | date: date_format }} 更新)
          {%- endif -%}
        </span>
        <h3>
          <a class="post-link" href="{{ post.url | relative_url }}">
            {{ post.title | escape }}
          </a>
        </h3>
        {%- if site.show_excerpts -%}
          {{ post.excerpt }}
        {%- endif -%}
      </li>
      {%- endfor -%}
    </ul>

  {%- endif -%}

  {{ content }}
</div>
EOF

# modify post.html (show modified date on posts)
cp ~/minima/_layouts/post.html _layouts
cat << 'EOF' | sed -r -i -e "/<\\/time>/ r /dev/stdin" _layouts/post.html
      {%- if page.update -%}
      <time class="dt-published" datetime="{{ page.update | date_to_xmlschema }}" itemprop="dateUpdated">
        ({{ page.update | date: date_format }} 更新)
      </time>
      {%- endif -%}</p>
EOF

# modify minima.scss (widen screen width)
cp ~/minima/_sass/minima.scss _sass
sed -r -i -e "s/ 800px / 1000px /" _sass/minima.scss

# modify _base.scss (delete clearfix)
cp ~/minima/_sass/minima/_base.scss _sass/minima
sed -r -i -e "/@extend %clearfix/ d" -e "/%clearfix:after/,+4 d" _sass/minima/_base.scss

# modify _layout.scss (delete clearfix)
cp ~/minima/_sass/minima/_layout.scss _sass/minima
sed -r -i -e "/@extend %clearfix/ d" _sass/minima/_layout.scss

# create local.scss
cat << 'EOF' > assets/local.scss
---
---

$spacing-unit:     30px !default;

$text-color:       #111 !default;
$brand-color:      #2a7ae2 !default;

$grey-color:       #828282 !default;
$grey-color-light: lighten($grey-color, 40%) !default;
$grey-color-dark:  darken($grey-color, 25%) !default;

body {
  margin: 0;
  padding: 0;
}

a {
  color: $brand-color;
  text-decoration: none;

  &:visited {
    color: darken($brand-color, 15%);
  }

  &:hover {
    color: $text-color;
    text-decoration: underline;
  }
}

.my-site-header {
  border-top: 5px solid $grey-color-dark;
  border-bottom: 1px solid $grey-color-light;
  min-height: $spacing-unit * 1.865;
}

.my-site-header>.wrapper {
  display: flex;
  flex-flow: row wrap;
  justify-content: space-between;
  align-items: baseline;
}

.my-site-header>.wrapper>div {
  display: flex;
  flex-flow: row wrap;
  align-items: baseline;
}

.my-site-header>.wrapper>div>div {
  padding: 0.2em;
}

.my-site-title {
  font-size: x-large;
  letter-spacing: -1px;
  &,
  &:visited {
    color: $grey-color-dark;
  }
}

.my-site-description,
.my-site-author {
  color: gray;
}

.my-site-author-icon {
  height: 1.4em;
  border-radius: 50%;
  padding-right: 0.2em;
  vertical-align: middle;
}

.my-social {
  position: relative;
  top: 0.25em;

  a:link,
  a:visited {
    color: gray
  }

  a:active,
  a:hover {
    text-decoration: none;
    color: initial;
  }
}

.my-social-icon {
  height: 1.2em;
  fill: currentColor;
  padding: 0 0.2em;
}

.my-site-footer {
  text-align: center;
  color: gray;
  border-top: 1px solid $grey-color-light;
  padding: $spacing-unit 0;
}
EOF

# modify head.html (add link to local.css)
cp ~/minima/_includes/head.html _includes
sed -r -i -f - << 'EOF' _includes/head.html
/X-UA-Compatible/ d
/stylesheet/ a \ \ <link rel="stylesheet" href="{{ "/assets/local.css" | relative_url }}">
EOF

# create localhead.html
cat << 'EOF' > _includes/localhead.html
<meta name="viewport" content="width=device-width, initial-scale=1">
{%- seo -%}
<link rel="stylesheet" href="{{ "/assets/local.css" | relative_url }}">
{%- if jekyll.environment == 'production' and site.google_analytics -%}
  {%- include google-analytics.html -%}
{%- endif -%}
EOF

# integrate fontconfig-user_ja.html
sed -r -i -f - << 'EOF' resources/fontconfig-user_ja.html
s/<!DOCTYPE/---\ntitle: fonts-conf 日本語版\ndate: 2011-05-15 00:00:00 +0900\n---\n<!DOCTYPE/
/<TITLE/,/<\/TITLE/ d
s!</HEAD!{%- include localhead.html -%}</HEAD!
16 s!>!>{%- include header.html -%}!
s!></BODY!>{%- include footer.html -%}</BODY!
EOF

# integrate ios501specialchars.html
sed -r -i -f - << 'EOF' resources/ios501specialchars.html
s/<!DOCTYPE/---\ntitle: iOS 5.0.1 Special Characters\ndate: 2012-02-19 00:00:00 +0900\n---\n<!DOCTYPE/
s!<title>.*</title>!{%- include localhead.html -%}!
/<body>/ a \ \ {%- include header.html -%}
/<\/body>/ i \ {%- include footer.html -%}
EOF

# integrate kitauji-members.html
sed -r -i -f - << 'EOF' resources/kitauji-members.html
s/<!DOCTYPE/---\ntitle: 響け!ユーフォニアム(アニメ版)部員名簿\ndate: 2023-08-11 00:00:00 +0900\n---\n<!DOCTYPE/
s!<title>.*</title>!{%- include localhead.html -%}!
/<body>/ a \ \ \ \ {%- include header.html -%}
/<\/table>/ a \ \ \ \ {%- include footer.html -%}
s/部員名簿/部員名簿 改訂版/
/Google tag/,+8 d
EOF

# integrate software-design-index.html
sed -r -i -f - << 'EOF' resources/software-design-index.html
s/<!DOCTYPE/---\ntitle: Software Design 2018.01～2024.03 総目次\ndate: 2022-11-23 00:00:00 +0900\n---\n<!DOCTYPE/
s!<title>.*</title>!{%- include localhead.html -%}!
/<body>/ a \ \ \ \ {%- include header.html -%}
/<\/table>/ a \ \ \ \ {%- include footer.html -%}
/Google tag/,+8 d
EOF

# remove index.md in resources
rm resources/index.md

# replace google-analytics.html
cat << 'EOF' > _includes/google-analytics.html
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id={{ site.google_analytics }}"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', '{{ site.google_analytics }}');
    </script>
EOF
