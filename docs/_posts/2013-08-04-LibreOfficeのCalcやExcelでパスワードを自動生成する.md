---
title: "LibreOfficeのCalcやExcelでパスワードを自動生成する"
categories: パソコン
---

ランダムなパスワードを大量に自動生成したいことって、たまにありますよね。(え、無いですか? 私はあるんですよ)

それをLibreOfficeのCalcやExcelで簡単にやる方法をメモっておきます。たいした話じゃないんだけど、毎回考えるのも面倒くさいので。

やりたいことは、こんな感じ。

- ランダムなパスワードを、任意の個数作れること。
- 特殊なツールを使わず、表計算の関数だけで実現できること。
- 使う文字種を簡単に指定できること。
- パスワードを好きな桁数にできること。

## やり方

では具体的なやり方を。

まず、一番左上のA1セルに、パスワードに使用可能な文字を羅列します。例えば、アルファベットの大文字・小文字と数字だけにしたい場合は、

    ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789

と入力します。文字の順番はなんでも構いません。

![img](img/20130804-001.png)

次に、任意のセルに、

    =mid($A$1,rand()*len($A$1)+1,1)

という関数を入力します。これで、A1に入力した文字列の中からランダムに1文字を取り出します。

![img](img/20130804-002.png)

このセルを右にコピーして、パスワードの桁数分に増やします。8文字なら8セル分。これで、パスワードが1つ生成できました。

![img](img/20130804-003.png)

パスワードの文字がセルに分かれているのがイヤだという場合は、さらにその右側のセルあたりに、各文字への参照を&でつないだ関数、たとえば

    =A3&B3&C3&D3&E3&F3&G3&H3

を入力すれば、ひとつづきの文字列が得られます。

![img](img/20130804-004.png)

最後に、この行をパスワードの個数分、下方向コピーすれば完成です。

![img](img/20130804-005.png)

F9を押すたびに、パスワードが再生成されます。

## 関数の説明

以下、補足として、A1に入力した文字列の中からランダムに1文字を取り出す関数の組み立て方を少し。

まず、rand関数で0以上1未満の擬似乱数を発生させます。

    =rand()

これに、len関数で数えた文字種の数を掛けると、0以上、文字種の数未満の数値が得られます。上記の例のようにアルファベットの大文字・小文字と数字の計62文字を使う場合は、0.0000～61.9999のどこかの数値になります。

    =rand()*len($A$1)

この数値をインデックスに使って、mid関数でA1の文字列から1文字を取り出すのですが、mid関数の第2引数で指定する開始位置は1始まりなので、1を足しておきます(つまり、1.0000～62.9999のどこかの数値にする)。第3引数の1は「1文字取り出す」という意味です。

    =mid($A$1,rand()*len($A$1)+1,1)

なお、開始位置が整数じゃなくて大丈夫なのかという気もしますが、小数点以下は単純に切り捨てられるようなので、このままで大丈夫です。

乱数の発生には、rand関数の代わりにrandbetween関数を使う方法もあります。こちらは下限と上限を指定できて、しかもその間の「整数」を返してくれるので、より直感的です。

    =mid($A$1,randbetween(1,len($A$1)),1)

ただし、次のような違いがあります。

- LibreOfficeのCalcで関数を再実行するには、F9ではなくCntrl+Shift+F9を押す。
- Excelでrandbetweenを使うには、[分析ツール]アドインの組み込みが必要(らしい)。

※バージョンメモ

- LibreOffice 4.1.0.4
