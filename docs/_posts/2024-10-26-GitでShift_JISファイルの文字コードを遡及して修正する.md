---
title: "GitでShift_JISファイルの文字コードを遡及して修正する"
categories: プログラミング
update: 2024-11-02 00:00:00 +0900
---

## .gitattributesでエンコーディングの変換を指示する

テキストファイルのエンコーディングはUTF-8が当たり前となって久しいが、Windowsを使っていると、未だにShift_JISにしなければならないことがある (正確にはCP932、あるいはWindows-31Jにしなければならないと言うべきか)。バッチファイル (bat) や、ExcelのVBAマクロをエクスポートしたファイルなど (bas、cls、fmt) がそれだ。

GitでShift_JISのテキストファイルを管理するとき、何も設定しないと、リポジトリ内部のファイルもShift_JISになってしまう。その状態でもバージョン管理は可能だが、素の`git show`や`git diff`では日本語が16進数表示になってしまう。もちろん、`.gitattributes`でdiffにiconvを噛ませるとか、TortoiseGitにエンコーディングを推測させるなどの手もあるが、やはりリポ内のテキストファイルはすべてUTF-8に統一されている方が扱いやすい。

そこで、自分は`.gitattributes`で特定の拡張子の`working-tree-encoding`をcp932に指定しておくことが多い (正確には拡張子だけでなく`.gitignore`と同じようにパスのパターンを指定できる)。たとえばこのように。

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

問題なのは、最初は`.gitattributes`なしで管理していて、途中で`git show`などの見え方がおかしいことに気づき、`working-tree-encoding=cp932`を追加したようなケースだ。この場合の問題点はいくつかある。

■問題点1: **触っていないファイルまで変更があったと認識される**

`.gitattributes`に`working-tree-encoding=cp932`を書いて保存した瞬間、その拡張子のファイルはすべて「リポ内ではUTF-8**のはず**のファイル」になる。しかし、実際にはリポ内のファイルはまだCP932のままだ。この状態で`git diff`を取ると、「リポ内の、実際はCP932なのにGitがUTF-8だと思い込んでいるファイル」と、「ワーキングディレクトリの、CP932からUTF-8に変換したファイル」の比較が行われるため、当然両者は不一致となる。その結果、実際には触っていなくても、その拡張子の全ファイルがワーキングディレクトリで修正ありとみなされてしまう。

■問題点2: **予期せぬ変更が紛れ込んでいても気付かない**

そして、そのまま「変更あり」と言われた全ファイルをコミットすると、触っていないと思っていたファイルにうっかり別の変更が紛れ込んでいたのに気付かなかった、という事故があり得る。何せ、`git diff`を取っても「全行変わってます」としか言われないのだから。

■問題点3: **過去との比較ができない**

また、このコミットでリポ内のファイルのエンコーディングに断絶が生まれるため、それ以前のコミットとは内容比較ができなくなる。改行コードの違いならオプションでなんとかなるが、エンコーディングの違いは如何ともしがたく、今後は断絶を跨いだ差分は取れなくなる。

■問題点4: **過去のコミット内容は16進数表示のまま**

断絶前のコミットは、リポジトリ内部ではCP932のままなので、相変わらず`git show`や`git diff`で日本語が16進数表示になってしまう。

## 遡及修正する方法

根本的な対処をするなら、あたかも最初から`working-tree-encoding=cp932`を指定していたかのようなふりをして、コミットをやり直す必要がある。その手順を試行錯誤した結果、成功したやり方をここに書いておく。ただし、実際にはもっと良いやり方がある可能性が高い。また、過去の履歴の改変になるので、**ほかの人が触っているブランチにpushする場合は慎重にやる**必要がある。いったん別のブランチで修正して一定期間後に正規のブランチと差し替えるとか、全員に履歴の改変があったことを周知徹底するとかの考慮が必要だろう。

遡及修正のコンセプトは、(特に驚きはないと思うが) `git rebase -i`を使って**最初のコミット**に`.gitattributes`を追加することだ。

### 手順の概略

遡及修正の大まかな手順は次の通り。

1. 修正対象のブランチをチェックアウトする  
   例: `git switch master`

1. ブランチをバックアップする  
   例: `git branch old-master`

1. 最初のコミットから、`-Xtheirs`と`-Xrenormalize`を付けて対話的リベースする  
   例: `git rebase -i --root -Xtheirs -Xrenormalize`

1. 最初から最後までの全コミットで停止して編集すると宣言する  
   例: `:%s/^pick/edit/` (viの場合)

1. 最初のコミットに`.gitattributes`を追加し、拡張子ごとのエンコーディング変換の設定を書く  
   例: `echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes`

1. `.gitattributes`を`git add`する  
   例: `git add .`

1. `--renormalize`オプションを付けて、全ファイルを`git add`する  
   例: `git add --renormalize .`

1. 修正コミットする  
   例: `git commit --amend --no-edit`

1. `git show`で差分を確認し、問題があれば補正して修正コミットする  
   例: `git show`

1. 次のコミットに移る  
   例: `git rebase --continue`

1. 最後のコミットに到達するまで上の4つを繰り返す

1. 元のブランチのコミットを指していたタグを調べ、手動で新コミットに向けなおす  
   例: `git tag -f v1.0.0 f2435a2`

以下、いくつかポイントを説明する。

### ブランチをバックアップする

遡及修正がうまくいったように見えても、作業中には気付かなかった問題が残っているかもしれない。元はどうなってたんだっけ、とか、改めてイチから遡及修正しなおそう、ということが必ずあるので、修正前の履歴 (コミット) もずっと残しておくのが安全だ。

ブランチをバックアップするといっても、Gitのブランチは特定のコミットを指すポインタに過ぎないので、手順としては`git branch 新ブランチ名 元のブランチ名`で新たにポインタを作るだけだ。

### 最初のコミットからリベースする

`git rebase`の引数には、リベースを始めるコミット**の親**を指定する必要がある。今回はいちばん最初のコミットから修正したいので、その親を指定したいが、何せいちばん最初のコミットなので親がいない。そういうときは、`--root`を付けると「ほんとに最初の何もないところから始める」を指定したことになる。

### -Xtheirsをつけてリベースする

リベース中の各コミットでは、CP932のファイルがあると、基本的にすべてコンフリクトが発生する。なぜなら、

- リポ内ではひとつ前のコミットのファイルがすでにUTF-8に置き換わっているので、「前はUTF-8だったファイルを、このコミットでCP932に変えた」という変更が加わっているように見える
- ワーキングディレクトリにあるのは「チェックアウト時に (実際はCP932のままなのに) UTF-8だと思ってCP932に変換しようとしてエラーになり、仕方なくバイナリファイルがそのまま (つまりCP932のまま) チェックアウトされた」もので、コミット時にはそれがUTF-8に変換されるので、「前はCP932だったファイルを、このコミットでUTF-8に変えた」という変更が加わっているように見える

ということで、要はお互いが逆方向の変換をしようとしていると解釈され、コンフリクトが発生するのだ。その結果Gitは、リベースの相手版と自分版を両方取り込んでコンフリクトマーカーをつけたファイルを生成する。なので、そのままではいちいち手動で各ファイルを開いてコンフリクトを解消する必要が出てくる。

`git rebase`に`-Xtheirs`を付けておくと、自動的に自分版を採用したファイルを作ってくれるので、すでにコンフリクトは解消した状態となり、大幅に手間が省ける。なお、「自分版なら-Xtheirsじゃなくて-Xoursじゃないの?」と思われた方は大変マトモな感性をお持ちだが、リベースは内部的にはいったんリベース相手のブランチにスイッチするような動きをするので、マージのときとはtheirsとoursが逆になる。よってここは「-Xours」ではなく「-Xtheirs」を指定する。

### -Xrenormalizeを付けてリベースする

CP932のファイルを削除したコミットがある場合、リベースで「CONFLICT (modify/delete)」が発生し、そのコミットをリプレイするのに失敗する。つまり、そのコミットは未実施の状態になる。さらに、削除したはずのファイルはワーキングディレクトリに残ったままになる。

そのため、削除したはずのファイルを手動で削除したうえで、`--amend`を付けない`git commit`をして、コミットメッセージも入力しなおす必要がある。

また、異常に気付かず全体を`git add`して`git commit --amend --no-edit`してしまうと、**本来のコミットがひとつ前のコミットに統合されてしまい**、かつ**削除したはずのファイルが残ったままになる**。

`git rebase`に`-Xrenormalize`を付けておくと、CP932のファイルを削除したコミットでもリプレイが失敗することが無くなる。なぜ、CP932のファイルを削除したコミットで「CONFLICT (modify/delete)」が発生し、なぜ`-Xrenormalize`を付けるとそれが回避できるのかは、理由を調べ切れていない。すまぬ。

### 全コミットで停止して編集する

当初は、`.gitattributes`を追加する最初のコミットだけ`edit`にして、ほかは`pick`のままでよいだろうと思っていた。そのままでもどうせCP932ファイルの変換エラーで停止するし、と。

しかし実際には、たまたまCP932のファイルをいじっていないコミットが存在すると、そのコミットではエラーもコンフリクトも発生しないのでリベースは止まらない。また、変更のなかったCP932のファイルはリポ内でもCP932のままになる。よって、あとから履歴を見ると、そのコミットだけ一時的にファイルがCP932に戻っているように見える。

安全のためには、全コミットで`--normalize`を付けた`git add .` (後述) をするのが良いと思う。また、修正コミットしたあとは毎回`git show`で問題ないか確認するのが良い。そのためには、結局全コミットを`edit`にして停止させる必要がある。

なお、`git rebase -i`するときに、環境変数`GIT_SEQUENCE_EDITOR`に`sed -i s/^pick/edit/`を設定しておくと、edit todoファイルの編集時のエディタとしてsedが使われるので、手動で編集する必要がなくなる。

ここまでを総合すると、結局リベースコマンドはこうするのが早そうだ。

```shell
GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xtheirs -Xrenormalize
```

### --renormalizeオプションを付けて、全ファイルをgit addする

`git add`するときに`--renormalize`を付けると、ワーキングディレクトリのファイルを`.attributes`の設定に従って仮想的にコミットし、もういちどチェックアウトしなおしたような状態になる。よって、問答無用で`git add --renormalize .`すれば、修正のなかったCP932ファイルもコミット対象となる。

### --no-editをつけて修正コミットする

基本的に、この遡及修正ではファイルのエンコーディング (と場合によっては改行コード) を変換したいだけで、変更内容やコミットメッセージを変えたいわけではない。`git commit --amend`に`--no-edit`を付けると、元のコミットメッセージがそのまま採用されるので、メッセージの編集画面を開いて閉じる手間が省ける。もしコミットメッセージを意図的に変えたいのなら、もちろん`--no-edit`を付けなくてもよい。

### git showで差分を確認し、問題があれば補正して修正コミットする

この記事の初版ではもっと簡単な手順で行けると踏んでいたのだが、実践してみると、あちこちで結果が想定どおりになっていなかった。その後判明した注意ポイントは可能な限り上に書いたのだが、それでもまだ想定外の事象は発生するだろうと思う。それに、例えば特定期間のコミットにだけ特殊な拡張子でCP932ファイルが存在する場合などは、適宜`.attributes`の中身を増やしたり減らしたりしたい場合もある。

それを考えると、結果的には全コミットでリベースを止めて、`git add --renormalize . && git commit --amend --no-edit`した後は、必ず`git show`で想定通りになっているか確認し、もし想定外のことがあれば補正してもう一度`git commit --amend --no-edit`し、完全に満足するまでそれを繰り返すのがむしろ時間の節約になりそうだ。

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
[master (root-commit) fc911da] 1. cp932.batとutf8.bashを追加: あ
 2 files changed, 2 insertions(+)
 create mode 100644 cp932.bat
 create mode 100644 utf8.bash
$ git tag v1.0.0
$ echo い | iconv -t SJIS | sed -e 's/$/\r/' > cp932.bat
$ git add .
warning: in the working copy of 'cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "2. cp932.batの中身を変更: あ→い"
[master 4145362] 2. cp932.batの中身を変更: あ→い
 1 file changed, 1 insertion(+), 1 deletion(-)
$ echo い > utf8.bash
$ git add .
$ git commit -m "3. utf8.bashの中身を変更: あ→い"
[master 0795f75] 3. utf8.bashの中身を変更: あ→い
 1 file changed, 1 insertion(+), 1 deletion(-)
$ echo い | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
$ git add .
warning: in the working copy of 'another-cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "4. another-cp932.batを追加: い"
[master bcac287] 4. another-cp932.batを追加: い
 1 file changed, 1 insertion(+)
 create mode 100644 another-cp932.bat
$ git rm cp932.bat
rm 'cp932.bat'
$ git commit -m "5. cp932.batを削除: い"
[master 90276d0] 5. cp932.batを削除: い
 1 file changed, 1 deletion(-)
 delete mode 100644 cp932.bat
$ echo う | iconv -t SJIS | sed -e 's/$/\r/' > another-cp932.bat
$ echo う > utf8.bash
$ git add .
warning: in the working copy of 'another-cp932.bat', CRLF will be replaced by LF the next time Git touches it
$ git commit -m "6. another-cp932.batとutf8.bashの中身を変更: い→う"
[master 5f4f362] 6. another-cp932.batとutf8.bashの中身を変更: い→う
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
* 5f4f362 (HEAD -> master) 6. another-cp932.batとutf8.bashの中身を変更: い→う
* 90276d0 5. cp932.batを削除: い
* bcac287 4. another-cp932.batを追加: い
* 0795f75 3. utf8.bashの中身を変更: あ→い
* 4145362 2. cp932.batの中身を変更: あ→い
* fc911da (tag: v1.0.0) 1. cp932.batとutf8.bashを追加: あ
$ for commit in $(git log --format=%H --reverse); do git show $commit; done
commit fc911da96d857cba6d540d9d199fd80680fe19be (tag: v1.0.0)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:23:48 2024 +0900

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
commit 414536297bb39690cacade7cd3a87ba6b33f7708
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:24:45 2024 +0900

    2. cp932.batの中身を変更: あ→い

diff --git a/cp932.bat b/cp932.bat
index 0d5dab3..59d08b3 100644
--- a/cp932.bat
+++ b/cp932.bat
@@ -1 +1 @@
-<82><A0>
+<82><A2>
commit 0795f75b3390dcf70323b3c7d12570c54145169f
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:24:52 2024 +0900

    3. utf8.bashの中身を変更: あ→い

diff --git a/utf8.bash b/utf8.bash
index f2435a2..c408b52 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-あ
+い
commit bcac2873de54dc79d2a6d6960b1a8c60f8893e60
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:02 2024 +0900

    4. another-cp932.batを追加: い

diff --git a/another-cp932.bat b/another-cp932.bat
new file mode 100644
index 0000000..59d08b3
--- /dev/null
+++ b/another-cp932.bat
@@ -0,0 +1 @@
+<82><A2>
commit 90276d0955f84c7f62bba48adff335a370211948
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:07 2024 +0900

    5. cp932.batを削除: い

diff --git a/cp932.bat b/cp932.bat
deleted file mode 100644
index 59d08b3..0000000
--- a/cp932.bat
+++ /dev/null
@@ -1 +0,0 @@
-<82><A2>
commit 5f4f3621acc88df94ec19fe663f41217b3607220 (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:23 2024 +0900

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
GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xtheirs -Xrenormalize

echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes
git add .

git add --renormalize . && git commit --amend --no-edit && git rebase --continue
git add --renormalize . && git commit --amend --no-edit && git rebase --continue
git add --renormalize . && git commit --amend --no-edit && git rebase --continue
git add --renormalize . && git commit --amend --no-edit && git rebase --continue
git add --renormalize . && git commit --amend --no-edit && git rebase --continue
git add --renormalize . && git commit --amend --no-edit && git rebase --continue

git tag -f v1.0.0 $(git log --format=%H | tail -n 1)
```

実行結果:

```console
$ git switch master
Already on 'master'
$ git branch old-master
$ GIT_SEQUENCE_EDITOR="sed -i s/^pick/edit/" git rebase -i --root -Xtheirs -Xrenormalize
Stopped at fc911da...  1. cp932.batとutf8.bashを追加: あ
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ echo '*.bat text working-tree-encoding=cp932 eol=crlf' > .gitattributes
$ git add .
warning: in the working copy of 'cp932.bat', LF will be replaced by CRLF the next time Git touches it
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 46f8334] 1. cp932.batとutf8.bashを追加: あ
 Date: Sat Nov 2 09:23:48 2024 +0900
 3 files changed, 3 insertions(+)
 create mode 100644 .gitattributes
 create mode 100644 cp932.bat
 create mode 100644 utf8.bash
error: failed to encode 'cp932.bat' from UTF-8 to cp932
error: failed to encode 'cp932.bat' from UTF-8 to cp932
Stopped at 4145362...  2. cp932.batの中身を変更: あ→い
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 085249e] 2. cp932.batの中身を変更: あ→い
 Date: Sat Nov 2 09:24:45 2024 +0900
 1 file changed, 1 insertion(+), 1 deletion(-)
Stopped at 0795f75...  3. utf8.bashの中身を変更: あ→い
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 6f8806b] 3. utf8.bashの中身を変更: あ→い
 Date: Sat Nov 2 09:24:52 2024 +0900
 1 file changed, 1 insertion(+), 1 deletion(-)
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
Stopped at bcac287...  4. another-cp932.batを追加: い
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 72c4a5a] 4. another-cp932.batを追加: い
 Date: Sat Nov 2 09:25:02 2024 +0900
 1 file changed, 1 insertion(+)
 create mode 100644 another-cp932.bat
error: failed to encode 'cp932.bat' from UTF-8 to cp932
Stopped at 90276d0...  5. cp932.batを削除: い
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD 93ac467] 5. cp932.batを削除: い
 Date: Sat Nov 2 09:25:07 2024 +0900
 1 file changed, 1 deletion(-)
 delete mode 100644 cp932.bat
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
error: failed to encode 'another-cp932.bat' from UTF-8 to cp932
Stopped at 5f4f362...  6. another-cp932.batとutf8.bashの中身を変更: い→う
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git add --renormalize . && git commit --amend --no-edit && git rebase --continue
[detached HEAD dc0db16] 6. another-cp932.batとutf8.bashの中身を変更: い→う
 Date: Sat Nov 2 09:25:23 2024 +0900
 2 files changed, 2 insertions(+), 2 deletions(-)
Successfully rebased and updated refs/heads/master.
$ git tag -f v1.0.0 $(git log --format=%H | tail -n 1)
Updated tag 'v1.0.0' (was fc911da)
$ 
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
* dc0db16 (HEAD -> master) 6. another-cp932.batとutf8.bashの中身を変更: い→う
* 93ac467 5. cp932.batを削除: い
* 72c4a5a 4. another-cp932.batを追加: い
* 6f8806b 3. utf8.bashの中身を変更: あ→い
* 085249e 2. cp932.batの中身を変更: あ→い
* 46f8334 (tag: v1.0.0) 1. cp932.batとutf8.bashを追加: あ
$ for commit in $(git log --format=%H --reverse); do git show $commit; done
commit 46f8334debc85deb1f6a54351c798c3ab5440d3b (tag: v1.0.0)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:23:48 2024 +0900

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
commit 085249ef452dff4af000231e2a6f3cb815d5ab59
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:24:45 2024 +0900

    2. cp932.batの中身を変更: あ→い

diff --git a/cp932.bat b/cp932.bat
index f2435a2..c408b52 100644
--- a/cp932.bat
+++ b/cp932.bat
@@ -1 +1 @@
-あ
+い
commit 6f8806befe4fa9ac027a996a473249037117c1dc
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:24:52 2024 +0900

    3. utf8.bashの中身を変更: あ→い

diff --git a/utf8.bash b/utf8.bash
index f2435a2..c408b52 100644
--- a/utf8.bash
+++ b/utf8.bash
@@ -1 +1 @@
-あ
+い
commit 72c4a5a71670a5810f2c5f2b6e4b75dfd9fbcfe2
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:02 2024 +0900

    4. another-cp932.batを追加: い

diff --git a/another-cp932.bat b/another-cp932.bat
new file mode 100644
index 0000000..c408b52
--- /dev/null
+++ b/another-cp932.bat
@@ -0,0 +1 @@
+い
commit 93ac46748f0a0018061896f668df5562fe46bea2
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:07 2024 +0900

    5. cp932.batを削除: い

diff --git a/cp932.bat b/cp932.bat
deleted file mode 100644
index c408b52..0000000
--- a/cp932.bat
+++ /dev/null
@@ -1 +0,0 @@
-い
commit dc0db16f8a3c2970815ef41c062b0a373c8396e2 (HEAD -> master)
Author: alpha3166 <alpha3166@example.com>
Date:   Sat Nov 2 09:25:23 2024 +0900

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
