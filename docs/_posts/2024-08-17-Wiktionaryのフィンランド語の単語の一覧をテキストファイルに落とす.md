---
title: "Wiktionaryのフィンランド語の単語の一覧をテキストファイルに落とす"
categories: ことば パソコン
---

[英語版のWiktionary](https://en.wiktionary.org/)に登録されているフィンランド語の単語を全部リストアップして、プレーンテキストのファイルに落としてみた。これはその手順の備忘録。

## 手順

Wiktionaryの中で、フィンランド語の意味が載っているページは、すべてFinnish lemmasというカテゴリーに属している。[Category:Finnish lemmas](https://en.wiktionary.org/wiki/Category:Finnish_lemmas)を見ると、これを書いている時点(2024年8月16日)で165,592語あるらしい。この一覧と同じ内容をテキストに落としたい。ウェブ画面では1ページに200個ずつしか表示されないので、全部を見るには828ページほど表示させる必要がある。手動ではとても無理なので、機械的にやる方法を考える。

Wiktionaryを含むWikiMediaは、Wikiシステムとして[MediaWiki](https://www.mediawiki.org/wiki/MediaWiki)を使っている。

そのMediaWikiには、[WikiMediaのダンプを月1～2回取って置いているサイト](https://dumps.wikimedia.org/backup-index.html)がある。その中に、英語版Wiktionaryのダンプもある。2024年8月16日時点では[20240801のダンプ](https://dumps.wikimedia.org/enwiktionary/20240801/)が最新のようだ。これをダウンロードして加工する。

名前から推測して、ページのデータは「なんとか-page.sql.gz」に、そのページが属するカテゴリのデータは「なんとか-categorylinks.sql.gz」に入っていそうだ。それぞれ249MBと577MBあって、本家からダウンロードすると遅いので、[ミラーサイトのリスト](https://dumps.wikimedia.org/mirrors.html)のいちばん上にあるAcademic Computer Club, Umeå Universityの<https://mirror.accum.se/mirror/wikimedia.org/>から落としてみた。

```bash
curl --remote-name --location https://mirror.accum.se/mirror/wikimedia.org/dumps/enwiktionary/20240801/enwiktionary-20240801-page.sql.gz
curl --remote-name --location https://mirror.accum.se/mirror/wikimedia.org/dumps/enwiktionary/20240801/enwiktionary-20240801-categorylinks.sql.gz
```

本家のサイトからハッシュ値もダウンロードして、中身が壊れていないか確認する。

```bash
curl --remote-name --location https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-sha1sums.txt
sha1sum --check enwiktionary-latest-sha1sums.txt --ignore-missing
```

問題なさそうなら、gzipを解凍する。

```bash
gzip --decompress --keep *.gz
```

できたファイルは結構大きい。

```console
$ ls -l *.sql
-rw-r--r-- 1 alpha alpha 5900788609 Aug 16 21:35 enwiktionary-20240801-categorylinks.sql
-rw-r--r-- 1 alpha alpha 1065239522 Aug 16 21:32 enwiktionary-20240801-page.sql
```

中身はMariaDBのダンプなので、これをMariaDBに入れる。[DockerHubのMariaDBの公式イメージ](https://hub.docker.com/_/mariadb)を使うことにする。

DBデータはいちおう永続化することにして、ローカルに入れ物のディレクトリを作る。

```bash
mkdir ../finn-db-data
```

Dockerのネットワークを作る。

```bash
docker network create finn
```

そのネットワークにDBサーバを立てる。`/var/lib/mysql`がデータ置き場なので、さっきの`../finn-db-data`をここにマウントする。DBユーザはrootだけで良かろう。

```bash
docker run \
  --detach \
  --network finn \
  --name finn-db \
  --volume $PWD/../finn-db-data:/var/lib/mysql \
  --env MARIADB_ROOT_PASSWORD=finn \
  mariadb
```

SQL実行用の使い捨てコンテナをもうひとつ立てる。その際、sqlファイルの置き場を適当な場所にマウントする。

```bash
docker run -it --network finn --rm -v $PWD:/work -w /work mariadb bash
```

コンテナの中でmariadbコマンドを起動する。

```bash
mariadb --host=finn-db --user=root --password=finn
```

適当な名前のデータベースを作ってつなぐ。

```sql
create database finn;
use finn;
```

sourceでsqlファイルを読み込み、テーブルをリストアする。とあっさり書いているが、数時間はかかるので、しばし待つ。

```sql
source enwiktionary-20240801-page.sql
source enwiktionary-20240801-categorylinks.sql
```

終わるとテーブルが2つできている。

```console
MariaDB [finn]> show tables;
+----------------+
| Tables_in_finn |
+----------------+
| categorylinks  |
| page           |
+----------------+
2 rows in set (0.004 sec)
```

カラムはこんな感じ。

```console
MariaDB [finn]> desc page;
+--------------------+---------------------+------+-----+---------+----------------+
| Field              | Type                | Null | Key | Default | Extra          |
+--------------------+---------------------+------+-----+---------+----------------+
| page_id            | int(8) unsigned     | NO   | PRI | NULL    | auto_increment |
| page_namespace     | int(11)             | NO   | MUL | 0       |                |
| page_title         | varbinary(255)      | NO   |     |         |                |
| page_is_redirect   | tinyint(1) unsigned | NO   | MUL | 0       |                |
| page_is_new        | tinyint(1) unsigned | NO   |     | 0       |                |
| page_random        | double unsigned     | NO   | MUL | 0       |                |
| page_touched       | binary(14)          | NO   |     | NULL    |                |
| page_links_updated | varbinary(14)       | YES  |     | NULL    |                |
| page_latest        | int(8) unsigned     | NO   |     | 0       |                |
| page_len           | int(8) unsigned     | NO   | MUL | 0       |                |
| page_content_model | varbinary(32)       | YES  |     | NULL    |                |
| page_lang          | varbinary(35)       | YES  |     | NULL    |                |
+--------------------+---------------------+------+-----+---------+----------------+
12 rows in set (0.003 sec)

MariaDB [finn]> desc categorylinks;
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
| Field             | Type                         | Null | Key | Default             | Extra                         |
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
| cl_from           | int(8) unsigned              | NO   | PRI | 0                   |                               |
| cl_to             | varbinary(255)               | NO   | PRI |                     |                               |
| cl_sortkey        | varbinary(230)               | NO   |     |                     |                               |
| cl_timestamp      | timestamp                    | NO   |     | current_timestamp() | on update current_timestamp() |
| cl_sortkey_prefix | varbinary(255)               | NO   |     |                     |                               |
| cl_collation      | varbinary(32)                | NO   |     |                     |                               |
| cl_type           | enum('page','subcat','file') | NO   |     | page                |                               |
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
7 rows in set (0.001 sec)
```

レコード数はこんな感じ。

```console
MariaDB [finn]> select count(*) from page;
+----------+
| count(*) |
+----------+
|  9663209 |
+----------+
1 row in set (3.619 sec)

MariaDB [finn]> select count(*) from categorylinks;
+----------+
| count(*) |
+----------+
| 49263384 |
+----------+
1 row in set (54.804 sec)
```

中身のレコードはこんな感じ。`categorylinks`の`cl_sortkey`の値には改行が入っているので、表が崩れて見える。

```sql
MariaDB [finn]> select * from page limit 10;
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
| page_id | page_namespace | page_title                                 | page_is_redirect | page_is_new | page_random        | page_touched   | page_links_updated | page_latest | page_len | page_content_model | page_lang |
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
|       6 |              4 | Welcome,_newcomers                         |                0 |           0 |  0.119036956801114 | 20240731044752 | 20240731045354     |    80638725 |     6460 | wikitext           | NULL      |
|       7 |              4 | GNU_Free_Documentation_License             |                0 |           0 |  0.492815242607906 | 20220827002219 | 20220827002219     |    68763312 |     2776 | wikitext           | NULL      |
|       8 |              4 | Text_of_the_GNU_Free_Documentation_License |                0 |           0 |  0.106965373369833 | 20240720013141 | 20240720014140     |    11480759 |    16898 | wikitext           | NULL      |
|       9 |              2 | Sjc~enwiktionary                           |                0 |           0 | 0.0563811697590921 | 20230310202314 | 20230310202313     |    32611008 |       86 | wikitext           | NULL      |
|      12 |              4 | What_Wiktionary_is_not                     |                0 |           0 |  0.296497345246838 | 20240730234243 | 20240730234808     |    69871386 |    11266 | wikitext           | NULL      |
|      13 |              2 | Eloquence                                  |                1 |           1 |  0.574770801304626 | 20230306071427 | 20230306071426     |      241835 |       30 | wikitext           | NULL      |
|      14 |              2 | Merphant                                   |                0 |           0 |  0.984362001516262 | 20230306071427 | 20230306071426     |      241836 |       61 | wikitext           | NULL      |
|      15 |              3 | Merphant                                   |                0 |           0 |  0.197497634401077 | 20230306071427 | 20230306071426     |      241837 |      518 | wikitext           | NULL      |
|      16 |              0 | dictionary                                 |                0 |           0 | 0.0344021981902441 | 20240801141041 | 20240801055722     |    79489285 |    25163 | wikitext           | NULL      |
|      17 |              5 | Text_of_the_GNU_Free_Documentation_License |                0 |           0 |  0.579518118481634 | 20240208234543 | 20230306071426     |     2240730 |      829 | wikitext           | NULL      |
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
10 rows in set (0.009 sec)

MariaDB [finn]> select * from categorylinks limit 10;
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
| cl_from | cl_to                                                                            | cl_sortkey
                                                | cl_timestamp        | cl_sortkey_prefix                          | cl_collation | cl_type |
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
|       6 | Wiktionary_beginners                                                             | WELCOME, NEWCOMERS
                                                | 2023-06-28 05:33:50 |                                            | uppercase    | page    |
|       6 | Wiktionary_pages_with_shortcuts                                                  | WELCOME, NEWCOMERS
                                                | 2023-06-28 05:33:50 |                                            | uppercase    | page    |
|       8 | Wiktionary                                                                       | TEXT OF THE GNU FREE DOCUMENTATION LICENSE
TEXT OF THE GNU FREE DOCUMENTATION LICENSE | 2013-12-31 15:47:07 | Text of the GNU Free Documentation License | uppercase    | page    |
|      12 | Help                                                                             | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2016-02-01 18:34:08 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary                                                                       | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2011-04-10 18:22:23 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary_beginners                                                             | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2016-11-07 13:56:37 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary_pages_with_shortcuts                                                  | WHAT WIKTIONARY IS NOT
                                                | 2023-06-28 05:32:45 |                                            | uppercase    | page    |
|      16 | American_Sign_Language_terms_in_nonstandard_scripts                              | DICTIONARY
DICTIONARY                                                                 | 2024-03-06 18:33:42 | DICTIONARY
         | uppercase    | page    |
|      16 | Automatic_Inscriptional_Pahlavi_transliterations_containing_ambiguous_characters | DICTIONARY
DICTIONARY                                                                 | 2024-03-06 18:33:42 | DICTIONARY
         | uppercase    | page    |
|      16 | English_3-syllable_words                                                         | DICTIONARY
DICTIONARY                                                                 | 2024-06-22 05:30:49 | DICTIONARY
         | uppercase    | page    |
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
10 rows in set (0.006 sec)
```

この中で、`page_title`がページ名(つまりWiktionaryでいえば単語の見出し語)、`cl_to`がカテゴリ名、`cl_sortkey`がアルファベット順のソートキーっぽい。なので、この2テーブルをJOINして、`cl_to`が`Finnish_lemmas`の`page_title`を`cl_sortkey`順に取り出して、ファイルに書き出す。なお、`cl_type`が`subcat`のものも少し混じっているので、`cl_type`は`page`に限定する。

```sql
select
  page_title
from
  page as p
  inner join categorylinks as c on
    c.cl_from = p.page_id
where
  c.cl_to = 'Finnish_lemmas' and
  c.cl_type = 'page'
order by
  c.cl_sortkey
into outfile 'enwiktionary-finnish-lemmas.txt';
```

結果のファイルは(クライアント側のコンテナではなく)DBサーバ側のコンテナの`/var/lib/mysql/finn/`に出力される。

クライアントコンテナは抜ける。

```bash
quit
exit
```

ローカルで見ると、`../finn-db-data/finn/enwiktionary-finnish-lemmas.txt`が出来ている。ただパーミッションが無くて見れないので、sudoで移動し、オーナーとグループを変える。

```bash
sudo mv ../finn-db-data/finn/enwiktionary-finnish-lemmas.txt .
sudo chown alpha:alpha enwiktionary-finnish-lemmas.txt
```

## 結果

中身はこんな感じ(冒頭100行)。[Category:Finnish lemmas](https://en.wiktionary.org/wiki/Category:Finnish_lemmas)の中身とも合ってるっぽい。

```text
'
-
Unsupported_titles/`period`
.fi
1_500_metrin_juoksu
1_500_metriä
1._Aik.
1._Moos.
1._Sam.
1._Tim.
10_000_metrin_juoksu
10_000_metriä
100_metrin_juoksu
100_metriä
100.
1000.
1000:s
112
18-trisomia
1:nen
1-propanoli
2._Aik.
2._Moos.
2._Sam.
200_metrin_juoksu
200_metriä
24/7
2-metyylibutaani
2:nen
3._Moos.
3D-skanneri
3D-tulostin
3D-tulostus
3:s
4._Moos.
400_metrin_juoksu
400_metriä
4H-kerho
4H-kerholainen
4H-neuvoja
4H-toiminta
5_000_metrin_juoksu
5_000_metriä
5._Moos.
5-hydroksitryptamiini
800_metrin_juoksu
800_metriä
Unsupported_titles/:
-a
A
a
a-
à
A_ja_O
à_la_carte_-annos
à_la_mode
a_priori
a_propos
a_vot
aa
aa'a
Aabraham
Aada
Aadam
Aadolf
aah
aaja
Aake
Aakko
aakkonen
aakkosellinen
aakkosellisesti
aakkosellisuus
aakkoshakemisto
aakkosittain
aakkosjärjestelmä
aakkosjärjestys
aakkoskeitto
aakkoslaji
aakkosluettelo
aakkoslukko
aakkosnimi
aakkosnumeerinen
aakkosnumeerisesti
aakkostaa
aakkostaminen
aakkosto
aakkostus
Aakula
AA-liike
aalloitse
aalloittain
aalloittainen
aalloittaisuus
aallokas
aalloke
aallokemuunnos
aallokko
aallokkoinen
aallonharja
```

参考までに、できたファイルの現物もここに置いておく。

- [enwiktionary-finnish-lemmas.txt](resources/enwiktionary-finnish-lemmas.txt)

## コンソールのサンプル

```console
$ curl --remote-name --location https://mirror.accum.se/mirror/wikimedia.org/dumps/enwiktionary/20240801/enwiktionary-20240801-page.sql.gz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   434  100   434    0     0    198      0  0:00:02  0:00:02 --:--:--   198
100  249M  100  249M    0     0  2721k      0  0:01:33  0:01:33 --:--:-- 2710k
$ curl --remote-name --location https://mirror.accum.se/mirror/wikimedia.org/dumps/enwiktionary/20240801/enwiktionary-20240801-categorylinks.sql.gz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   440  100   440    0     0    488      0 --:--:-- --:--:-- --:--:--   487
100  576M  100  576M    0     0  2959k      0  0:03:19  0:03:19 --:--:-- 3031k
$ curl --remote-name --location https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-sha1sums.txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3318  100  3318    0     0   4647      0 --:--:-- --:--:-- --:--:--  4653
$ ls -l
total 846088
-rw-r--r-- 1 alpha alpha 605022961 Aug 16 21:35 enwiktionary-20240801-categorylinks.sql.gz
-rw-r--r-- 1 alpha alpha 261360799 Aug 16 21:32 enwiktionary-20240801-page.sql.gz
-rw-r--r-- 1 alpha alpha      3318 Aug 16 21:36 enwiktionary-latest-sha1sums.txt
$ sha1sum --check enwiktionary-latest-sha1sums.txt --ignore-missing
enwiktionary-20240801-categorylinks.sql.gz: OK
enwiktionary-20240801-page.sql.gz: OK
$ gzip --decompress --keep *.gz
$ ls -l
total 7648860
-rw-r--r-- 1 alpha alpha 5900788609 Aug 16 21:35 enwiktionary-20240801-categorylinks.sql
-rw-r--r-- 1 alpha alpha  605022961 Aug 16 21:35 enwiktionary-20240801-categorylinks.sql.gz
-rw-r--r-- 1 alpha alpha 1065239522 Aug 16 21:32 enwiktionary-20240801-page.sql
-rw-r--r-- 1 alpha alpha  261360799 Aug 16 21:32 enwiktionary-20240801-page.sql.gz
-rw-r--r-- 1 alpha alpha       3318 Aug 16 21:36 enwiktionary-latest-sha1sums.txt
$ mkdir ../finn-db-data
$ docker network create finn
c560ae6e7b2fa30c836e81f9be2f8071b8604dfbac24269f86e966a298c87ab7
$ docker run \
  --detach \
  --network finn \
  --name finn-db \
  --volume $PWD/../finn-db-data:/var/lib/mysql \
  --env MARIADB_ROOT_PASSWORD=finn \
  mariadb
13c4c7fb5005a6c39deded0ec20bb93701ea4c1603fb05973f90ed106e291ef2
$ docker run -it --network finn --rm -v $PWD:/work -w /work mariadb bash
root@57ade8021967:/work# mariadb --host=finn-db --user=root --password=finn
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 11.5.2-MariaDB-ubu2404 mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database finn;
Query OK, 1 row affected (0.005 sec)

MariaDB [(none)]> use finn;
Database changed
MariaDB [finn]> source enwiktionary-20240801-page.sql
Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

(...)

Query OK, 9970 rows affected (0.184 sec)
Records: 9970  Duplicates: 0  Warnings: 0

Query OK, 10513 rows affected (0.357 sec)
Records: 10513  Duplicates: 0  Warnings: 0

(...)

Query OK, 8954 rows affected (4.384 sec)
Records: 8954  Duplicates: 0  Warnings: 0

Query OK, 1585 rows affected (0.950 sec)
Records: 1585  Duplicates: 0  Warnings: 0

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected, 1 warning (0.000 sec)

MariaDB [finn]> desc page;
+--------------------+---------------------+------+-----+---------+----------------+
| Field              | Type                | Null | Key | Default | Extra          |
+--------------------+---------------------+------+-----+---------+----------------+
| page_id            | int(8) unsigned     | NO   | PRI | NULL    | auto_increment |
| page_namespace     | int(11)             | NO   | MUL | 0       |                |
| page_title         | varbinary(255)      | NO   |     |         |                |
| page_is_redirect   | tinyint(1) unsigned | NO   | MUL | 0       |                |
| page_is_new        | tinyint(1) unsigned | NO   |     | 0       |                |
| page_random        | double unsigned     | NO   | MUL | 0       |                |
| page_touched       | binary(14)          | NO   |     | NULL    |                |
| page_links_updated | varbinary(14)       | YES  |     | NULL    |                |
| page_latest        | int(8) unsigned     | NO   |     | 0       |                |
| page_len           | int(8) unsigned     | NO   | MUL | 0       |                |
| page_content_model | varbinary(32)       | YES  |     | NULL    |                |
| page_lang          | varbinary(35)       | YES  |     | NULL    |                |
+--------------------+---------------------+------+-----+---------+----------------+
12 rows in set (0.001 sec)

MariaDB [finn]> select count(*) from page;
+----------+
| count(*) |
+----------+
|  9663209 |
+----------+
1 row in set (3.619 sec)

MariaDB [finn]> select * from page limit 10;
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
| page_id | page_namespace | page_title                                 | page_is_redirect | page_is_new | page_random        | page_touched   | page_links_updated | page_latest | page_len | page_content_model | page_lang |
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
|       6 |              4 | Welcome,_newcomers                         |                0 |           0 |  0.119036956801114 | 20240731044752 | 20240731045354     |    80638725 |     6460 | wikitext           | NULL      |
|       7 |              4 | GNU_Free_Documentation_License             |                0 |           0 |  0.492815242607906 | 20220827002219 | 20220827002219     |    68763312 |     2776 | wikitext           | NULL      |
|       8 |              4 | Text_of_the_GNU_Free_Documentation_License |                0 |           0 |  0.106965373369833 | 20240720013141 | 20240720014140     |    11480759 |    16898 | wikitext           | NULL      |
|       9 |              2 | Sjc~enwiktionary                           |                0 |           0 | 0.0563811697590921 | 20230310202314 | 20230310202313     |    32611008 |       86 | wikitext           | NULL      |
|      12 |              4 | What_Wiktionary_is_not                     |                0 |           0 |  0.296497345246838 | 20240730234243 | 20240730234808     |    69871386 |    11266 | wikitext           | NULL      |
|      13 |              2 | Eloquence                                  |                1 |           1 |  0.574770801304626 | 20230306071427 | 20230306071426     |      241835 |       30 | wikitext           | NULL      |
|      14 |              2 | Merphant                                   |                0 |           0 |  0.984362001516262 | 20230306071427 | 20230306071426     |      241836 |       61 | wikitext           | NULL      |
|      15 |              3 | Merphant                                   |                0 |           0 |  0.197497634401077 | 20230306071427 | 20230306071426     |      241837 |      518 | wikitext           | NULL      |
|      16 |              0 | dictionary                                 |                0 |           0 | 0.0344021981902441 | 20240801141041 | 20240801055722     |    79489285 |    25163 | wikitext           | NULL      |
|      17 |              5 | Text_of_the_GNU_Free_Documentation_License |                0 |           0 |  0.579518118481634 | 20240208234543 | 20230306071426     |     2240730 |      829 | wikitext           | NULL      |
+---------+----------------+--------------------------------------------+------------------+-------------+--------------------+----------------+--------------------+-------------+----------+--------------------+-----------+
10 rows in set (0.009 sec)

MariaDB [finn]> source enwiktionary-20240801-categorylinks.sql
Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

(...)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 9780 rows affected (0.129 sec)
Records: 9780  Duplicates: 0  Warnings: 0

Query OK, 9684 rows affected (0.179 sec)
Records: 9684  Duplicates: 0  Warnings: 0

(...)

Query OK, 8233 rows affected (2.477 sec)
Records: 8233  Duplicates: 0  Warnings: 0

Query OK, 7107 rows affected (2.091 sec)
Records: 7107  Duplicates: 0  Warnings: 0

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.000 sec)

Query OK, 0 rows affected (0.001 sec)

Query OK, 0 rows affected, 1 warning (0.000 sec)

MariaDB [finn]> desc categorylinks;
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
| Field             | Type                         | Null | Key | Default             | Extra                         |
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
| cl_from           | int(8) unsigned              | NO   | PRI | 0                   |                               |
| cl_to             | varbinary(255)               | NO   | PRI |                     |                               |
| cl_sortkey        | varbinary(230)               | NO   |     |                     |                               |
| cl_timestamp      | timestamp                    | NO   |     | current_timestamp() | on update current_timestamp() |
| cl_sortkey_prefix | varbinary(255)               | NO   |     |                     |                               |
| cl_collation      | varbinary(32)                | NO   |     |                     |                               |
| cl_type           | enum('page','subcat','file') | NO   |     | page                |                               |
+-------------------+------------------------------+------+-----+---------------------+-------------------------------+
7 rows in set (0.001 sec)

MariaDB [finn]> select count(*) from categorylinks;
+----------+
| count(*) |
+----------+
| 49263384 |
+----------+
1 row in set (54.804 sec)

MariaDB [finn]> select * from categorylinks limit 10;
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
| cl_from | cl_to                                                                            | cl_sortkey
                                                | cl_timestamp        | cl_sortkey_prefix                          | cl_collation | cl_type |
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
|       6 | Wiktionary_beginners                                                             | WELCOME, NEWCOMERS
                                                | 2023-06-28 05:33:50 |                                            | uppercase    | page    |
|       6 | Wiktionary_pages_with_shortcuts                                                  | WELCOME, NEWCOMERS
                                                | 2023-06-28 05:33:50 |                                            | uppercase    | page    |
|       8 | Wiktionary                                                                       | TEXT OF THE GNU FREE DOCUMENTATION LICENSE
TEXT OF THE GNU FREE DOCUMENTATION LICENSE | 2013-12-31 15:47:07 | Text of the GNU Free Documentation License | uppercase    | page    |
|      12 | Help                                                                             | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2016-02-01 18:34:08 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary                                                                       | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2011-04-10 18:22:23 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary_beginners                                                             | WHAT WIKTIONARY IS NOT
WHAT WIKTIONARY IS NOT                                         | 2016-11-07 13:56:37 | What Wiktionary is not                     | uppercase    | page    |
|      12 | Wiktionary_pages_with_shortcuts                                                  | WHAT WIKTIONARY IS NOT
                                                | 2023-06-28 05:32:45 |                                            | uppercase    | page    |
|      16 | American_Sign_Language_terms_in_nonstandard_scripts                              | DICTIONARY
DICTIONARY                                                                 | 2024-03-06 18:33:42 | DICTIONARY
         | uppercase    | page    |
|      16 | Automatic_Inscriptional_Pahlavi_transliterations_containing_ambiguous_characters | DICTIONARY
DICTIONARY                                                                 | 2024-03-06 18:33:42 | DICTIONARY
         | uppercase    | page    |
|      16 | English_3-syllable_words                                                         | DICTIONARY
DICTIONARY                                                                 | 2024-06-22 05:30:49 | DICTIONARY
         | uppercase    | page    |
+---------+----------------------------------------------------------------------------------+---------------------------------------------------------------------------------------+---------------------+--------------------------------------------+--------------+---------+
10 rows in set (0.006 sec)

MariaDB [finn]> select cl_collation, cl_type, count(*) from categorylinks where cl_to='Finnish_lemmas' group by 1, 2;
+--------------+---------+----------+
| cl_collation | cl_type | count(*) |
+--------------+---------+----------+
| uppercase    | page    |   165486 |
| uppercase    | subcat  |       15 |
+--------------+---------+----------+
2 rows in set (16.100 sec)

MariaDB [finn]> select
    ->   page_title
    -> from
    ->   page as p
    ->   inner join categorylinks as c on
    ->     c.cl_from = p.page_id
    -> where
    ->   c.cl_to = 'Finnish_lemmas' and
    ->   c.cl_type = 'page'
    -> order by
    ->   c.cl_sortkey
    -> into outfile 'enwiktionary-finnish-lemmas.txt';
Query OK, 165486 rows affected (11.372 sec)

MariaDB [finn]> quit
Bye
root@57ade8021967:/tmp# exit
exit
$ sudo mv ../finn-db-data/finn/enwiktionary-finnish-lemmas.txt .
$ ls -l enwiktionary-finnish-lemmas.txt
-rw-r--r-- 1 999 systemd-journal 2096915 Aug 17 07:15 enwiktionary-finnish-lemmas.txt
$ sudo chown alpha:alpha enwiktionary-finnish-lemmas.txt
$ ls -l enwiktionary-finnish-lemmas.txt
-rw-r--r-- 1 alpha alpha 2096915 Aug 17 07:15 enwiktionary-finnish-lemmas.txt
```

※バージョンメモ

- mariadbd  Ver 11.5.2-MariaDB-ubu2404 for debian-linux-gnu on x86_64 (mariadb.org binary distribution)
