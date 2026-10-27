@ Resume playback position: save playback state (CurrentFileNum, ElapsedMS) on shutdown.
@ Placed in mod00 cave at 0x03073ed4.
@ patch 0 03073ed4
#include "fw.inc"

resume_shutdown_save:
    push    {r0-r3, lr}

    @ Check if MusicService control block (0x03039708) has an active decoder
    ldr     r0, =0x03039708     @ MusicService global control block
    ldr     r0, [r0, #12]       @ active decoder object pointer
    cbz     r0, 1f              @ NULL if stopped or no music active

    @ Music is active (playing or paused): call SavePlaybackState
    ldr     r0, [r0, #4]        @ r0 = elapsed_ms
    ldr     r1, =0x0300d85c     @ r1 = SysFileInfo pointer
    ldr     r2, =0x03085000     @ mod34 SavePlaybackState(elapsed_ms, file_info)
    blx     r2

1:
    pop     {r0-r3, lr}

    @ Execute the original replaced instructions from 0x03069d90:
    ldr     r0, =0x03029350     @ MusicService state descriptor pointer
    ldr     r0, [r0, #0]
    cbz     r0, 2f
    ldrh    r0, [r0, #10]       @ playback status
    cmp     r0, #3              @ is status == 3 (playing)?
    itte    eq
    moveq   r0, #2
    strbeq.w r0, [r4, #529]     @ [gSysConfig, #529] = 2
    strbne.w r8, [r4, #529]     @ [gSysConfig, #529] = 1

2:
    fb      0x03069d82          @ return to shutdown flow

    .align  2
    .ltorg
