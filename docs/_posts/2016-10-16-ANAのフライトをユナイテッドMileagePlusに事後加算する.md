---
title: "ANAのフライトをユナイテッドMileagePlusに事後加算する"
---

スターアライアンスに乗ったときはマイルをユナイテッド航空のマイレージプラスに貯めてるんですが、この夏ANAの国内線に乗ったとき、うっかりそれを言い忘れてしまい、あとから加算してもらいました([5年前にアイスランド旅行したとき]({% post_url 2011-09-12-アイスランドに行く-1日目 %})以来ずっと飛行機乗ってなくて、そういうの忘れてたわ……)。

ざっくり結論だけ言うと、

1. ANAのサイトで英文の領収書を取得
1. 搭乗日から15日後以降に、ユナイテッドのサイトのメールフォームからそれを送る

というやり方で事後加算できたのですが、実際にはなかなかそこまでたどり着けなかったので、ちょっとその経緯をメモしておきます。

まず、電話での申請は早い段階で諦めました。マイレージプラスサービスセンターに電話すれば速い、という話も見かけましたが、そもそもユナイテッド本家のサイトで日本国内の問い合わせ先電話番号が見つけられませんでした。外部サイトで検索すると東京のコールセンターの番号は出てきますが、繋がりにくいとのことで、格安SIMで電話すると待ち時間だけでも通話料が馬鹿にならないので、やっぱり電話はパス。

あと、搭乗券の半券とか領収書を郵送するという方法もパス。なぜかというと、今回はANAのウェブサイトでチケットを購入してスマホの2次元バーコードで搭乗したので、そもそも紙の航空券も領収書も搭乗券もないのです。

となると、あとはウェブページで申請するか、メールで問い合わせるかです。

とりあえず「マイル加算申請」のページを試しましたが、うまくいかず。余談ですが、ユナイテッド航空のウェブページは非常に使い勝手が悪く、イライラさせられます。遅い、どこに何があるのかわからない、リンク切れが多い、ウェブサイトの表示言語設定が日本語だとエラーで表示されないページがあるなど、わざとやってるんじゃないかと疑いたくなるレベルです。マイル加算申請のページも日本語設定だとエラーで表示できないので、言語設定を英語に変えてトライします (その言語設定の変え方も、元言語が何かによって全然違う画面が出てきます。アホか)。でマイル加算申請のページですが、メニューの「MileagePlus」から「Earn award miles」を選び、ページのいちばん下にある「Missing miles? Request mileage credit」のリンクを押すと「Requesting credit to your MileagePlus account」というページに飛ぶので、「Star Alliance member airlines」を開いて「submit a request for credit.」を押します。ログイン画面を経て「Request credit for flights operated by United, United Express and select partners」というページに飛び、ここでフライト情報を入力するようになっています。Operating airlineでAll Nipponを選ぶと入力フォームが出てきます。が、最初のTicket numberが分からない。紙の航空券もないし、ANAから来たメールを隅から隅まで見てもそんなものは書いてません。Boarding Numberの[?]マークにポインタを当てると「ANAの国内線チケットはTicket number書いてないので205000000000を入れろ」みたいなツールチップが出るのでそれを入れると、結局無効だというエラーになります。どうしようもないので、ウェブページからの申請はこの辺でギブアップ。

で結局メールで問い合わせることにしました。「MileagePlus contact information」ページにある「Email MileagePlus」というリンクを押して、入力フォームから拙い英文で「マイル加算してちょ」というメールを書きます。この時点で伝えられる限りの情報として、搭乗日、便名、出発地、到着地、あと出発地の空港でもらった「ご搭乗案内」という紙に書かれた照会番号、BN、SN、FAREも付記しました。……が、おそらく無意味だったと思われます。

2日ほどで返信が来ました。搭乗者名、発行日、搭乗日、座席クラス、便名、チケット番号、料金、出発地、到着地が書かれた領収書のコピーを送れと書いてあります。ちょっと長い英文ですが、参考のために引用しておきます。

> Partner flights cannot be processed until 15 days after travel.
>
> In order to credit your account with any unrecorded flights taken within the past 12 months, I need additional information.
>
> Please forward legible copies of your ticket receipts or E-Ticket receipts that clearly show the passenger's name, date of issue, dates of travel, class of service, flight numbers, ticket numbers, fare paid, and departure and destination cities. Also be sure to include your MileagePlus account number so we can update your account. I will update the account(s) if mileage credit is due.
>
> If you no longer have the appropriate documentation but purchased your ticket through a travel agency, I suggest you contact the agency. Travel agents are required to keep copies of all tickets they issue. 

このメールの最後に「領収書がなければ代理店が持ってるはずだから、そっから貰えよ」(大意)と書いてあるのをみて、ようやくANAで何か発行してもらえるかも、ということに気づきました。

ANAのサイトに行くと、確かにトップページに「領収書・搭乗証明書検索」というのがあります。こっちは素直な画面構成なので、すぐに領収書を表示させることができました。これをPDFに"印刷"すれば、電子の領収書が手に入ります。ただ問題がひとつ。記載内容がすべて日本語なので、これをユナイテッドに送っても理解してもらえないかもしれません。ふと気づいてANAのトップページに戻り、言語をEnglishにすると、トップページのボタンも「Receipt/Certificate for boarding」になり、今度は内容がすべて英文の領収書を表示させることができました。ちなみに、チケットを購入するときに氏名をカタカナで登録していたため、Passenger Nameはどうしてもカタカナで出てしまうのですが、手入力できる宛名欄にローマ字の名前を表示させることでごまかしました。

先のメールへの返信でこの領収書を添付して送ると、むこうからは特に返信は来ませんでしたが、1か月ほどして確認すると、無事マイルが加算されていました。ほんの数百マイルのことでいろいろ苦労しましたが、ま、結果オーライということで。
