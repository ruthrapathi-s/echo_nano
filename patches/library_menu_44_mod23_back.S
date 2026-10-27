@ Media Library menu: back-navigation fix. When returning from the media
@ browser (mod23) to Media Library (mod22), translate the browser window title
@ (0x0300e800) back to the CFW menu entry types:
@   Artists (title 0x85)       -> type 9
@   Recent Albums (title 0x87) -> type 7
@ This lets mod22 menu_restore place the cursor on the exact item, while
@ preserving MusicTypeSelID as 3 (Artists) and 4 (Albums) inside mod23 so list
@ setup, rendering, and levels use stock logic.
@ Cave: after artist_count in the unreferenced 0x03079d78..0x03079ef5.
@ patch 23 03079e60
#include "fw.inc"
back_type:
    ldrh    r0, [r5]                    @ stock: r0 = MusicTypeSelID
    ldr     r1, =0x0300e800             @ browser window title string id
    ldrh    r1, [r1]
    cmp     r1, #0x84                   @ Most Played
    it      eq
    moveq   r0, #8
    cmp     r1, #0x85                   @ Artists
    it      eq
    moveq   r0, #9
    cmp     r1, #0x87                   @ Recent Albums
    it      eq
    moveq   r0, #7
    strh.w  r0, [sp]                    @ stock: store to window param
    bx      lr
    .align  2
    .ltorg
