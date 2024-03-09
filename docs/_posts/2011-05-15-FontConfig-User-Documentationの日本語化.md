---
title: "FontConfig User Documentationの日本語化"
categories: パソコン
update: 2024-02-17 00:00:00 +0900
---

FontConfigのドキュメント [FontConfig User Documentation](https://www.freedesktop.org/software/fontconfig/fontconfig-user.html) (man fonts-confで表示されるのと同じもの) を読むついでに日本語化してみました。かなーり適当に訳しているので、日本語化した内容については一切保証しません。

---

# fonts-conf

## 名前(Name)

fonts.conf&nbsp;--&nbsp;フォント設定ファイル

## 書式(Synopsis)

```plaintext
/etc/fonts/fonts.conf
/etc/fonts/fonts.dtd
/etc/fonts/conf.d
~/.fonts.conf.d
~/.fonts.conf
```

## 解説(Description)

fontconfigは、システム全体のフォントの設定、カスタマイズ、アプリケーションからのアクセスを行うためのライブラリである。

## 機能概要(Functional Overview)

fontconfigは、大きく設定モジュールとマッチングモジュールの2つからなる。設定モジュールは、XMLファイルを読み込んで内部にフォント設定情報を構築する。マッチングモジュールは、フォントパターンを受け取って、それに一番近いフォントを選んで返す。

### フォント設定(Font Configuration)

設定モジュールは、FcConfigというデータ型とlibexpat、およびFcConfigParseで構成され、設定を格納したXMLツリーから情報を読み取ったり、XMLツリーの情報を書き換えたりする。外からの観点では、妥当な(valid)XMLツリーを生成し、FcConfigParseに渡すことが設定モジュールの役割である。一度できあがった設定をアプリケーションが変更できるのは、アプリケーションが提供したフォントファイルのリストにフォントあるいはディレクトリを追加することだけである。

これは、フォント設定をなるべく一定に保ち、できるだけ多くのアプリケーションに共有してもらうためである。これにより、あるアプリケーションから別のアプリケーションにフォントの名前を渡したときでも、フォントの選択結果がほとんど同じになることが期待される。設定ファイルのフォーマットにXMLを使用しているのは、外部プログラムが編集する場合でも正しい構造と文法を保つのが容易だからである。

フォントの設定とフォントのマッチングは別物である。自分で適切なフォントを選びたいアプリケーションは、自分でフォントマッチングを実施することで、ライブラリ内の必要なフォントにアクセスできる。この柔軟性により、このライブラリを使うか独自フォント設定を作るかの二択に陥ることなく、このライブラリの中の必要な機能だけをアプリケーションが選んで使うことができる。フォントの設定は一箇所に集めておき、全てのアプリケーションがそれを使うのが望ましい。フォント設定の集中管理によって、フォントのインストールやカスタマイズが一元化され、単純化できるからである。

### フォント属性(Font Properties)

フォントパターンは基本的にどんな属性を含んでも構わないが、一般的によく使われる属性が決まっており、またその値の型も決まっている。fontconfigは、これらの属性のいくつかをフォントマッチングとフォントコンプリーションに使う。アプリケーションがフォントをレンダリングするときに役立つ属性もある。

属性|型|説明
-|-|-
family|String|フォントファミリーの名前
familylang|String|各ファミリーに対応する言語
style|String|フォントスタイル。weightとslantを上書きする
stylelang|String|各スタイルに対応する言語
fullname|String|フォントのフルネーム (スタイルを含むことが多い)
fullnamelang|String|フルネームに対応する言語
slant|Int|italic、oblique、romanのいずれか
weight|Int|light、medium、demibold、bold、blackのいずれか
size|Double|ポイントサイズ
width|Int|Condensed、normal、expandedのいずれか
aspect|Double|ヒンティング前にグリフを水平に引き伸ばす
pixelsize|Double|ピクセルサイズ
spacing|Int|proportional、dual-width、monospace、charcellのいずれか
foundry|String|フォント製造元の名前
antialias|Bool|グリフをアンチエイリアスできるかどうか
hinting|Bool|ラスタライザがヒンティングを使うかどうか
hintstyle|Int|自動ヒンティングのスタイル
verticallayout|Bool|垂直レイアウトを使うかどうか
autohint|Bool|普通のヒンタではなく自動ヒンタを使うかどうか
globaladvance|Bool|グローバルアドバンスを使うかどうか
file|String|フォントファイル名
index|Int|フォントのファイル内のインデックス
ftface|FT_Face|指定されたFreeTypeフェースオブジェクトを使うかどうか
rasterizer|String|使用されているラスタライザ
outline|Bool|グリフがアウトラインかどうか
scalable|Bool|グリフが伸縮可能かどうか
scale|Double|ポイントからピクセルへのスケール変換係数
dpi|Double|ターゲットとする1インチあたりのドット数
rgba|Int|unknown、rgb、bgr、vrgb、vbgr、noneのいずれか - サブピクセルの配置
lcdfilter|Int|LCDフィルタのタイプ
minspace|Bool|行間からリーディングを削除するかどうか
charset|CharSet|フォントがエンコードしているUnicodeの文字
lang|String|フォントがサポートする言語のRFC-3066形式のリスト
fontversion|Int|フォントのバージョン番号
capability|String|フォントのレイアウト能力のリスト
embolden|Bool|ラスタライザがボールド体を合成するかどうか

### フォントマッチング(Font Matching)

fontconfigは、与えられたパターンと、システムが利用可能なすべてのフォントとの距離を計算し、マッチングを行う。距離がいちばん小さいフォントが選択される。これにより、常になんらかのフォントが返ることが保証されるが、与えたパターンとは似通わないフォントが返るおそれもある。

フォントマッチングは、アプリケーションが構築したパターンから開始する。パターンには、最終的なフォントに求められる属性を全て含めておく。パターンの各属性には、1つ以上の値を含められる。値は優先順位に沿って並べる。リストの後の方よりも、頭の方でマッチした値の方が、より距離が近いと判定される。

最初にアプリケーションから渡されたパターンは、設定の中でパターンごとに指定された編集指示(editing instructions)を適用することで、変化していく。各編集指示は、適用条件(match predicate)と編集操作(editing operations)からなる。編集指示は、設定内での出現順に適用されていく。適用条件があてはまると、それに対応づけられた編集操作が適用されていく。

パターンが編集されたあと、一連のデフォルト値置換が実施されることで、属性が正規化される。これにより、レンダリング時に下位レイヤが各種属性のデフォルト値を意識する必要が無くなる。

最後に、正規化されたフォントパターンは、利用可能な全フォントとマッチングされる。パターンとフォントの距離は、次の属性を用いて計算される: foundry、charset、family、lang、spacing、pixelsize、style、slant、weight、antialias、rasterizer、outline。マッチングはこの優先順位で行われるので、リストの最初の方の属性の方が、後の方の属性より重みが大きい。

マッチング計算の中で、ファミリー名だけは特別扱いされ、強いファミリー名と弱いファミリー名に分割される。強いファミリー名はlangより高い優先順位を与えられ、弱いファミリー名はlangより低い優先順位を与えられる。これにより、ドキュメントが指定したフォントがどれも利用できない場合でも、ドキュメントの言語でフォントを選択できるようになる。

選択されたフォントを表すパターンは、パターンにはあるがフォント自体にはない属性を含むよう拡張される。これによりアプリケーションは、マッチングシステムを通してレンダリングに必要な指示やその他のデータを渡すことができるようになる。(訳注: このあたり、私には原文の意味がよく分かりません……) 最後に、設定内のフォント用の編集指示が、パターンに適用される。こうして手を加えられたパターンが、アプリケーションに返される。

戻り値には、フォイル名やピクセルサイズ、その他のレンダリングデータなど、フォントの場所を特定してラスタライズするのに十分な情報が含まれている。いずれの情報もFreeTypeライブラリからは独立しているので、アプリケーションは好きなラスタライズエンジンを使うことができるし、必要であればフォントファイルを直接読み込むことさえできる。

ここで述べたマッチングおよびパターン編集の一連の手順は、2パスで実行される。なぜなら、本質的に2種類の異なる処理が必要だからである。1つめは、ファミリー名の別名処理や、属性に適切なデフォルト値を補う処理など、フォントの選択方法を決める処理である。2つめは、選んだフォントをどうラスタライズするかを決める処理である。2つめの処理は、オリジナルのパターンではなく、選択されたフォントに適用しなければならない(意図しないマッチングもよく起こるため)。

### フォント名(Font Names)

fontconfigでは、ライブラリが解釈したり生成したりするフォントのパターンを、テキストで表現する。このテキスト表現は、ファミリー名のリスト、ポイントサイズのリスト、追加的属性のリストの3つから構成される。

```plaintext
<ファミリー名>-<ポイントサイズ>:<属性1>=<値1>:<属性2>=<値s2>...
```

属性の値がリストの場合は、カンマで区切る。ファミリー名とポイントサイズは省略もできる。さらに、属性の名前と値をいっぺんに指定する定数も存在する。いくつか例を挙げる。

フォント名|意味
-|-
Times-12|12ポイントのTimes Roman
Times-12:bold|12ポイントのTimes Bold
Courier:italic|ItalicでデフォルトサイズのCourier
Monospace:matrix=1 .1 0 1|計算でObliqueにしたMonospace

ファミリー名に'\\'、'-'、':'、','が含まれる場合は、区切り文字と解釈されるのを防ぐため、文字の前に'\\'を付加しなければならない。同様に、属性値が'\\'、'='、'_'、':'、','を含む場合は、文字の前に'\\'を付加しなければならない。付加した'\\'は、フォント名が解釈される際に除去される。

## アプリケーションのデバッグ(Debugging Applications)

フォントとアプリケーションの問題を診断するため、fontconfigにはデバッグ機能がたくさん埋めこまれている。環境変数FC_DEBUGでデバッグ機能を制御する。環境変数の値は数値として解釈され、各ビットが別々のデバッグ用メッセージを制御する。

名前|値|意味
-|-:|-
MATCH|1|フォントマッチングの簡潔な情報
MATCHV|2|フォントマッチングの完全な情報
EDIT|4|match/test/editの実行情報
FONTSET|8|起動時のフォント情報の読み込み情報
CACHE|16|キャッシュファイルの書き込み情報
CACHEV|32|キャッシュファイルの書き込みの完全な情報
PARSE|64|(廃止)
SCAN|128|キャッシュ構築のためのフォントファイルスキャン情報
SCANV|256|フォントファイルスキャンの冗長情報
MEMORY|512|fontconfigのメモリ使用状況
CONFIG|1024|どの設定ファイルが読み込まれたかの情報
LANGSET|2048|lang値の構築に用いられたcharsetのダンプ
OBJTYPES|4096|型チェックが失敗したときのメッセージ

アプリケーションを実行する前に、必要なデバッグレベルの値をすべて足し合わせ、FC_DEBUG環境変数に(10進数の値で)割り当てること。結果はstdoutに送られる。

## 言語タグ(Lang Tags)

データベース内の各フォントは、サポートする言語のリストを持っている。これは、各フォントがカバーするUnicodeの範囲と、各言語が使用する文字を比較して算出する。言語は、RFC-3066の命名法でタグ付けされる。この方式では、ISO 639の言語コードの後にハイフンが続き、その後にISO 3166の国コードが来る。ハイフンと国コードは省略される場合もある。

各言語が使用する文字は、fontconfigライブラリ内に組み込まれているため、新しい言語を追加する場合はライブラリの最ビルドが必要となる。現状ではISO 639-1の139言語のうち122言語と、ISO 639-2の2文字コードのうち141言語、および3文字コードのみをもつ30言語をサポートしている。(訳注: ISO 639-2は3文字コードの規格では?) 2文字と3文字の両方のコードがある言語では、2文字コードのみで表現している。

複数の地域で全く異なる文字集合を使用している言語では、地域ごとに別の扱いとしている。このようなケースとしては、アゼルバイジャン語、クルド語、パシュトー語、ティグリニャ語、中国語がある。

## 設定ファイルフォーマット(Configuration File Format)

fontconfigの設定ファイルはXML形式で記述する。このフォーマットにより、外部の設定ツールが文法的に正しい設定ファイルを容易に生成し、書き出すことができる。またXMLファイルはプレーンテキストなので、エキスパートユーザがテキストエディタで編集するのも簡単である。

fontconfigの文書型定義(document type definition)は、外部エンティティ"fonts.dtd"に記載しており、通常はデフォルトのフォント設定ディレクトリ(/etc/fonts)に格納されている。各設定ファイルは下記のとおりの構成となる。

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
...
</fontconfig>
```

### `<fontconfig>`

フォント設定ファイルの最上位レベル要素。この要素の中に`<dir>`、`<cache>`、`<include>`、`<match>`、`<alias>`要素を任意の順序で書く。(訳注: fonts.dtdによると、他に`<cachedir>`、`<config>`、`<selectfont>`も書ける)

### `<dir>`

この要素には、利用可能なフォントのセットに含めるフォントファイルをスキャンするディレクトリ名を書く。

### `<cache>`

この要素には、ユーザごとにフォント情報をキャッシュするファイル名を書く。ファイル名が'~'で始まる場合は、ユーザのホームディレクトリにあるファイルであることを示す。このファイルは、ディレクトリごとのキャッシュファイルには無いフォントの情報を格納するのに使用される。fontconfigライブラリが自動的にメンテナンスする。デフォルトは"~/.fonts.cache-`<バージョン>`"で、`<バージョン>`にはフォント設定ファイルのバージョン番号が入る(現在は2)。

### `<include ignore_missing="no">`

この要素では、追加の設定ファイルまたはディレクトリの名前を指定する。ディレクトリを指定した場合は、ディレクトリ内のASCIIの数字(U+0030〜U+0039)で始まり".conf"で終わる全てのファイルをソート順に処理する。FcConfigParseがXMLデータ型をトラバースする際、ファイル名をFcConfigLoadAndParseに渡すことにより、ファイルの中身が設定に組み込まれる。'ignore_missing'をデフォルトの"no"ではなく"yes"にした場合、ファイルまたはディレクトリが存在しなくてもライブラリのワーニングメッセージは表示されない。

### `<config>`

この要素には、追加の設定情報を書く。`<config>`内に`<blank>`と`<rescan>`要素を任意の順序で書く。

### `<blank>`

フォントには、エンコーディング上は存在するが画面表示するとブランクになる"壊れた"グリフが含まれることが多い。`<blank>`要素には、本来ブランクである各Unicode文字を`<int>`要素で指定する。このセットで指定しなかった文字がブランクであった場合、フォントがサポートする文字集合から削除される。

### `<rescan>`

`<rescan>`要素には、フォント設定の変更を自動的にチェックする間隔のデフォルト値を`<int>`要素で指定する。fontconfigは、ここで指定した間隔で、全ての設定ファイル、設定ディレクトリを検証し、内部のデータ構造を自動的に再構築する。

### `<selectfont>`

この要素では、一覧表示あるいはマッチングの対象とするフォントのブラックリストとホワイトリストを指定する。この要素内には、acceptfontとrejectfont要素を書く。

### `<acceptfont>`

この要素で指定したフォントは、"ホワイトリスト"として扱われる。ここで指定したフォントは、明示的に一覧表示およびマッチング要求の対象フォントセットに加えられる。rejectfont要素での"ブラックリスト"指定よりも優先される。acceptfont要素は対象フォントを指定するglobおよびpattern要素から成る。

### `<rejectfont>`

rejectfont要素で指定したフォントは、"ブラックリスト"として扱われる。ここで指定したフォントは、一覧表示およびマッチング要求の対象フォントセットから除外され、あたかも存在しないかのように扱われる。rejectfont要素は対象フォントを指定するglobおよびpattern要素から成る。

### `<glob>`

glob要素には、シェルスタイルのファイル名マッチングパターン(?と*を含む)を指定し、フルパスで対象フォントを特定する。複数ディレクトリを指定することもできるし(/usr/share/fonts/uglyfont\*)、特定のフォントファイルタイプを指定することもできる(\*.pcf.gz)が、後者の指定方法はファイル名のつけ方に強く依存しており、信頼性に欠ける。globはディレクトリのみに適用され、個々のフォントには適用されない点に注意。

### `<pattern>`

pattern要素は、指定されたフォント群に対してリストでのマッチングを行う。すなわち、要素のリストと、対応する値をもつ。もしこれら全ての要素がマッチする値をもっていた場合、パターンはフォントにマッチする。これは、(scalable、boldなどの)フォントの属性に基づくフォントの選択に使用される。これは、ファイルの拡張子を使う方式より信頼できる。patterm要素内にはpatelt要素を書く。

### `<patelt name="property">`

patelt要素には、1つのpatter要素と値のリストを書く。patter要素の名前を指定するname属性は必須。patelt要素内には、int、double、string、matrix、bool、charset、const要素を書く。(訳注: 以上の説明はfonts.dtdと不整合で、誤りと思われる。実際にはnameでフォント属性を指定し、そのフォント属性の値を型に応じてint、double、string、matrix、bool、charset、const要素のいずれか1つだけで指定する)

### `<match target="pattern">`

この要素内には、まず0個以上の`<test>`要素を書き、次に0個以上の`<edit>`要素を書く。すべてのtestに合致したパターンが、全てのeditの対象になる。targetの値を"pattern"(これがデフォルト値)ではなく"font"にすると、`<match>`の内容はマッチング前のパターンにではなく、マッチング結果のフォント名に対して適用される。targetの値を"scan"にすると、fontconfigの内部設定データベースを構築する際のスキャンに適用される。

### `<test qual="any" name="property" target="default" compare="eq">`

この要素には、target('pattern'、'font'、'scan'、'default'のいずれか) (訳注: fonts.dtdによると、実際には'scan'は指定できない) のフォント属性(前述のフォント属性のどれとでも)と比較する値を1つ書く。'compare'には、"eq"、"not_eq"、"less"、"less_eq"、"more"、"more_eq"のいずれかを書く。'qual'には、フォント属性の値のどれかひとつでもtestの条件を満たせばよい場合は"any"を(これがデフォルト)、フォント属性の全ての値がtestの条件を満たさなければならない場合は"all"を指定する。`<match target="font">`要素の中で使われた場合、`<test>`要素のtarget=属性はオリジナルのパターン、あるいはフォントのどちらにも作用する。"default"の場合は、外側の`<match>`要素が選択したターゲットが何であれ、それに対して作用する。(訳注: `<test>`要素は要するにif文。Javaなら`if (KEY.equals(VALUE))`と書くところを、`<test name="KEY" compare="eq"><string>VALUE</string></test>`と書く。)

### `<edit name="property" mode="assign" binding="weak">`

この要素には、式要素(値または演算を表す要素なら何でも)のリストを書く。式要素は実行時に評価され、nameで指定したフォント属性を書き換える。フォント属性が`<test>`要素にマッチしたものであれば、最初にマッチした値を書き換える。フォント属性に挿入する値には、bindingで指定したバインディング("strong"、"weak"、"same")が与えられる。"same"バインディングは、マッチしたパターン要素の値をそのまま使う。'mode'に書ける値は次の通り。

モード|マッチしたとき|マッチしなかったとき
-|-|-
"assign"|マッチした値を置き換える|全ての値を置き換える
"assign_replace"|全ての値を置き換える|全ての値を置き換える
"prepend"|マッチの前に挿入する|リストの先頭に挿入する
"prepend_first"|リストの先頭に挿入する|リストの先頭に挿入する
"append"|マッチの後に追加する|リストの末尾に追加する
"append_last"|リストの末尾に追加する|リストの末尾に追加する

### `<int>`, `<double>`, `<string>`, `<bool>`

これらの要素には、該当する型の値を1つ書く。`<bool>`要素にはtrueかfalseのいずれかを書く。実数型の書き方には重要な制限がある。仮数は小数点ではなく数字ではじめなければならない。したがって、1未満の値でも頭に0をつけること(たとえば、.5ではなく0.5、-.5ではなく-0.5と書く)。

### `<matrix>`

この要素には、アフィン変換に使う4つの`<double>`要素を書く。

### `<name>`

フォント属性の名前を書く。評価されると、フォント属性の最初の値になる。パターンの属性ではない。

### `<const>`

定数の名前を書く。値は常に整数で、フォントに共通の値のシンボル名として機能する。

定数|属性|値
-|-|-
thin|weight|0
extralight|weight|40
ultralight|weight|40
light|weight|50
book|weight|75
regular|weight|80
normal|weight|80
medium|weight|100
demibold|weight|180
semibold|weight|180
bold|weight|200
extrabold|weight|205
black|weight|210
heavy|weight|210
roman|slant|0
italic|slant|100
oblique|slant|110
ultracondensed|width|50
extracondensed|width|63
condensed|width|75
semicondensed|width|87
normal|width|100
semiexpanded|width|113
expanded|width|125
extraexpanded|width|150
ultraexpanded|width|200
proportional|spacing|0
dual|spacing|90
mono|spacing|100
charcell|spacing|110
unknown|rgba|0
rgb|rgba|1
bgr|rgba|2
vrgb|rgba|3
vbgr|rgba|4
none|rgba|5
lcdnone|lcdfilter|0
lcddefault|lcdfilter|1
lcdlight|lcdfilter|2
lcdlegacy|lcdfilter|3
hintnone|hintstyle|0
hintslight|hintstyle|1
hintmedium|hintstyle|2
hintfull|hintstyle|3

### `<or>`, `<and>`, `<plus>`, `<minus>`, `<times>`, `<divide>`

これらの要素は、式要素のリストに対して演算子として働く。`<or>`と`<and>`はbooleanであって、ビット演算子ではない。

### `<eq>`, `<not_eq>`, `<less>`, `<less_eq>`, `<more>`, `<more_eq>`

これらの要素は2つの値を比較し、booleanの結果を返す。

### `<not>`

1つの式要素のboolean値を反転させる。

### `<if>`

この要素内には3つの式要素を書く。最初の値がtrueであれば2番目の値になり、そうでなければ3番目の値になる。

### `<alias>`

alias要素は、1つのフォントファミリーを別のフォントファミリーに置き換えるのに必要とされる共通的な処理の省略記法である。この要素内には、`<family>`要素に続けてオプションで`<prefer>`、`<accept>`、`<default>`要素を書く。`<family>`要素にマッチしたフォントのfamily属性には、`<prefer>`要素に書いたファミリーが`<family>`でマッチした値の前に追加され、`<accept>`要素に書いたファミリーが`<family>`でマッチした値の後に追加され、`<default>`要素に書いたファミリーがfamily属性のリストの最後に追加される。

### `<family>`

フォントファミリー名を1つ書く。

### `<prefer>`, `<accept>`, `<default>`

内部に`<family>`要素を書く。`<alias>`要素内で使われる。

## 設定ファイル例(EXAMPLE CONFIGURATION FILE)

### システム設定ファイル(System configuration file)

システム全体の設定ファイルの例を示す。

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<!-- /etc/fonts/fonts.conf ファイル: システムフォントへのアクセス設定 -->
<fontconfig>
<!-- 
    フォントを探すディレクトリ
-->
<dir>/usr/share/fonts</dir>
<dir>/usr/X11R6/lib/X11/fonts</dir>

<!--
    旧式のaliasである'mono'も処理できるよう'monospace'に置き換える
-->
<match target="pattern">
    <test qual="any" name="family"><string>mono</string></test>
    <edit name="family" mode="assign"><string>monospace</string></edit>
</match>

<!--
    一般的なaliasを含まないフォント名には'sans'を付与する
-->
<match target="pattern">
    <test qual="all" name="family" mode="not_eq">sans</test>
    <test qual="all" name="family" mode="not_eq">serif</test>
    <test qual="all" name="family" mode="not_eq">monospace</test>
    <edit name="family" mode="append_last"><string>sans</string></edit>
</match>

<!--
    ユーザごとのカスタマイズ用ファイルを読み込む。ファイルが存在しなくても警告しない
-->
<include ignore_missing="yes">~/.fonts.conf</include>

<!--
    ローカルのカスタマイズ用ファイルを読み込む。ファイルが存在しなくても警告しない
-->
<include ignore_missing="yes">conf.d</include>
<include ignore_missing="yes">local.conf</include>

<!--
    一般的なフォント名を利用可能なTrueTypeフォントにaliasする
    Type1フェイスを似たようなTrueTypeフェイスに置き換えることで、画面表示を改善する
-->
<alias>
    <family>Times</family>
    <prefer><family>Times New Roman</family></prefer>
    <default><family>serif</family></default>
</alias>
<alias>
    <family>Helvetica</family>
    <prefer><family>Arial</family></prefer>
    <default><family>sans</family></default>
</alias>
<alias>
    <family>Courier</family>
    <prefer><family>Courier New</family></prefer>
    <default><family>monospace</family></default>
</alias>

<!--
    標準的な名前に、必要なaliasを付ける
    ユーザの設定ファイル読み込みの後でこれをすることで、
    ここのaliasを優先させる
-->
<alias>
    <family>serif</family>
    <prefer><family>Times New Roman</family></prefer>
</alias>
<alias>
    <family>sans</family>
    <prefer><family>Arial</family></prefer>
</alias>
<alias>
    <family>monospace</family>
    <prefer><family>Andale Mono</family></prefer>
</alias>
</fontconfig>
```

### ユーザごとの設定ファイル(User configuration file)

~/.fonts.confに置くユーザごとの設定ファイルの例を示す。

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<!-- ~/.fonts.conf: ユーザごとのフォント設定 -->
<fontconfig>

<!--
    プライベートなフォントディレクトリ
-->
<dir>~/.fonts</dir>

<!--
    液晶ディスプレイでのグリフ表示を改善するため、サプピクセルの順序にrgbを使う。
    この設定はレンダリングには影響するが、マッチングには影響しない
    常にtarget="font"を使う。
-->
<match target="font">
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
</match>
</fontconfig>
```

## 関連ファイル(Files)

*fonts.conf*は、fontconfigの設定情報を保持する。フォント情報を探すディレクトリを指定するのに加え、プログラムが指定したフォントパターンを、利用可能フォントとのマッチングの前に編集するための指示を含む。XMLフォーマットで記述する。

*conf.d*は、外部アプリケーションやローカル管理者が管理する追加設定ファイルを置く一般的なディレクトリである。数字で始まるファイル名は辞書順にソートされ、追加設定ファイルとして処理される。すべてXMLフォーマットで記述する。マスターのfonts.confファイルが`<include>`ディレクティブでこのディレクトリを指している。

*fonts.dtd*は、設定ファイルのフォーマットを記述したDTDである。

*~/.fonts.conf.d*は、ユーザごとの(普通は自動生成される)設定ファイルをおく一般的なディレクトリである。実際のディレクトリ名は、グローバルなfonts.confファイルの中で指定されている。

*~/.fonts.conf*は、ユーザごとのフォント設定を置く一般的な場所である。実際の場所は、グローバルなfonts.confファイルの中で指定されている。

*~/.fonts.cache-\**は、ディレクトリごとのキャッシュには見つからないフォント情報の一般的なリポジトリである。このファイルはfontconfigが自動的にメンテナンスする。

## 関連項目(See Also)

fc-cat(1), fc-cache(1), fc-list(1), fc-match(1), fc-query(1)

## バージョン(Version)

Fontconfig バージョン 2.8.0

---

※バージョンメモ

- fontconfig-2.8.0,1

※更新履歴

- 2024-02-17 訳した文書を成形して本文に統合
