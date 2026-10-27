@ Media Library menu: hook back_type at mod23 0x0307ac58 (replaces
@ "ldrh r0,[r5]; strh.w r0,[sp]").
@ patch 23 0307ac58
#include "fw.inc"
    .equ    back_type, 0x03079e60
    fbl     back_type
    nop
