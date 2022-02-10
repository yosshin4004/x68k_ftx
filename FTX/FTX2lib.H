#ifndef FTX2LIB_H
#define FTX2LIB_H

void ftx_pcgdat_set(const void *pcg_dat);
void ftx_fnt8_put(short x, short y, short cd);
void ftx_fnt16_put(short x, short y, short cd);
void ftx_clr();
void ftx_scroll_set(short x, short y);
void ftx_palette_set(short idx, unsigned short color);
void ftx_fnt16_cnv(const void *sp_pcg, void *fnt_pcg);

#endif
