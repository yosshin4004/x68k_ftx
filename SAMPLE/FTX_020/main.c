/*
	FTX 利用サンプルプログラム

	スプライト PCG データをフォント PCG にオンザフライで変換して利用します。
*/

#include <stdio.h>
#include <stdlib.h>
#include <doslib.h>
#include <iocslib.h>
#include "../../FTX/FTX2lib.H"

/* フォント PCG パターン最大使用数 */
#define	FNT_MAX		256

/* フォント PCG データファイル読み込みバッファ */
char fnt_pcg_dat[FNT_MAX * 128];

/* スプライト PCG データファイル読み込みバッファ */
char sp_pcg_dat[FNT_MAX * 128];

/* パレットデータファイル読み込みバッファ */
unsigned short pal_dat[256];


void main()
{
	int		i;
	FILE	*fp;

	/* 256x256dot 16色 グラフィックプレーン4枚 31KHz */
	CRTMOD(6);

	/* カーソル表示 OFF */
	B_CUROFF();

	/* スプライト PCG データ読み込み */
	fp = fopen("FONT.SP", "rb");
	if (fp == NULL) return;
	fread(
		sp_pcg_dat,
		128,		/* 1PCG = 128byte */
		256,		/* 256PCG */
		fp
	);
	fclose(fp);

	/* スプライトパレットデータ読み込み */
	fp = fopen("FONT.PAL", "rb");
	if (fp == NULL) return;
	fread(
		pal_dat,
		2,			/* 1color = 2byte */
		256,		/* 16color * 16block */
		fp
	);
	fclose(fp);

	/* スプライト PCG -> フォント PCG 変換 */
	for (i = 0; i < 256; i++) {
		ftx_fnt16_cnv(&sp_pcg_dat[i * 128], &fnt_pcg_dat[i * 128]);
	}

	/* スプライトパレット #1 をテキストパレットに転送 */
	for (i = 0; i < 16; i++) {
		ftx_palette_set(i, pal_dat[i + 16]);
	}

	/* フォント PCG データを指定 */
	ftx_pcgdat_set(fnt_pcg_dat);

	/* フォント描画 */
#if 1
	for (i = 0; i < 256; i++) {
		int x = i & 15;
		int y = i >> 4;
		ftx_fnt16_put(x, y, i);
	}
#else
	/*
		上記と同じ描画結果を 8x8 ドットフォントで描く場合、
		以下のようになる。
	*/
	for (i = 0; i < 256; i++) {
		int x = i & 15;
		int y = i >> 4;
		ftx_fnt8_put(x * 2    , y * 2    , i * 4    );
		ftx_fnt8_put(x * 2    , y * 2 + 1, i * 4 + 1);
		ftx_fnt8_put(x * 2 + 1, y * 2    , i * 4 + 2);
		ftx_fnt8_put(x * 2 + 1, y * 2 + 1, i * 4 + 3);
	}
#endif

	/* 何かキーを押すまでループ */
	while (INPOUT(0xFF) == 0) {}

	/*
		テキスト画面クリア。
		これをやらないと、プログラム終了後もテキスト画面上に
		描画結果が残ってしまう。
	*/
	ftx_clr();

	/* 画面モードを戻す */
	CRTMOD(0x10);
}

