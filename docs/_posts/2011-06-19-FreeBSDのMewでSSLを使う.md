---
title: "FreeBSDのMewでSSLを使う"
category: アプリの使い方
---

Yahoo! JAPANのメール(Y!メール)は、外部のメールクライアントからPOPでメールを取り出せるようになっていますが、APOPに対応していないためパスワードはネットワーク上を平文で流れてしまいます。またSMTPでメールを送信する場合のSMTP-AUTHのパスワードも同様に平文で流れます。幸い両方ともSSLに対応しているので、SSLで通信経路を暗号化してしまえば安心です。またGmailもPOPとIMAPでアクセス可能ですが、こちらはそもそもSSLを使わなければアクセスできないようです。

そんなわけで、Y!メールやGmailを外から使うにはSSLが必須なのですが、私がFreeBSD上で普段使っているMewは、単独ではSSLに対応していません。ただ、別途stunnelをインストールすれば、Mewが自動的にstunnelを呼び出してSSL経由で送受信ができます。

今回、MewでSSLを使ってY!メールにPOP/SMTPアクセスする方法と、GmailにIMAP/SMTPアクセスする方法を試してみたので、その手順をメモしておきます。

前提として、packagesかportsから

- emacs (editors/emacs)
- mew-emacs23 (mail/mew)

をインストールした上で、~/.emacsに下記を追加し、Mewを起動できるようになっているものとします。

```common_lisp
(autoload 'mew "mew" nil t)
(autoload 'mew-send "mew" nil t)
```

第1段階として、SSLを使わずにY!メールにPOP/SMTPアクセスしてみます。ただ、前述のとおりパスワードが平文で流れますので、通常はこの方法を使わない方が無難です。

~/.mew.elにY!メールの設定を書いて行きます。注意点としては……、

- Y!メールのPOPサーバはAPOPに対応していないので、POPの認証方式として明示的に平文を指定する必要があります。具体的には、mew-pop-authを'passにします。
- Y!メールのSMTPサーバ経由で送信する場合、SMTP-AUTHかPOP before SMTPでの認証が必要になります。ただし、POP before SMTPが使えるのはFromのアドレスが@yahoo.co.jpか@ybb.ne.jpのときだけです。通常はSMTP-AUTHを使う想定で良いでしょう。具体的には、mew-smtp-userにY!メールのユーザIDを設定しておく必要があります。
- プロバイダがOutbound Port25 Blockingを実施している場合(最近はほとんどが該当すると思いますが)、SMTPサーバに接続するときのポート番号を587にする必要があります。具体的には、mew-smtp-portを587にしておきます。

```common_lisp
;; Fromの表示名
(setq mew-name "アルファ")
;; Fromのメールアドレスの@の左側
(setq mew-user "alpha3166")
;; Fromのメールアドレスの@の右側
(setq mew-mail-domain "yahoo.co.jp")
;; POPサーバ
(setq mew-pop-server "pop.mail.yahoo.co.jp")
;; POPの認証方式
;;   'apop : APOP(デフォルト)
;;   'pass : 平文
;;   t : mew-pop-auth-listに従ったSASL
(setq mew-pop-auth 'pass)
;; POPのユーザID
(setq mew-pop-user "alpha3166")
;; SMTPサーバ
(setq mew-smtp-server "smtp.mail.yahoo.co.jp")
;; SMTP-AUTHのユーザID
(setq mew-smtp-user "alpha3166")
;; SMTPサーバに接続するときのポート番号 (OP25B実施プロバイダから接続するときは587を指定)
(setq mew-smtp-port 587)
```

この設定で、メールの送受信ともに実施できました。(なお上記のユーザIDは架空です)

では第2段階として、いよいよSSLを使ってY!メールにPOP/SMTPアクセスしてみます。

まず、packages/portsから

- stunnel (security/stunnel)
- ca_root_nss (security/ca_root_nss)

をインストールします。ca_root_nssはルート認証局の証明書です。

次に、~/.mew.elに以下の設定を追加します。

```common_lisp
;; 証明書を検証するレベル
;;   0 : サーバの証明書があっても無くても検証せずにSSL接続
;;   1 : サーバの証明書が「無し」か「ありで検証OK」のときだけSSL接続
;;   2 : サーバの証明書が「ありで検証OK」のときだけSSL接続
;;   3 : サーバが送ってきたものではなくローカルの証明書で検証OKのときだけSSL接続
(setq mew-ssl-verify-level 2)
;; ルート認証局の証明書のパス
(setq mew-ssl-cert-directory "\nCAfile=/usr/local/share/certs/ca-root-nss.crt")
;; POP over SSLを使う
(setq mew-pop-ssl t)
;; SMTP over SSLを使う
(setq mew-smtp-ssl t)
```

なお、SMTP over SSLでは自動的にデフォルトの465番ポートが使われるので、平文の時に設定した(setq mew-smtp-port 587)は削除しても構いません。

ここでmew-ssl-cert-directoryの記述がちょっとおかしいと思う方がいるかもしれません。この変数は本来「PEM 形式の証明書を "<ハッシュ>.0" という名前でコピー」したディレクトリを指定するものです(デフォルトは~/.certs)。Mewが内部的にstunnelを呼び出す際、/tmpの中に一時的なstunnelの設定ファイルを生成し、それを引数にstunnelを起動するのですが、mew-ssl-cert-directoryの値は、その一時ファイルの「CApath=」の値に引き継がれます。以下に例を示します。

```ini
client=yes
pid=
verify=2
foreground=yes
syslog=no
CApath=/home/alpha3166/.certs
[11611]
accept=127.0.0.1:11611
connect=pop.mail.yahoo.co.jp:995
```

しかし私が試した範囲では、~/.certsの中に置いた証明書が正しく認識されず「Creating an SSL/TLS connection...FAILED (cert verify failure)」になる場合がありました。そんな場合でも、stunnelに渡すファイルに「CAfile=」でシステムワイドのルート証明書のパス(/usr/local/share/certs/ca-root-nss.crt)を指定してやるとうまく動きました。しかし現状、MewからCAfileを指定する手段がありません。そこで苦肉の索として、mew-ssl-cert-directoryの先頭に改行を置き、CAfileのキーと値を両方記述したというわけです。

これでSSLを使った送受信ができました。なお、受信のときはモードラインに錠前のアイコンが表示されましたが、送信のときはなぜか表示されませんでした。ただ(setq mew-debug t)して出てくるログを見る限りでは、ちゃんとSSLで通信しているようです。

最後に、GmailにSSLを使ってIMAP/SMTPアクセスしてみます。

```common_lisp
;; Fromの表示名
(setq mew-name "アルファ")
;; Fromのメールアドレスの@の左側
(setq mew-user "alpha3166")
;; Fromのメールアドレスの@の右側
(setq mew-mail-domain "gmail.com")
;; Mew起動時のフォルダ
;;   "+" : +inbox
;;   "$" : $inbox
;;   "%" : %inbox
;;   "-" : -fj.mail.reader.mew
(setq mew-proto "%")
;; IMAPサーバ
(setq mew-imap-server "imap.gmail.com")
;; IMAPのユーザID
(setq mew-imap-user "alpha3166@gmail.com")
;; SMTPサーバ
(setq mew-smtp-server "smtp.gmail.com")
;; SMTP-AUTHのユーザID
(setq mew-smtp-user "alpha3166@gmail.com")
;; 証明書を検証するレベル
;;   0 : サーバの証明書があっても無くても検証せずにSSL接続
;;   1 : サーバの証明書が「無し」か「ありで検証OK」のときだけSSL接続
;;   2 : サーバの証明書が「ありで検証OK」のときだけSSL接続
;;   3 : サーバが送ってきたものではなくローカルの証明書で検証OKのときだけSSL接続
(setq mew-ssl-verify-level 2)
;; ルート認証局の証明書のパス
(setq mew-ssl-cert-directory "\nCAfile=/usr/local/share/certs/ca-root-nss.crt")
;; IMAP over SSLを使う
(setq mew-imap-ssl t)
;; SMTP over SSLを使う
(setq mew-smtp-ssl t)
```

これで無事にGmailのメール送受信もできました。

※バージョンメモ

- FreeBSD 8.2-RELEASE
- emacs-23.3_1,2
- mew-emacs23-6.3_2
- stunnel-4.35
- ca_root_nss-3.12.9
