---
title: "GitでShift_JISファイルの文字コードを遡及して修正する"
categories: プログラミング
---

## .gitattributesでエンコーディングの変換を指示する

テキストファイルのエンコーディングはUTF-8が当たり前となって久しいが、Windowsを使っていると、未だにShift_JISにしなければならないことがある (正確にはCP932、あるいはWindows-31Jにしなければならないと言うべきか)。バッチファイル (bat) や、ExcelなどのVBAマクロをエクスポートしたファイル (bas、cls、fmt) などがそれだ。

GitでShift_JISのテキストファイルを管理するとき、何も設定しないと、リポジトリ内部のファイルもShift_JISになってしまう。その状態でもバージョン管理は可能だが、`git show`や`git diff`で日本語が16進数表示になってしまうなどの不便さがある。

そこで、`.gitattributes`で特定の拡張子の`working-tree-encoding`をcp932に指定しておくことが多い (正確には拡張子だけでなく`.gitignore`と同じようにパスのパターンを指定できる)。たとえばこのように。

```plaintext
* text=auto
*.bat text working-tree-encoding=cp932 eol=crlf
*.ps1 text working-tree-encoding=cp932 eol=crlf
*.bas text working-tree-encoding=cp932 eol=crlf
*.cls text working-tree-encoding=cp932 eol=crlf
*.frm text working-tree-encoding=cp932 eol=crlf
```

1行目の`* text=auto`は「どれがテキストファイルかの判断はGitにお任せする」という指定だ。そして、Gitがテキストファイルだと判断したものは、コミット時に改行コードがLFに自動変換されたうえで、リポジトリに格納される。この設定は、configの`core.autocrlf`よりも強い。そのため、使う人の設定に依存しない統一的な指定ができる。`.gitattributes`の指定は「あと勝ち」なので、この指定がデフォルトとなり (`*`で全パスに適用される)、その下に個別指定を書いていく。

2行目以降の`text`は「この拡張子はテキストファイルで、改行コードやエンコーディングの変換を行う対象である」ことを明示している。

`eol=crlf`は、チェックアウト時に改行コードをCRLFに変換し、コミット時にLFに変換することを指定している。

そして`working-tree-encoding=cp932`は、チェックアウト時にエンコーディングをUTF-8からCP932に変換し、コミット時にCP932からUTF-8に変換することを指定している。つまり、`working-tree-encoding=なんとか`を指定すると、リポジトリ内のファイルのエンコーディングはUTF-8になる。よって、`git show`や`git diff`でも日本語が表示されるようになる。

と、ここまでは、ちょっと検索するとあちこちに書かれている話だ。

※参考資料

- [Git - gitattributes Documentation](https://git-scm.com/docs/gitattributes)

## 途中でエンコーディング変換を追加したときの問題点

問題なのは、最初は`working-tree-encoding`なしで管理していて、途中で`git show`などの見え方がおかしいことに気づき、`working-tree-encoding=cp932`を追加したようなケースだ。この場合の問題点はいくつかある。

■問題点1: **触っていないファイルまで変更があったと認識される**

`.gitattributes`に`working-tree-encoding=cp932`を書いて保存した瞬間、その拡張子のファイルはすべて「リポジトリ内ではUTF-8**のはず**のファイル」になる。しかし実際にはまだリポジトリ内はCP932のままだ。この状態で`git diff`を取ると、「リポジトリ内の、実際はCP932なのにGitがUTF-8だと思い込んでいるファイル」と、「ワーキングディレクトリの、CP932からUTF-8に変換したファイル」の比較が行われるため、当然両者は不一致となる。その結果、実際には触っていなくても、その拡張子の全ファイルがワーキングディレクトリで修正ありとみなされてしまう。

■問題点2: **予期せぬ変更が紛れ込んでいても気付かない**

そして、そのまま「変更あり」と言われた全ファイルをコミットすると、触っていないと思っていたファイルにうっかり別の変更が紛れ込んでいたのに気付かなかった、という事故があり得る。何せ、`git diff`を取っても「全行変わってます」としか言われないのだから。

■問題点3: **過去との比較ができない**

また、このコミットでリポ内のファイルのエンコーディングに断絶が生まれるため、それ以前のコミットとは内容比較ができなくなる。改行コードの違いならオプションでなんとかなるが、エンコーディングの違いは如何ともしがたく、今後は断絶を跨いだ差分は取れなくなる。

■問題点4: **過去のコミット内容は16進数表示のまま**

断絶前のコミットは、リポジトリ内部ではCP932のままなので、相変わらず`git show`や`git diff`で日本語が16進数表示になってしまう。

## 遡及修正する方法

根本的な対処をするなら、あたかも最初から`working-tree-encoding=cp932`を指定していたかのようなふりをして、コミットをやり直す必要がある。その手順を試行錯誤した結果、成功したやり方をここに書いておく。ただし、実際にはもっと良いやり方がある可能性が高い。また、過去の履歴の改変になるので、**ほかの人が触っているブランチにpushする場合は慎重にやる**必要がある。いったん別のブランチで修正して一定期間後に正規のブランチと差し替えるとか、全員に履歴の改変があったことを周知徹底するとかの考慮が必要だろう。

遡及修正のコンセプトは、(特に驚きはないと思うが) `git rebase -i`を使って**最初のコミット**に`.gitattributes`を追加することだ。

手順の概略は次の通り。

1. 修正対象のブランチに切り替える
1. 最初のコミットのさらに前から対話的リベースを始める
1. 最初のコミット前で停止させる
1. `.gitattributes`を追加して修正コミットする
1. 以降のコミットは順次エラーで停止するので、修正コミットを繰り返す

### 手順1: 修正対象のブランチに切り替える

```shell
git switch some-branch
```

既存のブランチは触らず、いったん新しいブランチで作業するなら下記。

```shell
git switch -c some-branch master
```

### 手順2: 最初のコミットのさらに前から対話的リベースを始める

```shell
git rebase -i --root -Xtheirs
```

最初のコミット直前で明示的に停止させたいので、`-i` (または`--interactive`) で対話的リベースにする。対話的リベースにすると、このあとエディタでコミットのリストが開き、どこで停止させるかをコミットごとに指定できる。

リベースの引数には、リベースを始めるコミット**の親**を指定する必要がある。今回はいちばん最初のコミットから修正したいので、その親を指定したいが、いちばん最初のコミットなので親がいない。そういうときは、`--root`を付けると「ほんとに最初の何もないところから始める」を指定したことになる。

以降の各コミットでは、リポ内にCP932のファイルがあると、基本的にすべてコンフリクトで停止する。なぜなら、リポ内では「ひとつ前のコミットがすでにUTF-8に変わっているので、それをこのコミットでCP932に変えたような歴史がある」ように見える一方で、ワーキングディレクトリの方では、「実際はCP932なのにUTF-8だと思ってCP932に変換しようとしてエラーになり、仕方なくCP932のバイナリファイルがそのままチェックアウトされて、それをUTF-8に変換したものをコミットしようとしている」ように見えるので、要はお互いが逆方向の変換をしようとしていると解釈され、コンフリクトが発生するのだ (理解できた?)。その結果Gitは、リベースの相手版と自分版を両方取り込んでコンフリクトマーカーをつけたファイルを生成して停止する。なので、そのままではいちいち手動で各ファイルを開いてコンフリクトを解消する必要が出てくる。`-Xtheirs`を付けておくと、自動的に自分版を採用したファイルを作ってくれるので、すでにコンフリクトは解消した状態となり、大幅に手間が省ける。なお、「自分版なら-Xtheirsじゃなくて-Xoursじゃないの?」と思われた方は大変マトモな感性をお持ちだと思うが、リベースは内部的にはいったんリベース相手のブランチにスイッチするような動きをするので、マージのときとはtheirsとoursが逆になる。よってここは「-Xours」ではなく「-Xtheirs」を指定するのが正解だ。

### 手順3: 最初のコミット前で停止させる

エディタでコミットのリストが表示されるので、最初のコミット (いちばん上の行のコミット) だけ`pick`を`edit`に書き換え、閉じる。これにより対話的リベースが始まり、最初のコミットの直前で一旦停止する。

### 手順4: `.gitattributes`を追加して修正コミットする

```shell
cat > .gitattributes <<EOF
* text=auto
*.bat text working-tree-encoding=cp932 eol=crlf
*.ps1 text working-tree-encoding=cp932 eol=crlf
*.bas text working-tree-encoding=cp932 eol=crlf
*.cls text working-tree-encoding=cp932 eol=crlf
*.frm text working-tree-encoding=cp932 eol=crlf
EOF
git add .
git commit --amend --no-edit
```

`git commit`には`--amend`を付けないと、元のコミットに加えてもう1個余計なコミットが生まれてしまうので、ここは`--amend`付きが正解だ。

また、`--no-edit`を付けることで、元のコミットメッセージがそのまま採用される。もし`--no-edit`を付けないと、カラのコミットメッセージからスタートすることになるので、元と同じメッセージを入れ直す必要がある (メッセージを変えたいなら付けなくても良いが)。

### 手順5: 以降のコミットは順次エラーで停止するので、修正コミットを繰り返す

```shell
git rebase --continue
git add .
git commit --amend --no-edit
```

`git rebase --continue`で、リベース対象の次のコミットに移動する。2番目以降のコミットは、コミットリストで`pick`のままにしているので、何事もなければそのまま採用されるが、手順2で述べたとおり、CP932のファイルがあるコミットでは基本的にすべて「error: failed to encode 'foo.bat' from UTF-8 to cp932」のようなエラーで停止するはずだ。

だが、手順2で`-Xtheirs`を付けておいたおかげで、ワーキングディレクトリのファイルの中身はすでにコンフリクトが解消した状態になっている。そのため、あとは`git add .`でコンフリクトが解消したことを宣言し、修正コミットしてやればよい。

この手順を最後のコミットまで繰り返す。数は多いが、単純な固定コマンドの繰り返しだけで行けるはずだ。

## 動作確認ログ

以下は、上記の手順でうまくいくか確認したときの動作ログ。ご参考までに。

まずはCP932であることを忘れて5回コミットしてしまった状況を作る。UTF-8のままでよい`foo.bash`と、CP932に補正したい`foo.bat`と`foo.ps1`があるとする。中身は最初「あ」から初めて、「い」、「う」、「え」、「お」に変更して5回コミットする。

コマンド:

```shell
git init test
cd test
git config --local core.autocrlf input

for word in あ い う え お; do
  echo $word > foo.bash
  echo $word | iconv -t SJIS | sed -e 's/$/\r/' > foo.bat
  echo $word | iconv -t SJIS | sed -e 's/$/\r/' > foo.ps1
  git add .
  git commit -m $word
done
```

実行結果:

```console
$ git init test
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint:   git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint:   git branch -m <name>
Initialized empty Git repository in /home/alpha3166/test/.git/
$ cd test
$ git config --local core.autocrlf input
$ for word in あ い う え お; do
>   echo $word > foo.bash
>   echo $word | iconv -t SJIS | sed -e 's/$/\r/' > foo.bat
>   echo $word | iconv -t SJIS | sed -e 's/$/\r/' > foo.ps1
>   git add .
>   git commit -m $word
> done
warning: in the working copy of 'foo.bat', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'foo.ps1', CRLF will be replaced by LF the next time Git touches it
[master (root-commit) a4e044e] あ
 3 files changed, 3 insertions(+)
 create mode 100644 foo.bash
 create mode 100644 foo.bat
 create mode 100644 foo.ps1
warning: in the working copy of 'foo.bat', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'foo.ps1', CRLF will be replaced by LF the next time Git touches it
[master 633500c] い
 3 files changed, 3 insertions(+), 3 deletions(-)
warning: in the working copy of 'foo.bat', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'foo.ps1', CRLF will be replaced by LF the next time Git touches it
[master 190fde0] う
 3 files changed, 3 insertions(+), 3 deletions(-)
warning: in the working copy of 'foo.bat', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'foo.ps1', CRLF will be replaced by LF the next time Git touches it
[master 42d836c] え
 3 files changed, 3 insertions(+), 3 deletions(-)
warning: in the working copy of 'foo.bat', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'foo.ps1', CRLF will be replaced by LF the next time Git touches it
[master 97f7d1a] お
 3 files changed, 3 insertions(+), 3 deletions(-)
```

ここで問題に気付く。`git show`すると、`foo.bat`と`foo.ps1`の日本語が文字化けしている。

コマンド:

```shell
git log --graph --oneline --all
git show
```

実行結果:

```console
$ git log --graph --oneline --all
* 97f7d1a (HEAD -> master) お
* 42d836c え
* 190fde0 う
* 633500c い
* a4e044e あ
$ git show
commit 97f7d1aa5fc238d3979db14a48c7b392ad8a6fa5 (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    お

diff --git a/foo.bash b/foo.bash
index 6807f54..e916450 100644
--- a/foo.bash
+++ b/foo.bash
@@ -1 +1 @@
-え
+お
diff --git a/foo.bat b/foo.bat
index 740acef..9017314 100644
--- a/foo.bat
+++ b/foo.bat
@@ -1 +1 @@
-<82><A6>
+<82><A8>
diff --git a/foo.ps1 b/foo.ps1
index 740acef..9017314 100644
--- a/foo.ps1
+++ b/foo.ps1
@@ -1 +1 @@
-<82><A6>
+<82><A8>
```

リベースで補正する。

コマンド:

```shell
git rebase -i --root -Xtheirs

# コミットリストで最初のコミットだけeditにしてエディタを閉じる

cat > .gitattributes <<EOF
* text=auto
*.bat text working-tree-encoding=cp932 eol=crlf
*.ps1 text working-tree-encoding=cp932 eol=crlf
*.bas text working-tree-encoding=cp932 eol=crlf
*.cls text working-tree-encoding=cp932 eol=crlf
*.frm text working-tree-encoding=cp932 eol=crlf
EOF
git add .
git commit --amend --no-edit

# い
git rebase --continue
git add .
git commit --amend --no-edit

# う
git rebase --continue
git add .
git commit --amend --no-edit

# え
git rebase --continue
git add .
git commit --amend --no-edit

# お
git rebase --continue
git add .
git commit --amend --no-edit
```

実行結果:

```console
$ git rebase -i --root -Xtheirs
```

```plaintext
edit a4e044e あ
pick 633500c い
pick 190fde0 う
pick 42d836c え
pick 97f7d1a お

# Rebase 97f7d1a onto 0b84c30 (5 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
(...)
```

```console
$ git rebase -i --root -Xtheirs
Stopped at a4e044e...  あ
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ cat > .gitattributes <<EOF
* text=auto
*.bat text working-tree-encoding=cp932 eol=crlf
*.ps1 text working-tree-encoding=cp932 eol=crlf
*.bas text working-tree-encoding=cp932 eol=crlf
*.cls text working-tree-encoding=cp932 eol=crlf
*.frm text working-tree-encoding=cp932 eol=crlf
EOF
$ git add .
warning: in the working copy of 'foo.bat', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'foo.ps1', LF will be replaced by CRLF the next time Git touches it
$ git commit --amend --no-edit
[detached HEAD 5d14c01] あ
 Date: Sat Oct 26 13:36:44 2024 +0900
 4 files changed, 9 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 foo.bash
 create mode 100644 foo.bat
 create mode 100644 foo.ps1
$ git rebase --continue
error: failed to encode 'foo.bat' from UTF-8 to cp932
error: failed to encode 'foo.ps1' from UTF-8 to cp932
error: Your local changes to the following files would be overwritten by merge:
        foo.bat
        foo.ps1
Please commit your changes or stash them before you merge.
Aborting
hint: Could not execute the todo command
hint:
hint:     pick 190fde0ab7e0ea29d6ae8b7f6278bc8fb9810918 う
hint:
hint: It has been rescheduled; To edit the command before continuing, please
hint: edit the todo list first:
hint:
hint:     git rebase --edit-todo
hint:     git rebase --continue
$ git add .
$ git commit --amend --no-edit
[detached HEAD e1137ee] い
 Date: Sat Oct 26 13:36:44 2024 +0900
 3 files changed, 3 insertions(+), 3 deletions(-)
$ git rebase --continue
error: failed to encode 'foo.bat' from UTF-8 to cp932
error: failed to encode 'foo.ps1' from UTF-8 to cp932
error: Your local changes to the following files would be overwritten by merge:
        foo.bat
        foo.ps1
Please commit your changes or stash them before you merge.
Aborting
hint: Could not execute the todo command
hint:
hint:     pick 42d836cd1b7e2db69d92b0137df7d804aa243d87 え
hint:
hint: It has been rescheduled; To edit the command before continuing, please
hint: edit the todo list first:
hint:
hint:     git rebase --edit-todo
hint:     git rebase --continue
$ git add .
$ git commit --amend --no-edit
[detached HEAD 1f61f58] う
 Date: Sat Oct 26 13:36:44 2024 +0900
 3 files changed, 3 insertions(+), 3 deletions(-)
$ git rebase --continue
error: failed to encode 'foo.bat' from UTF-8 to cp932
error: failed to encode 'foo.ps1' from UTF-8 to cp932
error: Your local changes to the following files would be overwritten by merge:
        foo.bat
        foo.ps1
Please commit your changes or stash them before you merge.
Aborting
hint: Could not execute the todo command
hint:
hint:     pick 97f7d1aa5fc238d3979db14a48c7b392ad8a6fa5 お
hint:
hint: It has been rescheduled; To edit the command before continuing, please
hint: edit the todo list first:
hint:
hint:     git rebase --edit-todo
hint:     git rebase --continue
$ git add .
$ git commit --amend --no-edit
[detached HEAD 24790ce] え
 Date: Sat Oct 26 13:36:44 2024 +0900
 3 files changed, 3 insertions(+), 3 deletions(-)
$ git rebase --continue
error: failed to encode 'foo.bat' from UTF-8 to cp932
error: failed to encode 'foo.ps1' from UTF-8 to cp932
Successfully rebased and updated refs/heads/master.
$ git add .
$ git commit --amend --no-edit
[master 3375b46] お
 Date: Sat Oct 26 13:36:44 2024 +0900
 3 files changed, 3 insertions(+), 3 deletions(-)
```

補正後の内容を確認する。

コマンド:

```shell
git show HEAD
git show HEAD~
git show HEAD~2
git show HEAD~3
git show HEAD~4
```

```console
$ git show HEAD
commit 3375b460a775e98df6526c0dc3f7ab9d358722ca (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    お

diff --git a/foo.bash b/foo.bash
index 6807f54..e916450 100644
--- a/foo.bash
+++ b/foo.bash
@@ -1 +1 @@
-え
+お
diff --git a/foo.bat b/foo.bat
index 6807f54..e916450 100644
--- a/foo.bat
+++ b/foo.bat
@@ -1 +1 @@
-え
+お
diff --git a/foo.ps1 b/foo.ps1
index 6807f54..e916450 100644
--- a/foo.ps1
+++ b/foo.ps1
@@ -1 +1 @@
-え
+お
$ git show HEAD~
commit 24790cea4af551534c74d60bddea9ee00057ebf4
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    え

diff --git a/foo.bash b/foo.bash
index 6b89e43..6807f54 100644
--- a/foo.bash
+++ b/foo.bash
@@ -1 +1 @@
-う
+え
diff --git a/foo.bat b/foo.bat
index 6b89e43..6807f54 100644
--- a/foo.bat
+++ b/foo.bat
@@ -1 +1 @@
-う
+え
diff --git a/foo.ps1 b/foo.ps1
index 6b89e43..6807f54 100644
--- a/foo.ps1
+++ b/foo.ps1
@@ -1 +1 @@
-う
+え
$ git show HEAD~2
commit 1f61f58313e0fe2c55ca9bea82ca74a146a16888
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    う

diff --git a/foo.bash b/foo.bash
index c408b52..6b89e43 100644
--- a/foo.bash
+++ b/foo.bash
@@ -1 +1 @@
-い
+う
diff --git a/foo.bat b/foo.bat
index c408b52..6b89e43 100644
--- a/foo.bat
+++ b/foo.bat
@@ -1 +1 @@
-い
+う
diff --git a/foo.ps1 b/foo.ps1
index c408b52..6b89e43 100644
--- a/foo.ps1
+++ b/foo.ps1
@@ -1 +1 @@
-い
+う
$ git show HEAD~3
commit e1137eed7a257ee53ba6317a2d9366b0cc819fc4
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    い

diff --git a/foo.bash b/foo.bash
index f2435a2..c408b52 100644
--- a/foo.bash
+++ b/foo.bash
@@ -1 +1 @@
-あ
+い
diff --git a/foo.bat b/foo.bat
index f2435a2..c408b52 100644
--- a/foo.bat
+++ b/foo.bat
@@ -1 +1 @@
-あ
+い
diff --git a/foo.ps1 b/foo.ps1
index f2435a2..c408b52 100644
--- a/foo.ps1
+++ b/foo.ps1
@@ -1 +1 @@
-あ
+い
$ git show HEAD~4
commit 5d14c01cc161b7812898ecd5a94256e7d9eca8cc
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Oct 26 13:36:44 2024 +0900

    あ

diff --git a/.gitattributes b/.gitattributes
new file mode 100644
index 0000000..3505a3c
--- /dev/null
+++ b/.gitattributes
@@ -0,0 +1,6 @@
+* text=auto
+*.bat text working-tree-encoding=cp932 eol=crlf
+*.ps1 text working-tree-encoding=cp932 eol=crlf
+*.bas text working-tree-encoding=cp932 eol=crlf
+*.cls text working-tree-encoding=cp932 eol=crlf
+*.frm text working-tree-encoding=cp932 eol=crlf
diff --git a/foo.bash b/foo.bash
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/foo.bash
@@ -0,0 +1 @@
+あ
diff --git a/foo.bat b/foo.bat
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/foo.bat
@@ -0,0 +1 @@
+あ
diff --git a/foo.ps1 b/foo.ps1
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/foo.ps1
@@ -0,0 +1 @@
+あ
```

※バージョンメモ

- git version 2.43.0
