@ Resume playback position: hook shutdown sequence when MusicService is running.
@ Replaces the 22-byte block at 0x03069d90 with a branch to the cave handler.
@ patch 0 03069d90
#include "fw.inc"

    fb      0x03073ed4
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
