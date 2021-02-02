/*
	FTX 利用サンプルプログラム

	FTX を利用して、文字列を print します。
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

/* パレットデータファイル読み込みバッファ */
unsigned short pal_dat[256];


void ftx_puts(
	short x,
	short y,
	const char *msg
){
	int x0 = x;
	while (*msg != '\0') {
		ftx_fnt8_put(x, y, *msg);
		x++;
		if (*msg == '\n') {
			x = x0;
			y++;
		}
		msg++;
	}
}

void main()
{
	int		i;
	FILE	*fp;

	/* 256x256dot 16色 グラフィックプレーン4枚 31KHz */
	CRTMOD(6);

	/* カーソル表示 OFF */
	B_CUROFF();

	/* フォント PCG データ読み込み */
	fp = fopen("FONT.FNT", "rb");
	if (fp == NULL) return;
	fread(
		fnt_pcg_dat,
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

	/* スプライトパレット #1 をテキストパレットに転送 */
	for (i = 0; i < 16; i++) {
		ftx_palette_set(i, pal_dat[i + 16]);
	}

	/* フォント PCG データを指定 */
	ftx_pcgdat_set(fnt_pcg_dat);

	/* 何かキーを押すまでループ */
	{
		int count = 0;
		while (INPOUT(0xFF) == 0) {
			char msg[256];
			sprintf(
				msg,
				"ftx test\n"
				"\n"
				"count %08X",
				count
			);
			ftx_puts(0, 0, msg);
			count++;
		}
	}

	/*
		テキスト画面クリア。
		これをやらないと、プログラム終了後もテキスト画面上に
		描画結果が残ってしまう。
	*/
	ftx_clr();

	/* 画面モードを戻す */
	CRTMOD(0x10);
}

