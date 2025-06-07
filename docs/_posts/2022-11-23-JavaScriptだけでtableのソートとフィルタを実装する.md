---
title: "JavaScriptだけでtableのソートとフィルタを実装する"
categories: ウェブ プログラミング
seo:
  date_modified: 2025-03-02 00:00:00 +0900
last_modified_at: 2025-03-02 00:00:00 +0900
---

HTMLのtableのソートとフィルタの機能をJavaScriptだけで書いてみたら、思ってたより100億倍簡単だった。なんかいろいろ使いまわせそうなので、メモ。

## やりたいこと

- 列見出しを押したら、その列で昇順にソートする
- 同じ列見出しをもう一回押したら、今度は降順にソートする
- ソートしてる列見出しの末尾に「🔼」(昇順)、「🔽」(降順)のマークを付ける
- テキストボックスに入力した正規表現に合致する行だけをフィルタする
- フィルタは、テキストボックスのEnterキーか、検索ボタン押下で発動させる
- リセットボタンを押したらフィルタを解除する
- 使うのはJavaScriptのみ (jQueryなど、他のライブラリは一切使わない)

実際どんな動きになるかは、「[Software Design 2018-01～2025-07 総目次](resources/software-design-index.html)」を触って確かめてみてちょ。

## ソート処理

thがクリックされたら、sortRows()が呼ばれるようにしておく。

```javascript
document.querySelectorAll('th').forEach(th => th.onclick = sortRows);
```

sortRows()の中では、まずtableの各行から「その行への参照」と「クリックされた列の値」をセットにしたレコードオブジェクトを作って、ソート用の配列にぶち込む。

```javascript
function sortRows() {
  const table = document.querySelector("table");
  const records = [];
  for (let i = 1; i < table.rows.length; i++) {
    const record = {};
    record.row = table.rows[i];
    record.key = table.rows[i].cells[this.cellIndex].textContent;
    records.push(record);
  }
```

で、そのソート用配列をソートする。

```javascript
  records.sort(compareKeys);
```

Arrayのsort()の引数に渡しているのは、別に定義しておいたキー比較関数(コンパレータ)への参照。こいつは、レコードオブジェクトからソート用の値を取り出して、どっちが大きいか比較した結果を返すようにしておく。Arrayのsort()は、この結果を使って全体をソートしてくれる。

```javascript
function compareKeys(a, b) {
  if (a.key < b.key) return -1;
  if (a.key > b.key) return 1;
  return 0;
}
```

ソートが終わったら、ソート後の順番で行をtableに書き戻す。appendChild()は、対象がすでにtableの子要素だった場合、removeしてからappendしてくれるので、結果的に行が「移動」することになる。

```javascript
  for (let i = 0; i < records.length; i++) {
    table.appendChild(records[i].row);
  }
```

ソートの骨格は以上。簡単ですな。

ソート列の見出しに「🔼」マークを付けるのは、CSSで「sort-ascクラスだったら末尾に🔼を表示する」ようにしておき、

```css
th.sort-asc::after {
  content: '🔼';
}
```

さっきのsortRec()の中で、いったん全thのCSSクラスを綺麗にしてから、今回クリックされたthだけにsort-ascクラスを追加する。

```javascript
  document.querySelectorAll('th').forEach(th => {
    th.classList.remove('sort-asc');
  });
  this.classList.add('sort-asc');
```

さて、ここまでだと昇順ソートにしか対応してないので、降順ソートもできるようにしておこう。

降順ソートは、降順用のコンパレータを用意しておいて(昇順用とは1と-1が逆になってる)、

```javascript
function compareKeysReverse(a, b) {
  if (a.key < b.key) return 1;
  if (a.key > b.key) return -1;
  return 0;
}
```

Arrayのsort()の引数に渡すコンパレータをこっちに変えればいいだけ。

```javascript
  records.sort(compareKeysReverse);
```

実際には昇順か降順かの分岐が必要なので、クリックされたthのCSSクラスがsort-ascのときは降順、そうでなければ昇順でソートすることにする。CSSクラスを状態の保持場所として使えば、JavaScript側では状態を持つ必要がなくて便利なのん。

```javascript
  if (this.classList.contains('sort-asc')) {
    records.sort(compareKeysReverse);
    purgeSortMarker();
    this.classList.add('sort-desc');
  } else {
    records.sort(compareKeys);
    purgeSortMarker();
    this.classList.add('sort-asc');
  }
```

purgeSortMarker()は、全thのCSSクラスを削除する処理を外出ししたもの(昇順のときも降順のときも必要だから括り出した)。

```javascript
function purgeSortMarker() {
  document.querySelectorAll('th').forEach(th => {
    th.classList.remove('sort-asc');
    th.classList.remove('sort-desc');
  });
}
```

降順のときthに設定しているCSSクラスのsort-descは、もちろん見出しに「🔽」を付けるためのもの。

```css
th.sort-desc::after {
  content: '🔽';
}
```

ソート周りはこれで完成。tableが2つ以上ある場合は、セレクタでCSSクラスを指定するなど、適宜アレンジしてください。

ちなみに、数字列を文字コード順 (1→10→11→2) じゃなくて数値としてソートしたい (1→2→10→11) 場合は、コンパレータで連続する数字 (`/(\d)+/`) の頭に0をパディングしてから大小比較すると簡単。例えば、最大10桁を想定するならこんな感じ。

```javascript
  function compareKeys(a, b) {
    const a_mod = a.key.replace(/(\d)+/g, m => m.padStart(10, '0'));
    const b_mod = b.key.replace(/(\d)+/g, m => m.padStart(10, '0'));
    return a_mod < b_mod ? -1 : a_mod > b_mod ? 1 : 0;
  }

  function compareKeysReverse(a, b) {
    const a_mod = a.key.replace(/(\d)+/g, m => m.padStart(10, '0'));
    const b_mod = b.key.replace(/(\d)+/g, m => m.padStart(10, '0'));
    return a_mod < b_mod ? 1 : a_mod > b_mod ? -1 : 0;
  }
```

## フィルタ処理

tableタグの前に、inputタグをひとつと、buttonタグをふたつ、用意しておく。ここではJavaScriptで生成して挿入しているが(これは、JavaScriptオフの環境で表示されないようにするため。JS動かないのにボタンだけあっても意味ないからね…)、もちろんHTMLに直接inputタグとbuttonタグを書いてもOK。

```javascript
const table = document.querySelector('table');
const tableParent = table.parentElement;

const input = document.createElement('input');
tableParent.insertBefore(input, table);

const searchButton = document.createElement('button');
searchButton.textContent = '正規表現で検索';
tableParent.insertBefore(searchButton, table);

const resetButton = document.createElement('button');
resetButton.textContent = '全て表示';
tableParent.insertBefore(resetButton, table);
```

inputでEnterが押されたら、filterRows()が呼ばれるようにしておく。

```javascript
input.addEventListener('keypress', () => {
  if (event.key === 'Enter') filterRows();
});
```

searchButtonが押された時も、filterRows()が呼ばれるようにしておく。

```javascript
searchButton.onclick = filterRows;
```

filterRows()の中では、まずinputタグの入力を取り出して、正規表現オブジェクトを作成する。第2引数の'i'は、大文字と小文字を区別しない設定。

```javascript
function filterRows() {
  const keyword = document.querySelector('input').value;
  const regex = new RegExp(keyword, 'i');
```

次に、tableの各行を取り出し、いったん非表示にする。

```javascript
  for (let i = 1; i < table.rows.length; i++) {
    const row = table.rows[i];
    row.style.display = 'none';
```

最後に、その行の各列の値を正規表現と比較し、1つでもマッチしたら、その行が表示されるようにする。

```javascript
    for (let j = 0; j < row.cells.length; j++) {
      if (row.cells[j].textContent.match(regex)) {
        row.style.display = 'table-row';
        break;
      }
    }
  }
```

resetButtonは、押されたらresetFilter()が呼ばれるようにしておき、

```javascript
resetButton.onclick = resetFilter;
```

resetFilter()の中ではinputの中身をクリアしてfilterRows()を呼ぶ。

```javascript
function resetFilter() {
  document.querySelector('input').value = '';
  filterRows();
}
```

これだけで、フィルタ処理も完成です。うーん、簡単!

## 最終形

使いまわし用として、そのまま使えるHTMLとしても貼っておく。tableひとつだけでいいなら、このままtableタグの中身だけ書き換えれば、たぶん使えるんじゃないっすかね。

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>タイトル</title>
    <style>
      button {
        margin: 0 0 1em 0.5em;
      }
      table {
        border-collapse: collapse;
      }
      th {
        color: white;
        background: navy;
        cursor: pointer;
      }
      th.sort-asc::after {
        content: '🔼';
      }
      th.sort-desc::after {
        content: '🔽';
      }
      td {
        padding: 0 0.3em;
        border-bottom: 1px solid lightgray;
        vertical-align: top;
      }
    </style>
  </head>

  <body>
    <h1>タイトル</h1>
    <table>
      <tr><th>見出し1</th><th>見出し2</th><th>見出し3</th></tr>
      <tr><td>あああ</td><td>CCC</td><td>333</td></tr>
      <tr><td>いいい</td><td>BBB</td><td>111</td></tr>
      <tr><td>ううう</td><td>AAA</td><td>222</td></tr>
    </table>

    <script>
      initialize();

      function initialize() {
        const table = document.querySelector('table');
        const tableParent = table.parentElement;

        const input = document.createElement('input');
        input.addEventListener('keypress', () => {
          if (event.key === 'Enter') filterRows();
        });
        tableParent.insertBefore(input, table);

        const searchButton = document.createElement('button');
        searchButton.textContent = '正規表現で検索';
        searchButton.onclick = filterRows;
        tableParent.insertBefore(searchButton, table);

        const resetButton = document.createElement('button');
        resetButton.textContent = '全て表示';
        resetButton.onclick = resetFilter;
        tableParent.insertBefore(resetButton, table);

        document.querySelectorAll('th').forEach(th => th.onclick = sortRows);
        document.querySelector('th').classList.add('sort-asc');
      }

      function filterRows() {
        const keyword = document.querySelector('input').value;
        const regex = new RegExp(keyword, 'i');
        const table = document.querySelector('table');
        for (let i = 1; i < table.rows.length; i++) {
          const row = table.rows[i];
          row.style.display = 'none';
          for (let j = 0; j < row.cells.length; j++) {
            if (row.cells[j].textContent.match(regex)) {
              row.style.display = 'table-row';
              break;
            }
          }
        }
      }

      function resetFilter() {
        document.querySelector('input').value = '';
        filterRows();
      }

      function sortRows() {
        const table = document.querySelector("table");
        const records = [];
        for (let i = 1; i < table.rows.length; i++) {
          const record = {};
          record.row = table.rows[i];
          record.key = table.rows[i].cells[this.cellIndex].textContent;
          records.push(record);
        }
        if (this.classList.contains('sort-asc')) {
          records.sort(compareKeysReverse);
          purgeSortMarker();
          this.classList.add('sort-desc');
        } else {
          records.sort(compareKeys);
          purgeSortMarker();
          this.classList.add('sort-asc');
        }
        for (let i = 0; i < records.length; i++) {
          table.appendChild(records[i].row);
        }
      }

      function purgeSortMarker() {
        document.querySelectorAll('th').forEach(th => {
          th.classList.remove('sort-asc');
          th.classList.remove('sort-desc');
        });
      }

      function compareKeys(a, b) {
        if (a.key < b.key) return -1;
        if (a.key > b.key) return 1;
        return 0;
      }

      function compareKeysReverse(a, b) {
        if (a.key < b.key) return 1;
        if (a.key > b.key) return -1;
        return 0;
      }
    </script>
  </body>
</html>
```

※更新履歴

- 2024-02-19 ソート順の↓↑を🔼🔽に変更、フィルタのリセットボタンを追加、inputとbuttonのinsert先をtableの親elementに変更
- 2025-03-02 数字列を数値としてソートする方法を追記
