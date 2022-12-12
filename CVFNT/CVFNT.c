/*
	FTX 対応 スプライト PCG → フォントデータ変換ツール
*/

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../FTX/FTX2lib.H"


static void
SpritePcgToFontPcg(
	const	void	*pSrcPcg,
			void	*pDstPcg
){
	int x, y;
	const uint8_t *pU8SrcPcg = (const uint8_t *)pSrcPcg;
	uint16_t *pS16DstPcg = (uint16_t *)pDstPcg;

#if 0
/* ナイーブ実装 */
	for (y = 0; y < 16; y++) {
		pS16DstPcg[y     ] = 0;
		pS16DstPcg[y + 16] = 0;
		pS16DstPcg[y + 32] = 0;
		pS16DstPcg[y + 48] = 0;

		for (x = 0; x < 8; x += 2) {
			int tmp0 = * pU8SrcPcg;
			int tmp1 = *(pU8SrcPcg + 64);
			pU8SrcPcg++;

			pS16DstPcg[y     ] |= ((tmp0      & 1) / 1) << (15 - (x + 1));
			pS16DstPcg[y + 16] |= ((tmp0      & 2) / 2) << (15 - (x + 1));
			pS16DstPcg[y + 32] |= ((tmp0      & 4) / 4) << (15 - (x + 1));
			pS16DstPcg[y + 48] |= ((tmp0      & 8) / 8) << (15 - (x + 1));

			pS16DstPcg[y     ] |= ((tmp0 / 16 & 1) / 1) << (15 - (x + 0));
			pS16DstPcg[y + 16] |= ((tmp0 / 16 & 2) / 2) << (15 - (x + 0));
			pS16DstPcg[y + 32] |= ((tmp0 / 16 & 4) / 4) << (15 - (x + 0));
			pS16DstPcg[y + 48] |= ((tmp0 / 16 & 8) / 8) << (15 - (x + 0));

			pS16DstPcg[y     ] |= ((tmp1      & 1) / 1) << (15 - (x + 9));
			pS16DstPcg[y + 16] |= ((tmp1      & 2) / 2) << (15 - (x + 9));
			pS16DstPcg[y + 32] |= ((tmp1      & 4) / 4) << (15 - (x + 9));
			pS16DstPcg[y + 48] |= ((tmp1      & 8) / 8) << (15 - (x + 9));

			pS16DstPcg[y     ] |= ((tmp1 / 16 & 1) / 1) << (15 - (x + 8));
			pS16DstPcg[y + 16] |= ((tmp1 / 16 & 2) / 2) << (15 - (x + 8));
			pS16DstPcg[y + 32] |= ((tmp1 / 16 & 4) / 4) << (15 - (x + 8));
			pS16DstPcg[y + 48] |= ((tmp1 / 16 & 8) / 8) << (15 - (x + 8));
		}
	}
#else
/* 最適化実装 */
	#if 0
	/* C 実装 */
	for (y = 0; y < 16; y++) {
		pS16DstPcg[y     ] = 0;
		pS16DstPcg[y + 16] = 0;
		pS16DstPcg[y + 32] = 0;
		pS16DstPcg[y + 48] = 0;

		for (x = 0; x < 8; x += 2) {
			int tmp0 = * pU8SrcPcg;
			int tmp1 = *(pU8SrcPcg + 64);
			pU8SrcPcg++;

			{
				unsigned int tmp01 = (tmp0 << 8) | tmp1;

				unsigned int tmp = tmp01 << (6 - x);
				unsigned short mask = 0x0101 << (6 - x);
				pS16DstPcg[y     ] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 16] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 32] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 48] |= (tmp       & mask);

				mask <<= 1;
				pS16DstPcg[y     ] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 16] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 32] |= (tmp       & mask);
				tmp >>= 1;
				pS16DstPcg[y + 48] |= (tmp       & mask);
			}
		}
	}
	#else
	/* asm 実装 */
	ftx_fnt16_cnv(pU8SrcPcg, pS16DstPcg);
	#endif
#endif
}

static bool
FtxConverter(
	const char *pszInputFileName,
	const char *pszOutputFileName
){
	size_t srcFileSize;
	size_t dstFileSize;
	int nPcg;
	FILE *pSrcFile;
	FILE *pDstFile;

	/* ソースファイルを開く */
	pSrcFile = fopen(pszInputFileName, "rb");
	if (pSrcFile == NULL) {
		printf("%s が開けません。\n", pszInputFileName);
		return false;
	}

	/* デスティネーションファイルを開く */
	pDstFile = fopen(pszOutputFileName, "wb");
	if (pDstFile == NULL) {
		printf("%s が開けません。\n", pszOutputFileName);
		return false;
	}

	/* ソースファイルのサイズを調べる */
	fseek(pSrcFile, 0, SEEK_END);
	srcFileSize = ftell(pSrcFile);
	fseek(pSrcFile, 0, SEEK_SET);

	/* ソースファイルのサイズから PCG 枚数と、デスティネーションファイルサイズを決定 */
	nPcg = srcFileSize / 128;
	dstFileSize = nPcg * 128;

	/* コンバート */
	{
		int i = 0;
		for (i = 0; i < nPcg; i++) {
			static int8_t srcBuffer[128];
			static int8_t dstBuffer[128];
			int ret;

			/* ソースファイルの読み込み */
			ret = fread(srcBuffer, 1, 128, pSrcFile);
			if (ret != 128) {
				printf("ファイルリードエラー。\n");
				return false;
			}

			/* PCG の変換 */
			SpritePcgToFontPcg(srcBuffer, dstBuffer);

			/* デスティネーションファイルの書き込み */
			ret = fwrite(dstBuffer, 1, 128, pDstFile);
			if (ret != 128) {
				printf("ファイルライトエラー。\n");
				return false;
			}
		}
	}

	/* 経過報告 */
	printf("%d PCG 変換しました。\n", nPcg);

	/* ファイルを閉じる */
	fclose(pDstFile);
	fclose(pSrcFile);

	/* 正常終了 */
	return true;
}


int
main(
	int		argc,
	char	**argv
){
	const	char	*pszInputFileName = NULL;
	const	char	*pszOutputFileName = NULL;

	/* 引数なしで起動した場合はヘルプを表示して終了 */
	if (argc == 1) {
		printf(
			"\n"
			"[remarks]\n"
			"	X680x0 のスプライトデータ（*.sp）を元に、\n"
			"	FTX 用フォント PCG ファイルを生成します。\n"
			"\n"
			"[parameters]\n"
			"	-i 入力ファイル名 \n"
			"		入力ファイル名を指定する。\n"
			"	-o 出力ファイル名 \n"
			"		出力ファイル名を指定する。\n"
			"\n"
		);

		/* 正常終了 */
		return 0;
	}

	/* 引数解析 */
	{
		int iArg = 1;
		while (iArg < argc) {
			if (strcmp(argv[iArg], "-i") == 0) {
				if (iArg + 1 >= argc) {
					printf("引数指定が不足しています。\n");

					/* 異常終了 */
					return 1;
				}
				pszInputFileName = argv[iArg + 1];
				iArg++;		/* 引数をスキップ */
			} else
			if (strcmp(argv[iArg], "-o") == 0) {
				if (iArg + 1 >= argc) {
					printf("引数指定が不足しています。\n");

					/* 異常終了 */
					return 1;
				}
				pszOutputFileName = argv[iArg + 1];
				iArg++;		/* 引数をスキップ */
			} else {
				printf("引数指定が不正です。\n");

				/* 異常終了 */
				return 1;
			}

			/* 次の要素へ */
			iArg++;
		}
	}

	/* スイッチ指定が不十分か不正ならエラーメッセージを出力して終了 */
	if (pszInputFileName == NULL) {
		printf("	入力ファイル名が指定されていません。\n");

		/* 異常終了 */
		return 1;
	}
	if (pszOutputFileName == NULL) {
		printf("	出力ファイル名が指定されていません。\n");

		/* 異常終了 */
		return 1;
	}

	/* 解析結果を表示 */
	if (1) {
		printf(
			"引数解析結果\n"
			"	-i %s\n"
			"	-o %s\n",
			pszInputFileName,
			pszOutputFileName
		);
	}

	/* コンバート処理本体に飛ぶ */
	if (
		FtxConverter(
			pszInputFileName,
			pszOutputFileName
		) == false
	) {
		/* 異常終了 */
		printf("異常終了\n");
		return 1;
	}

	/* 正常終了 */
	printf("正常終了\n");
	return 0;
}

