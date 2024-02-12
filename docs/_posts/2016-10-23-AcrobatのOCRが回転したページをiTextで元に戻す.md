---
title: "AcrobatのOCRが回転したページをiTextで元に戻す"
category: 本
---

ドキュメントスキャナでPDF化(いわゆる自炊)した本にAdobe AcrobatでOCRをかけると、勝手にページが回転されてしまうことがあります。たとえば縦書きの本で横文字がたくさん出てくるページとか、図表のページとか、よくわからないけどAcrobatさんが誤認識したページとか。私の場合、できれば回転方法はオリジナルと同じに戻したいと思っていたのですが、回転されたページをいちいち目検で見つけ出して手動補正するのも大変なので、そのままにしていました。

が、JavaでPDFを操作するフリーのライブラリ「iText」を使えば簡単に自動補正できることが分かったので、メモしておきます。

PDFの各ページの現状の回転方向を取得するには、PdfReaderクラスのgetPageRotation()を使います。たとえば、引数で指定したPDFファイルの各ページの回転方向を一覧表示させるならこんな感じ。ちなみに、PDFのページ数は0からではなく1から始まります。

```java
import java.io.IOException;

import com.itextpdf.text.pdf.PdfReader;

public class PdfPageRotationLister {
    public static void main(String[] args) throws IOException {
        PdfReader reader = new PdfReader(args[0]);
        for (int page = 1; page <= reader.getNumberOfPages(); page++) {
            int rotation = reader.getPageRotation(page);
            System.out.println(String.format("%d頁: %d度", page, rotation));
        }
        reader.close();
    }
}
```

回転方向は角度で表され、0、90、180、270のいずれかの値になります。実行結果のサンプルはこちら。

```console
1頁: 0度
2頁: 90度
3頁: 180度
4頁: 270度
```

回転方向を明示的にセットするには、getPageN()でそのページの属性の集合体(PdfDictionary型)を取り出して、「/Rotate」の値を書き換えます。もし、回転方向をすべて0度にリセットするとしたら、このような感じになります。補正後のPDFはPdfStamperを使って"out.pdf"に書き出しています。

```java
import java.io.FileOutputStream;
import java.io.IOException;

import com.itextpdf.text.DocumentException;
import com.itextpdf.text.pdf.PdfDictionary;
import com.itextpdf.text.pdf.PdfName;
import com.itextpdf.text.pdf.PdfNumber;
import com.itextpdf.text.pdf.PdfReader;
import com.itextpdf.text.pdf.PdfStamper;

public class PdfPageRotationResetter {
    public static void main(String[] args) throws IOException, DocumentException {
        PdfReader reader = new PdfReader(args[0]);
        for (int page = 1; page <= reader.getNumberOfPages(); page++) {
            PdfDictionary dict = reader.getPageN(page);
            dict.put(PdfName.ROTATE, new PdfNumber(0));
        }
        PdfStamper stamper = new PdfStamper(reader, new FileOutputStream("out.pdf"));
        stamper.close();
        reader.close();
    }
}
```

これを組み合わせると、OCR前のオリジナルPDF(第1引数)とOCR後のPDF(第2引数)を指定し、回転方向をオリジナルと同じに補正することができます。

```java
import java.io.FileOutputStream;
import java.io.IOException;

import com.itextpdf.text.DocumentException;
import com.itextpdf.text.pdf.PdfDictionary;
import com.itextpdf.text.pdf.PdfName;
import com.itextpdf.text.pdf.PdfNumber;
import com.itextpdf.text.pdf.PdfReader;
import com.itextpdf.text.pdf.PdfStamper;

public class PdfPageRotationCopier {
    public static void main(String[] args) throws IOException, DocumentException {
        PdfReader original = new PdfReader(args[0]);
        PdfReader ocr = new PdfReader(args[1]);
        boolean modified = false;
        for (int page = 1; page <= ocr.getNumberOfPages(); page++) {
            int originalRotation = original.getPageRotation(page);
            int ocrRotation = ocr.getPageRotation(page);
            if (originalRotation != ocrRotation) {
                PdfDictionary dict = ocr.getPageN(page);
                dict.put(PdfName.ROTATE, new PdfNumber(originalRotation));
                modified = true;
            }
        }
        if (modified) {
            PdfStamper stamper = new PdfStamper(ocr, new FileOutputStream("ocr_modified.pdf"));
            stamper.close();
        }
        ocr.close();
        original.close();
    }
}
```

※バージョンメモ

- JDK 1.8.0_111
- iText 5.5.10
