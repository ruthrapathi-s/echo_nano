@ Hook StopPlayback in mod33 (0x03083448) to call power_codec_release_stop.
@ Replaces: movs r0, #4 (2B) + bl 0x306af30 (4B) = 6B.
@ Calls 0x03074b00 which releases codec clock row and clock row 4, then returns here.
@ patch 33 03083448
#include "fw.inc"

    .equ    power_codec_release_stop, 0x03074b00

    fbl     power_codec_release_stop
    nop
