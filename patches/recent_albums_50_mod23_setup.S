@ Recent Albums: mod23 browser window init (FUN_03079f1e, r4 = window param
@ {u16 0, u16 title id, ...}) calls the level setup FUN_0307a144 through here.
@ For title 0x87 the album level reads the newest-first group table written by
@ the CFW blob (DB base + 0x52380) instead of base + 0x52160.
@ Code cave: 0x03079d78..0x03079ef5 is an unreferenced function.
@ patch 23 03079d78
#include "fw.inc"
    .equ    setup, 0x0307a144
recent_setup:
    push    {r3, lr}
    fbl     setup
    ldrh    r0, [r4, #2]
    cmp     r0, #0x84                   @ Most Played
    bne     2f
    ldr     r1, =0x0300e808             @ level descriptor: +0 base, +4 fields, +0x0c tables
    movw    r0, #0x400                  @ title field offset
    strh    r0, [r1, #4]
    ldr     r0, [r1]                    @ DB_BASE
    ldr     r2, =0x52f10                @ SEC_MOST_PLAYED_SONGS
    add     r0, r2
    str     r0, [r1, #0x0c]             @ table[0] = DB_BASE + 0x52f10
    b       1f
2:  cmp     r0, #0x87
    bne     1f
    ldr     r1, =0x0300e808             @ level descriptor: +0 base, +0x0c.. tables
    ldr     r0, [r1]
    ldr     r2, =0x52380
    add     r0, r2
    str     r0, [r1, #0x10]             @ album groups
1:  pop     {r3, pc}
    .align  2
    .ltorg
