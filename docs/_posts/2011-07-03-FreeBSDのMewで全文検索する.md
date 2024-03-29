---
title: "FreeBSDのMewで全文検索する"
categories: パソコン
---

FreeBSD上のMewで、メールの全文検索を試してみました。といっても特に難しいことは何も無く、Hyper Estraierをインストールし、インデックスを作り、検索するだけでした。

今回試した具体的な手順は次のとおりです。

まず下記のpackage (またはport) をインストールします。

- hyperestraier (textproc/hyperestraier)

次にMewで「kM」と入力してしばらく待つと、エコー領域に次のようなメッセージが表示され、メール全文のインデックスが作成されます。

```console
Hyper Estraier indexing...
Hyper Estraier indexing ...done
```

インデックス本体は、~/Mail/casket/ 以下に作成されるようです。
なお、インデックスは、シェルなどからmewestコマンドを起動することでも作成/更新できます。

```console
$ mewest
Indexing new messages...
Indexing new messages...done
```

インデックスができたら、Mewで「k/」と入力するとエコー領域に下記のプロンプトが出るので、検索キーワードを入力します。下記は「チューナー」という単語で検索する例。

```console
Hyper Estraier virtual pattern: チューナー
```

そのあとにフィルタパターンを訊かれますが、ここはそのままRETで構いません。もし、例えばFrom:がsomeoneのメールだけを表示したい場合は、ここで「from=someone」のように入力します。

```console
Hyper Estraier filter pattern: 
```

これでVirtualなセレクションが作られ、条件に該当するメールが表示されます。

手順としては以上ですが、気づいたことを2つほど。

まず、~/Mail をシンボリックリンクにしていると、インデックスが作成されないようです。私はこれに気づくまで結構かかり、悩みました。

あと、ヘッダに「Content-Type」が無いメールは、日本語部分のインデックスが上手く作成されず、結果的に検索でひっかからなくなるようです。

※バージョンメモ

- FreeBSD 8.2-RELEASE
- emacs-23.3_1,2
- mew-emacs23-6.3_2
- hyperestraier-1.4.13
