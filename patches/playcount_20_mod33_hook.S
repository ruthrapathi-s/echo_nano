@ Media playback: track advance hook in mod33 (AdvanceTrack).
@ Calls playcount_advance_hook in mod00 cave.
@ patch 33 03082164
#include "fw.inc"
    .equ    playcount_advance_hook, 0x0307434c
    fb      playcount_advance_hook
