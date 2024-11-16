---
title: "GitでShift_JISファイルの文字コードを遡及して修正する"
categories: プログラミング
update: 2024-11-10 00:00:00 +0900
---

## .gitattributesでエンコーディングの変換を指示する

テキストファイルのエンコーディングはUTF-8が当たり前となって久しいが、Windowsを使っていると、未だにCP932 (Shift_JISをマイクロソフトが独自に拡張したエンコーディング、別名Windows-31J) にしなければならないことがある。バッチファイル (bat) や、ExcelのVBAマクロをエクスポートしたファイルなど (bas、cls、frm) がそれだ。

GitでCP932のテキストファイルを管理するとき、何も設定しないとリポジトリ内部にもCP932で格納されてしまう。その状態でもバージョン管理は可能だが、素の`git show`や`git diff`では日本語が16進数表示になってしまう。もちろん、`.gitattributes`でdiffにiconvを噛ませるとか、TortoiseGitにエンコーディングを推測させるなどの手もあるが、やはりリポ内のテキストファイルはすべてUTF-8に統一されている方が扱いやすい。

そこで自分は、`.gitattributes`で特定の拡張子の`working-tree-encoding`を`cp932`に指定している。たとえばこのように。

```plaintext
*.bat text working-tree-encoding=cp932 eol=crlf
*.bas text working-tree-encoding=cp932 eol=crlf
*.cls text working-tree-encoding=cp932 eol=crlf
*.frm text working-tree-encoding=cp932 eol=crlf
```

`.gitattributes`の1列目には、`.gitignore`と同じ文法で、設定を適用する対象のパスを指定する。

2列目の`text`は、1列目のパスに該当するものがテキストファイルであり、3列目以降の設定を適用することを宣言している。

3列目の`working-tree-encoding=cp932`は、チェックイン時 (つまり`git add`でファイルがインデックスに追加されるとき) にエンコーディングをCP932からUTF-8に変換し、チェックアウト時にUTF-8からCP932に変換するよう指示している。つまり、`working-tree-encoding=なんとか`を指定すると、リポジトリ内のファイルのエンコーディングはUTF-8になる。よって、`git show`や`git diff`でも日本語が表示されるようになる。

4列目の`eol=crlf`は、チェックイン時に改行コードがCR+LFだったらLFに変換し (最初からLFならそのまま)、チェックアウト時にLFからCR+LFに変換するよう指示している。この指示は、Gitプロパティの`core.eol`や`core.autocrlf`よりも強い。そのため、使う人の設定やOSに依存しない統一的な指定ができる。WindowsのバッチファイルはCR+LFでないと動かないし、Unix系のシェルスクリプトはLFでないと悲惨な事故が起こったりするので、強制的に変換する設定はアリだろう。

と、ここまでは、ちょっと検索するとあちこちに書かれている話だ。

※参考資料

- [Git - gitattributes Documentation](https://git-scm.com/docs/gitattributes)

## 途中でエンコーディング変換を追加したときの問題点

問題なのは、最初は`.gitattributes`なしで管理していて、途中で`git show`などの見え方がおかしいことに気づき、`working-tree-encoding=cp932`を追加したようなケースだ。この場合の問題点はいくつかある。

■問題点1: **触っていないファイルまで変更があったと認識される**

`.gitattributes`に`working-tree-encoding=cp932`を書いて保存した瞬間、その拡張子のファイルはすべて「リポ内ではUTF-8**のはず**のファイル」になる。しかし、実際にはリポ内のファイルはまだCP932のままだ。この状態で`git diff`を取ると、「リポ内の、GitがUTF-8だと思い込んでいるファイル (実際はCP932)」と、「ワーキングディレクトリの、CP932からUTF-8に変換したファイル」の比較が行われるため、当然両者は不一致となる。その結果、実際には触っていなくても、その拡張子の全ファイルがワーキングディレクトリで修正ありとみなされてしまう。

■問題点2: **予期せぬ変更が紛れ込んでいても気付かない**

そして、そのまま「変更あり」と言われた全ファイルをコミットすると、触っていないと思っていたファイルにうっかり別の変更が紛れ込んでいたのに気付かなかった、という事故があり得る。何せ、`git diff`を取っても「全行変わってます」としか言われないのだから。

■問題点3: **過去との比較ができない**

また、このコミットでリポ内のファイルのエンコーディングに断絶が生まれるため、それ以前のコミットとは内容比較ができなくなる。改行コードの違いならオプションでなんとかなるが、エンコーディングの違いは如何ともしがたく、今後は断絶を跨いだ差分は取れなくなる。

■問題点4: **過去のコミット内容は16進数表示のまま**

断絶前のコミットは、リポ内部ではCP932のままなので、相変わらず`git show`や`git diff`で日本語が16進数表示になってしまう。

## 遡及修正する方法

根本的な対処をするなら、あたかも最初から`working-tree-encoding=cp932`を指定していたかのようなふりをして、コミットをやり直す必要がある。その手順を試行錯誤した結果、成功したやり方をここに書いておく。ただし、実際にはもっと良いやり方がある可能性が高い。また、過去の履歴の改変になるので、**ほかの人が触っているブランチにpushする場合は慎重にやる**必要がある。いったん別のブランチで修正して一定期間後に正規のブランチと差し替えるとか、全員に履歴の改変があったことを周知徹底するとかの考慮が必要だろう。

遡及修正のコンセプトは、(特に驚きはないと思うが) `git rebase -i`を使って**最初のコミット**に`.gitattributes`を追加することだ。

### 手順の概略

遡及修正の大まかな手順は次の通り。

1. 修正対象のブランチをチェックアウトする  
   例: `git switch master`

1. ブランチをバックアップする  
   例: `git branch old-master`

1. 最初のコミットから、`-Xrenormalize`を付けて対話的リベースする  
   例: `git rebase -i --root -Xrenormalize`

1. 最初から最後までの全コミットで停止して編集すると宣言する  
   例: `:%s/^pick/edit/` (viの場合)

1. 最初のコミットに`.gitattributes`を追加し、拡張子ごとのエンコーディング変換の設定を書く  
   例: `echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes`

1. `.gitattributes`を`git add`する  
   例: `git add .`

1. 全ファイルを`git add`する  
   例: `git add .`

1. 修正コミットする  
   例: `git commit --amend --no-edit`

1. `git show`で差分を確認し、問題があれば補正して、問題が無くなるまで上の2つを繰り返す  
   例: `git show`

1. 次のコミットに移る  
   例: `git rebase --continue`

1. 最後のコミットに到達するまで上の4つを繰り返す

1. 元のブランチのコミットを指していたタグを調べ、手動で新コミットに向けなおす  
   例: `git tag -f v1.0.0 f2435a2`

以下、いくつかポイントを説明する。

### ブランチをバックアップする

遡及修正がうまくいったように見えても、作業中には気付かなかった問題が残っているかもしれない。元はどうなってたんだっけ、とか、改めてイチから遡及修正しなおそう、ということが必ずあるので、修正前の履歴 (コミット) もずっと残しておくのが安全だ。

ブランチをバックアップするといっても、Gitのブランチは特定のコミットを指すポインタに過ぎないので、手順としては`git branch 新ブランチ名 元のブランチ名`で新たにポインタを作るだけだ。`元のブランチ名`を省略した場合は、現在チェックアウトしているブランチから新ブランチを派生させるという意味になる。

### 最初のコミットからリベースする

`git rebase`の引数には、リベースを始めるコミット**の親**を指定する必要がある。今回はいちばん最初のコミットから修正したいので、その親を指定したいが、何せいちばん最初のコミットなので親がいない。そういうときは、`--root`を付けると「ほんとに最初の何もないところから始める」を指定したことになる。

### -Xrenormalizeを付けてリベースする

リベース中の各コミットでは、CP932のファイルがあると、基本的にすべて「CONFLICT (content)」が発生し、そのコミットをリプレイするのに失敗する。なぜなら、

- この時点でワーキングディレクトリのファイルの中身はCP932だが、`working-tree-encoding=cp932`の効力で、GitにはUTF-8に変換した姿として見えている。
- これからリプレイしようとしているコミットは、元のブランチ (中身はCP932) におけるコミットの差分なので、CP932のテキストをCP932のテキストに書き換えるパッチに相当する。

という状況なので、「GitにはUTF-8に見えているワーキングディレクトリのファイル」に「CP932で書かれたパッチ」を適用しようとしても、適用先の行が見つかるはずもない。その結果的Gitは、ファイルの中身全体がコンフリクトしたと判断し、「リベースの相手版」(ワーキングディレクトリのファイルをUTF-8に変換した版) と「自分版」(元のブランチのCP932版) を両方取り込んで、コンフリクトマーカーをつけたファイルを生成する。

また、CP932のファイルを削除したコミットがある場合は「CONFLICT (modify/delete)」が発生し、削除したはずのファイルはワーキングディレクトリに残ったままになる。

コンフリクトによりコミットのリプレイが失敗した結果、そのコミットは未実施の状態になる。そのため、毎回下記を行う必要がある。

- 「CONFLICT (content)」については、手動で各ファイルを開いて編集し、コンフリクトを解消する。
- 「CONFLICT (modify/delete)」については、削除したはずのファイルを手動で削除する。
- `--amend`を付けない`git commit`をして、コミットメッセージを入力しなおす。

`git rebase`に`-Xrenormalize`オプションを付けておくと、元のブランチのコミット差分を取る際にも、各コミットに同じ`.gitattributes`の内容を適用して一度仮想的にチェックイン、チェックアウトした後の状態でパッチを作ってくれるので、UTF-8のパッチができあがる (たぶん)。その結果、上記のようなコンフリクトが発生することもなくなり、各`git rebase --continue`ごとに、自動的にパッチを適用してコミットまでされた状態で停止する。よって、手動でのコンフリクト解消や、コミット時にメッセージを入力しなおす手間が省ける。

(なお、この記事の2024-11-02版では`git rebase`に`-Xtheirs`も付けていたが、`-Xrenormalize`を付けていればそもそもコンフリクトが発生しないため、`-Xtheirs`は付けない手順に変えた。また、各コミットで停止した後の`git add`にも`--renormalize`を付けていたが、こちらも`git rebase`に`-Xrenormalize`を付けていれば不要であったため、外した)

### 全コミットで停止して「git add .」する

当初は、`.gitattributes`を追加する最初のコミットだけ`edit`にして、ほかは`pick`のままでよいだろうと思っていた。しかし実際には、途中でCP932の新規ファイルがあるとそのファイルだけリポ内がCP932のままになるなどの問題が発生した。

安全のためには、全コミットを`edit`で止めて、都度`git add .`をするのが良いと思う。また、修正コミットしたあとは毎回`git show`で問題ないか確認するのが良い。そのためには、結局全コミットを`edit`にして停止させる必要がある。

なお、`git rebase -i`するときに、環境変数`GIT_SEQUENCE_EDITOR`に`sed -i s/^pick/edit/`を設定しておくと、edit todoファイルの編集時のエディタとしてsedが使われるので、手動で編集する必要がなくなる。

ここまでを総合すると、結局リベースコマンドはこうするのが早そうだ。

```shell
GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xrenormalize
```

### --no-editをつけて修正コミットする

基本的に、この遡及修正ではファイルのエンコーディング (と場合によっては改行コード) を変換したいだけで、変更内容やコミットメッセージを変えたいわけではない。`git commit --amend`に`--no-edit`を付けると、元のコミットメッセージがそのまま採用されるので、メッセージの編集画面を開いて閉じる手間が省ける。もしコミットメッセージを意図的に変えたいのなら、もちろん`--no-edit`を付けなくてもよい。

### git showで差分を確認し、問題があれば補正して修正コミットする

この記事の初版ではもっと簡単な手順で行けると踏んでいたのだが、実践してみると、あちこちで結果が想定どおりになっていなかった。その後判明した注意ポイントは可能な限り上に書いたのだが、それでもまだ想定外の事象は発生するだろうと思う。それに、例えば特定期間のコミットにだけ特殊な拡張子でCP932ファイルが存在する場合などは、適宜`.gitattributes`の中身を増やしたり減らしたりしたい場合もある。

それを考えると、結果的には全コミットでリベースを止めて、`git add . && git commit --amend --no-edit`した後は、必ず`git show`で想定通りになっているか確認し、もし想定外のことがあれば補正してもう一度`git add . && git commit --amend --no-edit`し、完全に満足するまでそれを繰り返すのがむしろ時間の節約になりそうだ。

### 元のブランチのコミットを指していたタグを調べ、手動で新コミットに向けなおす

Gitのタグ (軽量タグ) は、特定のコミットを指すポインタだ。この手順で遡及修正したブランチでは全てのコミットが作り直されるため、どのコミットにもタグはついていない状態になる。修正後のブランチをホンモノとする際には、旧コミットを指していたタグは、すべて新コミットに向けなおす必要があるだろう。

タグの数が少なければ、新しいタグが指すべきコミットを調べて`git tag -f タグ名 コミット`でポイント先を強制変更すれば良い。タグの数が多い場合は何らかの手段で自動化が必要だと思うが、それはまた別途ということにしよう。

## 動作確認ログ

以下は、上記の手順でうまくいくか確認したときの動作ログ。ご参考までに。

まず、CP932であることを忘れてコミットしてしまった状況を作る。各コミットで下記を行った想定とする。

1. cp932.batとutf8.bashを追加: あ (v1.0.0のタグを振る)
1. cp932.batの中身を変更: あ→い
1. utf8.bashの中身を変更: あ→い
1. another-cp932.batを追加: い
1. cp932.batを削除: い
1. another-cp932.batとutf8.bashの中身を変更: い→う

コマンド:

```shell
git init test
cd test
git config --local user.email alpha3166@example.com

echo あ | iconv -t SJIS | sed -e 's/$/\r/' > cp932.bat
echo あ > utf8.bash
git add .
git commit -m "1. cp932.batとutf8.bashを追加: あ"

git tag v1.0.0

echo い | iconv -t SJIS | sed -e 's/$/\r/' > cp932.bat
git add .
git commit -m "2. cp932.batの中身を変更: あ→い"

echo い > utf8.bash
git add .
git commit -m "3. utf8.bashの中身を変更: あ→い"

echo い | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
git add .
git commit -m "4. another-cp932.batを追加: い"

git rm cp932.bat
git commit -m "5. cp932.batを削除: い"

echo う | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
echo う > utf8.bash
git add .
git commit -m "6. another-cp932.batとutf8.bashの中身を変更: い→う"
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
Initialized empty Git repository in /home/alpha/test/.git/
$ cd test
$ git config --local user.email alpha3166@example.com
$ echo あ | iconv -t SJIS | sed -e 's/$/\r/' > cp932.bat
$ echo あ > utf8.bash
$ git add .
warning: in the working copy of 'cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "1. cp932.batとutf8.bashを追加: あ"
[master (root-commit) f43f68a] 1. cp932.batとutf8.bashを追加: あ
 2 files changed, 2 insertions(+)
 create mode 100644 cp932.bat
 create mode 100644 utf8.bash
$ git tag v1.0.0
$ echo い | iconv -t SJIS | sed -e 's/$/\r/' > cp932.bat
$ git add .
warning: in the working copy of 'cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "2. cp932.batの中身を変更: あ→い"
[master 4dd76e3] 2. cp932.batの中身を変更: あ→い
 1 file changed, 1 insertion(+), 1 deletion(-)
$ echo い > utf8.bash
$ git add .
$ git commit -m "3. utf8.bashの中身を変更: あ→い"
[master 5100ec4] 3. utf8.bashの中身を変更: あ→い
 1 file changed, 1 insertion(+), 1 deletion(-)
$ echo い | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
$ git add .
warning: in the working copy of 'another-cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "4. another-cp932.batを追加: い"
[master 2ce9a17] 4. another-cp932.batを追加: い
 1 file changed, 1 insertion(+)
 create mode 100644 another-cp932.bat
$ git rm cp932.bat
rm 'cp932.bat'
$ git commit -m "5. cp932.batを削除: い"
[master ce6fc82] 5. cp932.batを削除: い
 1 file changed, 1 deletion(-)
 delete mode 100644 cp932.bat
$ echo う | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
$ echo う > utf8.bash
$ git add .
warning: in the working copy of 'another-cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "6. another-cp932.batとutf8.bashの中身を変更: い→う"
[master 98e0997] 6. another-cp932.batとutf8.bashの中身を変更: い→う
 2 files changed, 2 insertions(+), 2 deletions(-)
```

ここで問題に気付いたとする。各コミットの内容を確認すると、CP932の日本語が文字化けしている。

コマンド:

```shell
git log --oneline --graph
for commit in $(git log --format=%H --reverse); do git show $commit; done
```

実行結果:

```console
$ git log --oneline --graph
* 98e0997 (HEAD -> master) 6. another-cp932.batとutf8.bashの中身を変更: い→う
* ce6fc82 5. cp932.batを削除: い
* 2ce9a17 4. another-cp932.batを追加: い
* 5100ec4 3. utf8.bashの中身を変更: あ→い
* 4dd76e3 2. cp932.batの中身を変更: あ→い
* f43f68a (tag: v1.0.0) 1. cp932.batとutf8.bashを追加: あ
$ for commit in $(git log --format=%H --reverse); do git show $commit; done
commit f43f68ad23a5d428a766106cda36506dacdb60bd (tag: v1.0.0)
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:04:52 2024 +0900

    1. cp932.batとutf8.bashを追加: あ

diff --git a/cp932.bat b/cp932.bat
new file mode 100644
index 0000000..0d5dab3
--- /dev/null
+++ b/cp932.bat
@@ -0,0 +1 @@
+<82><A0>
diff --git a/utf8.bash b/utf8.bash
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/utf8.bash
@@ -0,0 +1 @@
+あ
commit 4dd76e334d8af31574656dc3f2d7e25847ccc522
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:15 2024 +0900

    2. cp932.batの中身を変更: あ→い

diff --git a/cp932.bat b/cp932.bat
index 0d5dab3..59d08b3 100644
--- a/cp932.bat
+++ b/cp932.bat
@@ -1 +1 @@
-<82><A0>
+<82><A2>
commit 5100ec4a9ca2aaf574fe211abfc9816d654083e1
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:22 2024 +0900

    3. utf8.bashの中身を変更: あ→い

diff --git a/utf8.bash b/utf8.bash
index f2435a2..c408b52 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-あ
+い
commit 2ce9a170ff4456f4edbf1e8c7edfef5be7e1cf80
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:28 2024 +0900

    4. another-cp932.batを追加: い

diff --git a/another-cp932.bat b/another-cp932.bat
new file mode 100644
index 0000000..59d08b3
--- /dev/null
+++ b/another-cp932.bat
@@ -0,0 +1 @@
+<82><A2>
commit ce6fc82dea50ac8b00a23c97e54e39f13746d94e
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:32 2024 +0900

    5. cp932.batを削除: い

diff --git a/cp932.bat b/cp932.bat
deleted file mode 100644
index 59d08b3..0000000
--- a/cp932.bat
+++ /dev/null
@@ -1 +0,0 @@
-<82><A2>
commit 98e0997f64320e873b08dcd0741f95de67c0517c (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:43 2024 +0900

    6. another-cp932.batとutf8.bashの中身を変更: い→う

diff --git a/another-cp932.bat b/another-cp932.bat
index 59d08b3..c618cb3 100644
--- a/another-cp932.bat
+++ b/another-cp932.bat
@@ -1 +1 @@
-<82><A2>
+<82><A4>
diff --git a/utf8.bash b/utf8.bash
index c408b52..6b89e43 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-い
+う
```

対話的リベースで補正する。

コマンド:

```shell
git switch master
git branch old-master
GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xrenormalize

echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes
git add .

git add . && git commit --amend --no-edit && git rebase --continue
git add . && git commit --amend --no-edit && git rebase --continue
git add . && git commit --amend --no-edit && git rebase --continue
git add . && git commit --amend --no-edit && git rebase --continue
git add . && git commit --amend --no-edit && git rebase --continue
git add . && git commit --amend --no-edit && git rebase --continue

git tag -f v1.0.0 $(git log --format=%H | tail -n 1)
```

実行結果:

```console
$ git switch master
Already on 'master'
$ git branch old-master
$ GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xrenormalize
Stopped at f43f68a...  1. cp932.batとutf8.bashを追加: あ
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes
$ git add .
warning: in the working copy of 'cp932.bat', LF will be replaced by CRLF the next time Git touches it
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD eb40805] 1. cp932.batとutf8.bashを追加: あ
 Date: Sun Nov 10 16:04:52 2024 +0900
 3 files changed, 3 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 cp932.bat
 create mode 100644 utf8.bash
error: failed to encode 'cp932.bat' from UTF-8 to cp932
error: failed to encode 'cp932.bat' from UTF-8 to cp932
Stopped at 4dd76e3...  2. cp932.batの中身を変更: あ→い
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 85a04c5] 2. cp932.batの中身を変更: あ→い
 Date: Sun Nov 10 16:05:15 2024 +0900
 1 file changed, 1 insertion(+), 1 deletion(-)
Stopped at 5100ec4...  3. utf8.bashの中身を変更: あ→い
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 43a8126] 3. utf8.bashの中身を変更: あ→い
 Date: Sun Nov 10 16:05:22 2024 +0900
 1 file changed, 1 insertion(+), 1 deletion(-)
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
Stopped at 2ce9a17...  4. another-cp932.batを追加: い
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 27b1eba] 4. another-cp932.batを追加: い
 Date: Sun Nov 10 16:05:28 2024 +0900
 1 file changed, 1 insertion(+)
 create mode 100644 another-cp932.bat
error: failed to encode 'cp932.bat' from UTF-8 to cp932
Stopped at ce6fc82...  5. cp932.batを削除: い
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 558b22c] 5. cp932.batを削除: い
 Date: Sun Nov 10 16:05:32 2024 +0900
 1 file changed, 1 deletion(-)
 delete mode 100644 cp932.bat
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
Stopped at 98e0997...  6. another-cp932.batとutf8.bashの中身を変更: い→う
You can amend the commit now, with

  git commit --amend

Once you are satisfied with your changes, run

  git rebase --continue
$ git add . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 8ce7329] 6. another-cp932.batとutf8.bashの中身を変更: い→う
 Date: Sun Nov 10 16:05:43 2024 +0900
 2 files changed, 2 insertions(+), 2 deletions(-)
Successfully rebased and updated refs/heads/master.
$ git tag -f v1.0.0 $(git log --format=%H | tail -n 1)
Updated tag 'v1.0.0' (was f43f68a)
```

補正後の結果を確認する。

コマンド:

```shell
git log --oneline --graph
for commit in $(git log --format=%H --reverse); do git show $commit; done
```

実行結果:

```console
$ git log --oneline --graph
* 8ce7329 (HEAD -> master) 6. another-cp932.batとutf8.bashの中身を変更: い→う
* 558b22c 5. cp932.batを削除: い
* 27b1eba 4. another-cp932.batを追加: い
* 43a8126 3. utf8.bashの中身を変更: あ→い
* 85a04c5 2. cp932.batの中身を変更: あ→い
* eb40805 (tag: v1.0.0) 1. cp932.batとutf8.bashを追加: あ
$ for commit in $(git log --format=%H --reverse); do git show $commit; done
commit eb408056cf963a9a445c700ab90ece846525f2b7 (tag: v1.0.0)
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:04:52 2024 +0900

    1. cp932.batとutf8.bashを追加: あ

diff --git a/.gitattributes b/.gitattributes
new file mode 100644
index 0000000..372c0c7
--- /dev/null
+++ b/.gitattributes
@@ -0,0 +1 @@
+*.bat text working-tree-encoding=cp932 eol=crlf
diff --git a/cp932.bat b/cp932.bat
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/cp932.bat
@@ -0,0 +1 @@
+あ
diff --git a/utf8.bash b/utf8.bash
new file mode 100644
index 0000000..f2435a2
--- /dev/null
+++ b/utf8.bash
@@ -0,0 +1 @@
+あ
commit 85a04c5c6ce18de21cabe0f288f6d25280c0b0d6
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:15 2024 +0900

    2. cp932.batの中身を変更: あ→い

diff --git a/cp932.bat b/cp932.bat
index f2435a2..c408b52 100644
--- a/cp932.bat
+++ b/cp932.bat
@@ -1 +1 @@
-あ
+い
commit 43a812621fc644ccf1cc68e6b962fa27cc3d8fc2
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:22 2024 +0900

    3. utf8.bashの中身を変更: あ→い

diff --git a/utf8.bash b/utf8.bash
index f2435a2..c408b52 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-あ
+い
commit 27b1eba5bed6636e1f0466282cd3bd80ea67463f
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:28 2024 +0900

    4. another-cp932.batを追加: い

diff --git a/another-cp932.bat b/another-cp932.bat
new file mode 100644
index 0000000..c408b52
--- /dev/null
+++ b/another-cp932.bat
@@ -0,0 +1 @@
+い
commit 558b22c985fd1a4a10f718ce8247530924b44db2
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:32 2024 +0900

    5. cp932.batを削除: い

diff --git a/cp932.bat b/cp932.bat
deleted file mode 100644
index c408b52..0000000
--- a/cp932.bat
+++ /dev/null
@@ -1 +0,0 @@
-い
commit 8ce7329c5923700fb327df583050c3fe49ff5c10 (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sun Nov 10 16:05:43 2024 +0900

    6. another-cp932.batとutf8.bashの中身を変更: い→う

diff --git a/another-cp932.bat b/another-cp932.bat
index c408b52..6b89e43 100644
--- a/another-cp932.bat
+++ b/another-cp932.bat
@@ -1 +1 @@
-い
+う
diff --git a/utf8.bash b/utf8.bash
index c408b52..6b89e43 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-い
+う
```

※バージョンメモ

- git version 2.43.0

※更新履歴

- 2024-11-02 いろいろ考慮が足りてなかったため全面改稿。
- 2024-11-10 まだいろいろ間違っていたり、不要な手順があったりしたため、再び全面改稿。
