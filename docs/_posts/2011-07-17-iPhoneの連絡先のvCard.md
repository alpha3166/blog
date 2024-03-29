---
title: "iPhoneの連絡先のvCard"
categories: スマホ
---

iPhoneの「連絡先」アプリで「連絡先を送信」すると、データをvCard形式(.vcf)でメールに添付して送信できます。iPhoneで入力した内容が、vCardではどのように出力されるのか、項目の対応関係が知りたくて、少し調べてみました。

まずはiPhoneで、下記の内容の新規連絡先を作成します。追加フィールドも含めて、フルセットの項目を入力しています。

```plaintext
■画像
 JPEG画像

■名前
 [敬称(前)] ドクター
 [姓] 山田
 [姓の読み] やまだ
 [名] 太郎
 [名の読み] たろう
 [ミドルネーム] ジョン
 [敬称(後)] 様
 [ニックネーム] やまちゃん
 [役職] 部長
 [部署] 総務部
 [会社] 海山商事

■電話
 [携帯] 090 1111 0001
 [iPhone] 080 1111 0002
 [自宅] 03 1111 0003
 [勤務先] 03 1111 0004
 [主番号] 03 1111 0005
 [自宅ファクス] 03 1111 0006
 [勤務先ファクス] 03 1111 0007
 [ポケベル] 020 1111 0008
 [その他] 03 1111 0009
 [カスタムラベル] 03 1111 0010

■メール
 [自宅] jitaku@example.com
 [勤務先] kinmusaki@example.com
 [その他] sonota@example.com
 [カスタムラベル] customlabel@example.com

■サウンド
 [着信音] マリンバ
 [SMS/MMS] 予感

■URL
 [Web] http://web.example.com/
 [自宅] http://jitaku.example.com/
 [勤務先] http://kinmusaki.example.com/
 [その他] http://sonota.example.com/
 [カスタムラベル] http://customlabel.example.com/

■住所
 [自宅] 100-0001
        東京都 千代田区
        千代田
        1-1-1
        日本
 [勤務先] 100-0002
          東京都 千代田区
          皇居外苑
          1-1-2
          日本
 [その他] 100-0003
          東京都 千代田区
          一ツ橋
          1-1-3
          日本
 [カスタムラベル] 100-0004
                  東京都 千代田区
                  大手町
                  1-1-4
                  日本

■誕生日
 [誕生日] 1960年1月1日

■日付
 [記念日] 2011年1月2日
 [その他] 2011年1月3日
 [カスタムラベル] 2011年1月4日

■インスタントメッセージ
 [自宅] jitaku
        AIM
 [勤務先] kinmusaki
          Yahoo!
 [その他] sonota
          MSN
 [カスタムラベル] customlabel
                  ICQ
 [カスタムラベル] customlabel2
                  Jabber

■メモ
 [メモ] 北海道生まれ
```

次にこの連絡先をメールで自分宛に送信します。
添付されていた.vcfをPCのテキストエディタで開いた内容が下記です。

```properties
BEGIN:VCARD
VERSION:3.0
N:山田;太郎;ジョン;ドクター;様
FN:ドクター 山田 太郎 様 ジョン
NICKNAME:やまちゃん
X-PHONETIC-FIRST-NAME:たろう
X-PHONETIC-LAST-NAME:やまだ
ORG:海山商事;総務部
TITLE:部長
EMAIL;type=INTERNET;type=HOME;type=pref:jitaku@example.com
EMAIL;type=INTERNET;type=WORK:kinmusaki@example.com
item1.EMAIL;type=INTERNET:sonota@example.com
item1.X-ABLabel:_$!<Other>!$_
item2.EMAIL;type=INTERNET:customlabel@example.com
item2.X-ABLabel:カスタムラベル
TEL;type=CELL:090 1111 0001
TEL;type=IPHONE:080 1111 0002
TEL;type=HOME:03 1111 0003
TEL;type=WORK:03 1111 0004
TEL;type=MAIN:03 1111 0005
TEL;type=HOME;type=FAX:03 1111 0006
TEL;type=WORK;type=FAX:03 1111 0007
TEL;type=PAGER:020 1111 0008
item3.TEL:03 1111 0009
item3.X-ABLabel:_$!<Other>!$_
item4.TEL:03 1111 0010
item4.X-ABLabel:カスタムラベル
item5.ADR;type=HOME;type=pref:;;千代田\n1-1-1;千代田区;東京都;100-0001;日本
item5.X-ABADR:ja
item6.ADR;type=WORK:;;皇居外苑\n1-1-2;千代田区;東京都;100-0002;日本
item6.X-ABADR:ja
item7.ADR;type=HOME:;;一ツ橋\n1-1-3;千代田区;東京都;100-0003;日本
item7.X-ABLabel:_$!<Other>!$_
item7.X-ABADR:ja
item8.ADR;type=HOME:;;大手町\n1-1-4;千代田区;東京都;100-0004;日本
item8.X-ABLabel:カスタムラベル
item8.X-ABADR:ja
item9.URL;type=pref:http://web.example.com/
item9.X-ABLabel:_$!<HomePage>!$_
URL;type=HOME:http://jitaku.example.com/
URL;type=WORK:http://kinmusaki.example.com/
item10.URL:http://sonota.example.com/
item10.X-ABLabel:_$!<Other>!$_
item11.URL:http://customlabel.example.com/
item11.X-ABLabel:カスタムラベル
BDAY;value=date:1960-01-01
PHOTO;ENCODING=b;TYPE=JPEG:/9j/4AAQSkZJRgABAQAAAQABAAD/4QBYRXhpZgAATU0AKgAA
 AAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAA
 (中略)
 O9f7sNwNpc+inOCa7r+0/egDof7Uz0NH9qeprnJdXw3RnZzwFHJpY9UWRNwySwGCSRt9eP8APS
 gD/9k=
X-YAHOO;type=WORK:kinmusaki
item12.X-MSN:sonota
item12.X-ABLabel:_$!<Other>!$_
item13.X-ICQ:customlabel
item13.X-ABLabel:カスタムラベル
item14.X-JABBER:customlabel2
item14.X-ABLabel:カスタムラベル
END:VCARD
```

この結果を見ると、全ての項目がvCardに出力されるわけではないようです。サウンドの設定、誕生日を除く日付、インスタントメッセージのAIM、メモ、が出力されていません。

なお、Twitter for iPhoneでユーザーを表示させて「新規連絡先を作成」(または「既存の連絡先に追加」)すると、その人のTwitterアカウントが連絡先に追加されます。この場合は、「twitter」というカスタムラベルが自動的に作られ、URLの中にそのカスタムラベルで「twitter:@foo」のような文字列が登録されるようです。

※バージョンメモ

- iOS 4.3.3
