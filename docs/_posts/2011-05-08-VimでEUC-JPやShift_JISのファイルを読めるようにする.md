---
title: "VimでEUC-JPやShift_JISのファイルを読めるようにする"
category: Unixで日本語
---

ロケールのコードセットをeucJPからUTF-8に変えたので、VimでEUC-JPやShift_JISのファイルを開くと文字化けするようになりました。

Vimは、内部処理に用いるエンコーディング(encoding)とは別に、ファイルを読み書きするときに試すエンコーディング(fileencodings)を複数設定できるようになっています。

:setで見てみると、デフォルトでは

```viml
fileencodings=ucs-bom,utf-8,default,latin1
```

となっています。Vimは、ここに列挙されたエンコーディングを左から順番に試し、エラーが出なかったものを採用するとのこと。そこで、~/.vimrcに下記の行を追加することで、ISO-2022-JP、EUC-JP、Shift_JISの自動判定ができるようになります。

```viml
set fileencodings=iso-2022-jp,euc-jp,cp932,ucs-bom,utf-8,default,latin1
```

sjisではなくcp932を使っているのは、Windowsの機種依存文字(丸付き数字とか、全角1文字のTELとか)があっても変換できるようにするためです。

※バージョンメモ

- FreeBSD 8.2-RELEASE
- vim-7.3.121
- libiconv-1.13.1_1
