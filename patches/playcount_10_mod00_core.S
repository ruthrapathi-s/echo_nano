@ Play count / Most-Played tracking: core runtime routines in mod00 cave.
@ Placed at 0x03074300 in the unreferenced 0x030742e8..0x03076340 region of mod00.
@ patch 0 03074300
#include "fw.inc"

    .equ    fw_read,       0x0306b36c
    .equ    fw_write,      0x0306b75e
    .equ    DEV_DB,        0x30001
    .equ    SEC_PLAY_COUNTS,       0x52ec0
    .equ    SEC_MOST_PLAYED_COUNT, 0x52f00
    .equ    SEC_MOST_PLAYED_SONGS, 0x52f10
    .equ    MAGIC_PC,      0x5043

.global playcount_get_count
.global playcount_advance_hook

@ ------------------------------------------------------------------------------
@ playcount_get_count: returns top-level item count for Most Played (r0 = count)
@ Called from mod23 (artist_count). Preserves r4-r11.
@ ------------------------------------------------------------------------------
playcount_get_count:
    push    {r1-r3, lr}
    ldr     r3, =g_most_played_count
    ldrh    r0, [r3]
    movw    r1, #0xffff
    cmp     r0, r1
    bne     9f

    @ Uninitialized in RAM: read from SEC_MOST_PLAYED_COUNT
    ldr     r0, =0x0300d148             @ DB_BASE pointer
    ldr     r0, [r0]
    cmp     r0, #0
    beq     8f
    ldr     r1, =SEC_MOST_PLAYED_COUNT
    add     r0, r0, r1
    lsls    r1, r0, #9                  @ byte address = LBA * 512
    ldr     r0, =DEV_DB
    movs    r2, #64                     @ read first 64 bytes
    ldr     r3, =playcount_cbuf
    fbl     fw_read
    cmp     r0, #0
    bne     8f                          @ read failed

    ldr     r3, =playcount_cbuf
    ldrh    r1, [r3, #2]                @ magic
    ldr     r2, =MAGIC_PC
    cmp     r1, r2
    bne     8f
    ldrh    r0, [r3]                    @ count
    cmp     r0, #256
    it      hi
    movhi   r0, #256
    b       7f

8:  movs    r0, #0
7:  ldr     r3, =g_most_played_count
    strh    r0, [r3]
9:  pop     {r1-r3, pc}

@ ------------------------------------------------------------------------------
@ playcount_advance_hook: called from mod33 AdvanceTrack (0x03082164).
@ r0 = mode (0 = advance track, 1 = stop).
@ If r0 == 0 and elapsed >= duration / 2, increments play count.
@ Then executes replaced instruction stmdb sp!, {r4-r9, sl, lr} and branches to 0x03082168.
@ ------------------------------------------------------------------------------
playcount_advance_hook:
    push    {r0-r3, lr}
    cmp     r0, #0                      @ only check when advancing track (mode 0)
    bne     1f

    @ Check active decoder
    ldr     r1, =0x03039708             @ MusicService control block
    ldr     r1, [r1, #12]               @ active decoder
    cbz     r1, 1f
    ldr     r2, [r1, #0]                @ duration_ms
    cbz     r2, 1f
    ldr     r3, [r1, #4]                @ elapsed_ms
    lsrs    r2, r2, #1                  @ duration / 2
    cmp     r3, r2                      @ elapsed >= duration / 2 ?
    blo     1f

    @ Listened to >= 50%: increment play count
    bl      playcount_increment

1:  pop     {r0-r3, lr}
    @ Execute original replaced instruction from 0x03082164:
    stmdb   sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
    fb      0x03082168

@ ------------------------------------------------------------------------------
@ playcount_increment: updates SEC_PLAY_COUNTS and SEC_MOST_PLAYED_* on SD card.
@ ------------------------------------------------------------------------------
playcount_increment:
    push    {r4-r7, lr}

    @ Check DB_BASE
    ldr     r4, =0x0300d148
    ldr     r4, [r4]                    @ r4 = DB_BASE
    cmp     r4, #0
    beq     99f

    @ Get recno and nsongs
    ldr     r0, =0x0300d85c             @ SysFileInfo
    ldrh    r5, [r0, #52]               @ r5 = recno
    ldr     r0, =0x0300d164             @ library counters
    ldrh    r1, [r0, #46]               @ r1 = total songs
    cmp     r5, r1
    bhs     99f                         @ invalid recno

    @ 1. Read SEC_PLAY_COUNTS sector for recno
    lsrs    r6, r5, #7                  @ r6 = sector offset (recno / 128)
    ldr     r0, =SEC_PLAY_COUNTS
    add     r6, r6, r0
    add     r6, r6, r4                  @ r6 = LBA

    ldr     r0, =DEV_DB
    lsls    r1, r6, #9                  @ byte address = LBA * 512
    movw    r2, #512
    ldr     r3, =playcount_buf
    fbl     fw_read
    cmp     r0, #0
    bne     99f                         @ read failed

    @ Increment count
    and     r7, r5, #0x7f               @ r7 = recno % 128
    lsls    r7, r7, #2                  @ byte offset in sector
    ldr     r3, =playcount_buf
    ldr     r0, [r3, r7]
    adds    r0, r0, #1                  @ r0 = new_count
    str     r0, [r3, r7]
    mov     r7, r0                      @ r7 = new_count

    @ Write back SEC_PLAY_COUNTS sector
    ldr     r0, =DEV_DB
    mov     r1, r6                      @ LBA
    movs    r2, #1                      @ 1 sector
    ldr     r3, =playcount_buf
    fbl     fw_write

    @ 2. Update Most-Played top table
    @ Read SEC_MOST_PLAYED_COUNT (1 sector)
    ldr     r6, =SEC_MOST_PLAYED_COUNT
    add     r6, r6, r4                  @ LBA
    ldr     r0, =DEV_DB
    lsls    r1, r6, #9
    movw    r2, #512
    ldr     r3, =playcount_cbuf
    fbl     fw_read

    @ Check magic
    ldr     r3, =playcount_cbuf
    ldrh    r1, [r3, #2]
    ldr     r2, =MAGIC_PC
    cmp     r1, r2
    beq     2f
    movs    r0, #0
    strh    r0, [r3]
    strh    r2, [r3, #2]
2:  ldrh    r6, [r3]                    @ r6 = m (current top count)
    cmp     r6, #256
    it      hi
    movhi   r6, #256

    @ Read SEC_MOST_PLAYED_SONGS (2 sectors = 1024 bytes)
    ldr     r0, =SEC_MOST_PLAYED_SONGS
    add     r4, r4, r0                  @ r4 = songs LBA
    ldr     r0, =DEV_DB
    lsls    r1, r4, #9
    movw    r2, #1024
    ldr     r3, =playcount_buf
    fbl     fw_read

    @ Clamp new_count (r7) to u16
    movw    r0, #0xffff
    cmp     r7, r0
    it      hi
    movhi   r7, r0                      @ r7 = u16 new_count

    ldr     r3, =playcount_buf          @ recnos base
    add     r12, r3, #512               @ counts base

    @ Search for r5 (recno) in recnos[0..r6-1]
    movs    r0, #0                      @ r0 = idx
3:  cmp     r0, r6
    bhs     4f                          @ not found
    ldrh    r1, [r3, r0, lsl #1]
    cmp     r1, r5
    beq     found_entry
    adds    r0, r0, #1
    b       3b

found_entry:
    @ Found at index r0: update count
    strh    r7, [r12, r0, lsl #1]
    b       bubble_up

4:  @ Not found in existing table
    cmp     r6, #256
    bhs     5f
    @ Table has room (< 256): append at index r6
    mov     r0, r6                      @ r0 = insertion index
    strh    r5, [r3, r0, lsl #1]        @ recnos[m] = recno
    strh    r7, [r12, r0, lsl #1]       @ counts[m] = count
    adds    r6, r6, #1                  @ m++
    b       bubble_up

5:  @ Table full (m == 256): check if new_count > counts[255]
    movs    r0, #255
    ldrh    r1, [r12, r0, lsl #1]
    cmp     r7, r1
    bls     done_table                  @ not higher than lowest
    strh    r5, [r3, r0, lsl #1]
    strh    r7, [r12, r0, lsl #1]
    @ r0 = 255, bubble up

bubble_up:
    @ r0 is current index of the updated entry
6:  cbz     r0, done_table              @ reached top
    subs    r1, r0, #1                  @ r1 = parent index
    ldrh    r2, [r12, r0, lsl #1]       @ counts[r0]
    ldrh    r7, [r12, r1, lsl #1]       @ counts[r1]
    cmp     r2, r7
    bls     done_table                  @ counts[r0] <= counts[r1], sorted!
    @ Swap counts
    strh    r7, [r12, r0, lsl #1]
    strh    r2, [r12, r1, lsl #1]
    @ Swap recnos
    ldrh    r2, [r3, r0, lsl #1]
    ldrh    r7, [r3, r1, lsl #1]
    strh    r7, [r3, r0, lsl #1]
    strh    r2, [r3, r1, lsl #1]
    mov     r0, r1
    b       6b

done_table:
    @ Write back SEC_MOST_PLAYED_SONGS (2 sectors)
    ldr     r0, =DEV_DB
    mov     r1, r4                      @ LBA
    movs    r2, #2                      @ 2 sectors
    ldr     r3, =playcount_buf
    fbl     fw_write

    @ Write back SEC_MOST_PLAYED_COUNT (1 sector)
    ldr     r3, =playcount_cbuf
    strh    r6, [r3]                    @ count = m
    ldr     r2, =MAGIC_PC
    strh    r2, [r3, #2]                @ magic
    ldr     r0, =DEV_DB
    ldr     r1, =0x0300d148
    ldr     r1, [r1]
    ldr     r2, =SEC_MOST_PLAYED_COUNT
    add     r1, r1, r2                  @ LBA
    movs    r2, #1
    fbl     fw_write

    @ Update cached count in RAM
    ldr     r0, =g_most_played_count
    strh    r6, [r0]

99: pop     {r4-r7, pc}

    .align  2
    .ltorg

@ ------------------------------------------------------------------------------
@ Data structures in RAM cave
@ ------------------------------------------------------------------------------
    .align  2
g_most_played_count:
    .short  0xffff                      @ uninitialized
    .short  0                           @ padding
playcount_cbuf:
    .space  512                         @ count sector buffer
playcount_buf:
    .space  1024                        @ 2-sector buffer (recnos + counts)
