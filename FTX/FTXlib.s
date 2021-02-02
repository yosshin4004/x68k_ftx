*==========================================================================
*                 テキストプレーンフォント表示システム FTX
*                          ver 2.01     by よっしん
*==========================================================================

	.globl	_ftx_pcgdat_set
	.globl	_ftx_fnt8_put
	.globl	_ftx_fnt16_put
	.globl	_ftx_clr
	.globl	_ftx_scroll_set
	.globl	_ftx_palette_set
	.globl	_ftx_fnt16_cnv


	.include doscall.mac
	.include iocscall.mac


*==========================================================================
*
*	スタックフレームの作成
*
*==========================================================================

	.offset 0

arg1_l	ds.b	2
arg1_w	ds.b	1
arg1_b	ds.b	1

arg2_l	ds.b	2
arg2_w	ds.b	1
arg2_b	ds.b	1

arg3_l	ds.b	2
arg3_w	ds.b	1
arg3_b	ds.b	1

arg4_l	ds.b	2
arg4_w	ds.b	1
arg4_b	ds.b	1

arg5_l	ds.b	2
arg5_w	ds.b	1
arg5_b	ds.b	1

arg6_l	ds.b	2
arg6_w	ds.b	1
arg6_b	ds.b	1


	.text
	.even


*==========================================================================
*
* 書式：
*	void ftx_pcgdat_set(short *pcg_dat);
*
* 引数：
*	pcg_dat :
*		CVFNT.x で作成したフォント PCG データのポインタ。
*
*==========================================================================

_ftx_pcgdat_set

A7ID	=	4			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	A7ID+arg1_l(sp),pcg_adr	* PCG アドレス
	rts



*==========================================================================
*
* 書式：
*	void ftx_fnt8_put(short x, short y, short cd);
*
* 引数：
*	x :
*		表示先 x 座標（0～127）
*	y :
*		表示先 y 座標（0～127）
*	cd :
*		表示するテキスト PCG ナンバー（0～65535）
*
*==========================================================================

_ftx_fnt8_put

A7ID	=	4			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	*=====[ スーパーバイザモードへ ]
		suba.l	a1,a1
		iocs	_B_SUPER	* スーパーバイザモードへ
		move.l	d0,usp_bak	* 元々スーパーバイザモードの場合は d0.l=-1


	*=====[ 初期アドレス計算 ]
		*-----[ GET アドレス ]
						* パターン配列は bg_put コンパチとする

		move.l	A7ID+arg3_l(sp),d0	* d0.l = パターンコード
		move.w	d0,d1			* d1.w = d0 (バックアップ)

		lsr.l	#2,d0			* d0.l = パターンコード / 4
		lsl.l	#7,d0			* d0.l = (パターンコード / 4) * 128

		andi.w	#3,d1			* d1.w = パターンコード & 3
		lsl.w	#4,d1			* d1.w = (パターンコード & 3) * 16

		cmpi.w	#32,d1
		blt.b	@F			* 32 > d1 なら bra
			subi.w	#31,d1
		@@:

		movea.l	pcg_adr(pc),a0		* a0.l = PCG データのアドレス
		adda.l	d0,a0			* a0.l += d0.l
		adda.w	d1,a0			* a0.l += d1.w
						* a0.l = PCG 読み出し開始アドレス

		*-----[ PUT アドレス ]
		movea.l	#$E00000,a1		* a1.l = T0 の 開始アドレス
		move.w	A7ID+arg1_w(sp),d0	* d0.w = x
		andi.w	#127,d0			* d0.w = x & 127
		adda.w	d0,a1			* a1.l += d0.w

		move.w	A7ID+arg2_w(sp),d0	* d0.w = y
		andi.l	#127,d0			* d0.l = y & 127
						*	PCG 1 個で Y 方向 8 ドット
						*	TEXT 上の Y 方向 1 ドットあたり 128 バイト
						*	8 * 128 = 1 << 10 なので、10 ビットの左シフトが必要。
						*	ロングサイズの 10 ビットの左シフトは
						*	8+2n = 28 クロックかかる。
						*	しかし swap と右 6 ビットシフト併用した方が高速で、
						*	合計 4+20 = 24 クロックで済む。
		swap	d0			* 4 クロック
		lsr.l	#6,d0			* 8+2n (=20 クロック)
		adda.l	d0,a1			* a1.l += d0.l
						* a1.l = TEXT 上の PUT 先アドレス


	*=====[ FONT PUT ]
						* a0.l = PCG 読み出し開始アドレス
						* a1.l = TEXT 上の PUT 先アドレス

		move.l	#$20000,d0		* d0.l = TEXT プレーンのストライド

		*-----[ T0 ]
		move.b	  (a0),(a1)		* 1 ライン目
		move.b	 2(a0),$80(a1)		* 2 ライン目
		move.b	 4(a0),$100(a1)		* 3 ライン目
		move.b	 6(a0),$180(a1)		* 4 ライン目
		move.b	 8(a0),$200(a1)		* 5 ライン目
		move.b	10(a0),$280(a1)		* 6 ライン目
		move.b	12(a0),$300(a1)		* 7 ライン目
		move.b	14(a0),$380(a1)		* 8 ライン目
		lea	$20(a0),a0		* 次のプレーンの PCG アドレスへ
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T1 ]
		move.b	  (a0),(a1)		* 1 ライン目
		move.b	 2(a0),$80(a1)		* 2 ライン目
		move.b	 4(a0),$100(a1)		* 3 ライン目
		move.b	 6(a0),$180(a1)		* 4 ライン目
		move.b	 8(a0),$200(a1)		* 5 ライン目
		move.b	10(a0),$280(a1)		* 6 ライン目
		move.b	12(a0),$300(a1)		* 7 ライン目
		move.b	14(a0),$380(a1)		* 8 ライン目
		lea	$20(a0),a0		* 次のプレーンの PCG アドレスへ
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T2 ]
		move.b	  (a0),(a1)		* 1 ライン目
		move.b	 2(a0),$80(a1)		* 2 ライン目
		move.b	 4(a0),$100(a1)		* 3 ライン目
		move.b	 6(a0),$180(a1)		* 4 ライン目
		move.b	 8(a0),$200(a1)		* 5 ライン目
		move.b	10(a0),$280(a1)		* 6 ライン目
		move.b	12(a0),$300(a1)		* 7 ライン目
		move.b	14(a0),$380(a1)		* 8 ライン目
		lea	$20(a0),a0		* 次のプレーンの PCG アドレスへ
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T3 ]
		move.b	  (a0),(a1)		* 1 ライン目
		move.b	 2(a0),$80(a1)		* 2 ライン目
		move.b	 4(a0),$100(a1)		* 3 ライン目
		move.b	 6(a0),$180(a1)		* 4 ライン目
		move.b	 8(a0),$200(a1)		* 5 ライン目
		move.b	10(a0),$280(a1)		* 6 ライン目
		move.b	12(a0),$300(a1)		* 7 ライン目
		move.b	14(a0),$380(a1)		* 8 ライン目


	*=====[ ユーザーモードへ ]
		move.l	usp_bak(pc),d0
		bmi.b	@F			* ユーザーモードから実行されていたので戻す必要なし
			movea.l	d0,a1
			iocs	_B_SUPER	* ユーザーモードへ
		@@:


	*=====[ return ]
	rts



*==========================================================================
*
* 書式：
*	void ftx_fnt16_put(short x, short y, short cd);
*
* 引数：
*	x :
*		表示先 x 座標（0～63）
*	y :
*		表示先 y 座標（0～63）
*	cd :
*		表示するテキスト PCG ナンバー（0～65535）
*
*==========================================================================

_ftx_fnt16_put

A7ID	=	4			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	*=====[ スーパーバイザモードへ ]
		suba.l	a1,a1
		iocs	_B_SUPER	* スーパーバイザモードへ
		move.l	d0,usp_bak	* 元々スーパーバイザモードの場合は d0.l=-1


	*=====[ 初期アドレス計算 ]
		*-----[ GET アドレス ]
		move.l	A7ID+arg3_l(sp),d0	* d0.l = パターンコード
		lsl.l	#7,d0			* d0.l = パターンコード * 128
		movea.l	pcg_adr(pc),a0		* a0.l = PCG データのアドレス
		adda.l	d0,a0			* a0.l += d0.l
						* a0.l = PCG 読み出し開始アドレス

		*------[ PUT アドレス ]
		movea.l	#$E00000,a1		* a1.l = T0 の 開始アドレス
		move.w	A7ID+arg1_w(sp),d0	* d0.w = x
		andi.w	#63,d0			* d0.w = x & 63
		add.w	d0,d0			* d0.w = (x & 63) * 2
		adda.w	d0,a1			* a1.l += d0.w

		move.w	A7ID+arg2_w(sp),d0	* d0.w = y
		andi.l	#63,d0			* d0.l = y & 63
						*	PCG 1 個で Y 方向 16 ドット
						*	TEXT 上の Y 方向 1 ドットあたり 128 バイト
						*	16 * 128 = 1 << 11 なので、11 ビットの左シフトが必要。
						*	ロングサイズの 11 ビットの左シフトは
						*	8+2n = 30 クロックかかる。
						*	しかし swap と右 5 ビットシフト併用した方が高速で、
						*	合計 4+18 = 22 クロックで済む。
		swap	d0			* 4 クロック
		lsr.l	#5,d0			* 8+2n (=18 クロック)
		adda.l	d0,a1			* a1.l += d0.l
						* a1.l = TEXT 上の PUT 先アドレス


	*=====[ FONT PUT ]
						* a0.l = PCG 読み出し開始アドレス
						* a1.l = TEXT 上の PUT 先アドレス

		move.l	#$20000,d0		* d0.l = TEXT プレーンのストライド


		*-----[ T0 ]
		move.w	(a0)+,(a1)		*  1 ライン目
		move.w	(a0)+,$80(a1)		*  2 ライン目
		move.w	(a0)+,$100(a1)		*  3 ライン目
		move.w	(a0)+,$180(a1)		*  4 ライン目
		move.w	(a0)+,$200(a1)		*  5 ライン目
		move.w	(a0)+,$280(a1)		*  6 ライン目
		move.w	(a0)+,$300(a1)		*  7 ライン目
		move.w	(a0)+,$380(a1)		*  8 ライン目
		move.w	(a0)+,$400(a1)		*  9 ライン目
		move.w	(a0)+,$480(a1)		* 10 ライン目
		move.w	(a0)+,$500(a1)		* 11 ライン目
		move.w	(a0)+,$580(a1)		* 12 ライン目
		move.w	(a0)+,$600(a1)		* 13 ライン目
		move.w	(a0)+,$680(a1)		* 14 ライン目
		move.w	(a0)+,$700(a1)		* 15 ライン目
		move.w	(a0)+,$780(a1)		* 16 ライン目
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T1 ]
		move.w	(a0)+,(a1)		*  1 ライン目
		move.w	(a0)+,$80(a1)		*  2 ライン目
		move.w	(a0)+,$100(a1)		*  3 ライン目
		move.w	(a0)+,$180(a1)		*  4 ライン目
		move.w	(a0)+,$200(a1)		*  5 ライン目
		move.w	(a0)+,$280(a1)		*  6 ライン目
		move.w	(a0)+,$300(a1)		*  7 ライン目
		move.w	(a0)+,$380(a1)		*  8 ライン目
		move.w	(a0)+,$400(a1)		*  9 ライン目
		move.w	(a0)+,$480(a1)		* 10 ライン目
		move.w	(a0)+,$500(a1)		* 11 ライン目
		move.w	(a0)+,$580(a1)		* 12 ライン目
		move.w	(a0)+,$600(a1)		* 13 ライン目
		move.w	(a0)+,$680(a1)		* 14 ライン目
		move.w	(a0)+,$700(a1)		* 15 ライン目
		move.w	(a0)+,$780(a1)		* 16 ライン目
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T2 ]
		move.w	(a0)+,(a1)		*  1 ライン目
		move.w	(a0)+,$80(a1)		*  2 ライン目
		move.w	(a0)+,$100(a1)		*  3 ライン目
		move.w	(a0)+,$180(a1)		*  4 ライン目
		move.w	(a0)+,$200(a1)		*  5 ライン目
		move.w	(a0)+,$280(a1)		*  6 ライン目
		move.w	(a0)+,$300(a1)		*  7 ライン目
		move.w	(a0)+,$380(a1)		*  8 ライン目
		move.w	(a0)+,$400(a1)		*  9 ライン目
		move.w	(a0)+,$480(a1)		* 10 ライン目
		move.w	(a0)+,$500(a1)		* 11 ライン目
		move.w	(a0)+,$580(a1)		* 12 ライン目
		move.w	(a0)+,$600(a1)		* 13 ライン目
		move.w	(a0)+,$680(a1)		* 14 ライン目
		move.w	(a0)+,$700(a1)		* 15 ライン目
		move.w	(a0)+,$780(a1)		* 16 ライン目
		adda.l	d0,a1			* 次のプレーンの TEXT アドレスへ

		*-----[ T3 ]
		move.w	(a0)+,(a1)		*  1 ライン目
		move.w	(a0)+,$80(a1)		*  2 ライン目
		move.w	(a0)+,$100(a1)		*  3 ライン目
		move.w	(a0)+,$180(a1)		*  4 ライン目
		move.w	(a0)+,$200(a1)		*  5 ライン目
		move.w	(a0)+,$280(a1)		*  6 ライン目
		move.w	(a0)+,$300(a1)		*  7 ライン目
		move.w	(a0)+,$380(a1)		*  8 ライン目
		move.w	(a0)+,$400(a1)		*  9 ライン目
		move.w	(a0)+,$480(a1)		* 10 ライン目
		move.w	(a0)+,$500(a1)		* 11 ライン目
		move.w	(a0)+,$580(a1)		* 12 ライン目
		move.w	(a0)+,$600(a1)		* 13 ライン目
		move.w	(a0)+,$680(a1)		* 14 ライン目
		move.w	(a0)+,$700(a1)		* 15 ライン目
		move.w	(a0)+,$780(a1)		* 16 ライン目


	*=====[ ユーザーモードへ ]
		move.l	usp_bak(pc),d0
		bmi.b	@F			* ユーザーモードから実行されていたので戻す必要なし
			movea.l	d0,a1
			iocs	_B_SUPER	* ユーザーモードへ
		@@:

	*=====[ return ]
	rts



*==========================================================================
*
* 書式：void ftx_clr();
*
*==========================================================================

_ftx_clr

A7ID	=	4 + (5+4)*4		*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	movem.l	d3-d7/a3-a6,-(a7)	* レジスタ退避

	*=====[ スーパーバイザモードへ ]
		suba.l	a1,a1
		iocs	_B_SUPER	* スーパーバイザモードへ
		move.l	d0,usp_bak	* 元々スーパーバイザモードの場合は d0.l=-1

	*=====[ テキストクリア実行 ]
		move.w	$E8002A,CRTC_R21_bak		* CRTC_R21 現在値の退避
		move.w	#%00000001_1111_0000,$E8002A	* T0～T3 同時アクセス

		movea.l	#$E20000,a6			* a6.l = T0 の開始アドレス
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		suba.l	a0,a0
		suba.l	a1,a1
		suba.l	a2,a2
		suba.l	a3,a3
		suba.l	a4,a4
		suba.l	a5,a5
							* a0-d0/a0-a5 に 0 を格納した

		*-----[ 32768 ロングワードクリア ]
		move.w	#511,d0				* dbra カウンタ
	TCLR_LOOP:
		movem.l	d1-d7/a0-a5,-(a6)		* 13.l
		movem.l	d1-d7/a0-a5,-(a6)		* 13.l 合計 26.l
		movem.l	d1-d7/a0-a5,-(a6)		* 13.l 合計 39.l
		movem.l	d1-d7/a0-a5,-(a6)		* 13.l 合計 52.l
		movem.l	d1-d7/a0-a4,-(a6)		* 12.l 合計 64.l
		dbra	d0,TCLR_LOOP

		move.w	CRTC_R21_bak(pc),$E8002A	* CRTC_R21 現在値の復活

	*=====[ ユーザーモードへ ]
		move.l	usp_bak(pc),d0
		bmi.b	@F			* ユーザーモードから実行されていたので戻す必要なし
			movea.l	d0,a1
			iocs	_B_SUPER	* ユーザーモードへ
		@@:

	*=====[ return ]
	movem.l	(a7)+,d3-d7/a3-a6	* レジスタ復活

	rts



*==========================================================================
*
* 書式：
*	void ftx_scroll_set(short x, short y);
*
* 引数：
*	x :
*		X 座標（0～1023）
*	y :
*		Y 座標（0～1023）
*
*==========================================================================

_ftx_scroll_set

A7ID	=	4			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	*=====[ スーパーバイザモードへ ]
		suba.l	a1,a1
		iocs	_B_SUPER	* スーパーバイザモードへ
		move.l	d0,usp_bak	* 元々スーパーバイザモードの場合は d0.l=-1

	*=====[ テクストスクロールレジスタ書き込み ]
		move.w	A7ID+arg1_w(sp),$E80014
		move.w	A7ID+arg2_w(sp),$E80016

	*=====[ ユーザーモードへ ]
		move.l	usp_bak(pc),d0
		bmi.b	@F			* ユーザーモードから実行されていたので戻す必要なし
			movea.l	d0,a1
			iocs	_B_SUPER	* ユーザーモードへ
		@@:

	*=====[ return ]
	rts



*==========================================================================
*
* 書式：
*	void ftx_palette_set(short idx, short color);
*
* 引数：
*	idx :
*		パレットインデクス（0～15）
*	color :
*		カラーコード（0～65536）
*
*==========================================================================

_ftx_palette_set

A7ID	=	4			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 0 byte ]

	*=====[ IOCS コールに丸投げ ]
		move.w	A7ID+arg1_w(sp),d1
		move.l	A7ID+arg2_l(sp),d2
		iocs	_TPALET2

	*=====[ return ]
	rts



*==========================================================================
*
* 書式：
*	void ftx_fnt16_cnv(const void *sp_pcg, void *fnt_pcg);
*
* 引数：
*	sp_pcg :
*		変換元のスプライト PCG のポインタ
*	fnt_pcg :
*		フォント PCG 変換結果出力先のポインタ
*
*==========================================================================

_ftx_fnt16_cnv

A7ID	=	4+4*2			*   スタック上 return先アドレス  [ 4 byte ]
					* + 退避レジスタの全バイト数     [ 4*2 byte ]

	movem.l	d6-d7,-(a7)		* レジスタ退避

	movea.l	A7ID+arg1_l(sp),a1	* a1.l = pU16DstPcg
	movea.l	A7ID+arg2_l(sp),a0	* a0.l = pU8SrcPcg


	moveq.l	#0,d7			* d7 = 0

	*=====[ Y 座標のループ ]
loop:
		moveq.l	#0,d0			* d0.l = 0
		move.w	d0,    (a0,d7.w)	* pU16DstPcg[y     ] = 0
		move.w	d0,16*2(a0,d7.w)	* pU16DstPcg[y + 16] = 0
		move.w	d0,32*2(a0,d7.w)	* pU16DstPcg[y + 32] = 0
		move.w	d0,48*2(a0,d7.w)	* pU16DstPcg[y + 48] = 0

		moveq.l	#6,d6			* d6 = 6

		*=====[ X 座標のループ ]
		@@:
			moveq.l	#0,d0			* d0 = 0
			moveq.l	#0,d1			* d1 = 0

			move.b	(a1,64),d1		* d1.l = tmp1
			move.b	(a1)+,d0		* d0.l = tmp0

			lsl.w	#8,d0			* d0.w = tmp0 << 8
			or.b	d1,d0			* d0.w = (tmp0 << 8) | tmp1
							*      = tmp01

			move.w	d0,d1			* d1.w = tmp01
			rol.w	d6,d1			* d1.w = tmp01 << (6 - x)
							*      = tmp
			move.w	#$0101,d2		* d2.w = 0x0101
			lsl.w	d6,d2			* d2.w = 0x0101 << (6 - x)
							*      = mask

							*---------------------------------------
			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,(a0,d7.w)		* pS16DstPcg[y     ] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,16*2(a0,d7.w)	* pS16DstPcg[y + 16] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,32*2(a0,d7.w)	* pS16DstPcg[y + 32] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,48*2(a0,d7.w)	* pS16DstPcg[y + 48] |= tmp & mask;
							*---------------------------------------

			add.w	d2,d2			* mask <<= 1

							*---------------------------------------
			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,(a0,d7.w)		* pS16DstPcg[y     ] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,16*2(a0,d7.w)	* pS16DstPcg[y + 16] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,32*2(a0,d7.w)	* pS16DstPcg[y + 32] |= tmp & mask;

			ror.w	#1,d1			* tmp >>= 1

			move.w	d1,d0			* d0.w = tmp
			and.w	d2,d0			* d0.w = tmp & mask
			or.w	d0,48*2(a0,d7.w)	* pS16DstPcg[y + 48] |= tmp & mask;
							*---------------------------------------

			*------[ 次の要素へ ]
			subq.w	#2,d6
			bpl.b	@b

		*------[ 次の要素へ ]
		addq.w	#2,d7
		cmp.w	#16*2,d7
		blt	loop

	*=====[ return ]
	movem.l	(a7)+,d6-d7		* レジスタ復活
	rts



*==========================================================================
*
* メモリ確保など
*
*==========================================================================

	.even

usp_bak		dc.l	0
pcg_adr		dc.l	0
CRTC_R21_bak	dc.w	0


