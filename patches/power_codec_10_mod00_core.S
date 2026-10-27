@ Power management: Deeper idle B-core clock release on Stop & Pause
@ Placed in mod00 cave at 0x03074b00.
@ patch 0 03074b00
#include "fw.inc"

    .equ    ReleaseCodecClockRow, 0x03084ea0
    .equ    ReleaseClockRow,      0x0306af30

.global power_codec_release_stop
.global power_codec_release_pause

@ ------------------------------------------------------------------------------
@ power_codec_release_stop:
@ Called from mod33 StopPlayback (0x03083448).
@ Calls ReleaseCodecClockRow(), then calls ReleaseClockRow(4), then returns.
@ ------------------------------------------------------------------------------
power_codec_release_stop:
    push    {r1-r3, lr}
    fbl     ReleaseCodecClockRow
    movs    r0, #4              @ row 4: MusicInit
    fbl     ReleaseClockRow
    pop     {r1-r3, pc}

    .align 2
@ ------------------------------------------------------------------------------
@ power_codec_release_pause:
@ Called from mod33 PausePlayback (0x03081a14).
@ Sets playback status = 2 (PAUSED), calls ReleaseCodecClockRow(),
@ then branches to 0x030817ba.
@ Preserves r0, r2 for 0x030817ba.
@ ------------------------------------------------------------------------------
power_codec_release_pause:
    movs    r1, #2
    strh    r1, [r2, #10]       @ SysFileInfo->status = 2 (PAUSED)
    push    {r0-r3, lr}
    fbl     ReleaseCodecClockRow
    pop     {r0-r3, lr}
    fb      0x030817ba          @ continue pause handler
