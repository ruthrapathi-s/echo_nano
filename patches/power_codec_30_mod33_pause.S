@ Hook PausePlayback in mod33 (0x03081a14) to branch to power_codec_release_pause.
@ Replaces: movs r1, #2 (2B) + strh r1, [r2, #10] (2B) + b.n 0x30817ba (2B) = 6B.
@ Branches to 0x03074b10 which sets status = 2, releases codec clock row, and branches to 0x030817ba.
@ patch 33 03081a14
#include "fw.inc"

    .equ    power_codec_release_pause, 0x03074b10

    fb      power_codec_release_pause
    nop
