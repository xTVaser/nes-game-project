    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 0

;Console at the beginnig is in unknown state
;NES does not support full 6502 instruction set, no binary coded decimal, we need to disable as a safe guard

    .bank 0
    .org $C000
RESET:
    SEI         ;disable IRQs
    CLD         ;disable decimal mode
    LDX #$40
    STX $4017   ;disable APU frame IRQ
    LDX #$FF
    TXS         ;setup system stack
    INX         ;X = 0
    STX $2000   ;disable NMI
    STX $2001   ;disable rendering
    STX $4010   ;disable DMC IRQs
    
;we must wait 2 frames before continuing after accessing PPU due to NES hardware limitations
;setup palatte by accessing PPU memory, this memory is seperat efrom 6502's.
;therefore we setup the PPU's memory addresses to write, and then use it's $2007 port.
;PPU will autoincrement address to write with.

    jsr WaitForVBlank ; first vblank
    ;could do more initialization here if we needed to.
    jsr WaitForVBlank ; PPU now ready.
    
LoadPalettes:
    LDA $2002   ;read PPU status to reset high/low latch
    LDA #$3F
    STA $2006   ;write the high byte of $3F00 address
    LDA #$00
    STA $2006   ;write the low byte of $3F00 address
    
    LDX #$00    ;start otu at 0

    LoadPalettesLoop:
        LDA palette, x  ;load data from address (palette + the value in x)
        STA $2007       ;write to PPU
        INX             ; X++
        CPX #32         ;compare X to hex $20, decimal 32, copying 32 bytes = 4 sprites. WHAT (he said 16)
    BNE LoadPalettesLoop    ;branch to loadpalettesloop if compare was not equal to xzero, if was equal to 32 keep going down.
    
;now we are going to actually print hello world
;the screen right now is undefined we have to fill the remainder of the screen with our space character.
;once again to do this by setting the screen memory address and sending data to PPU port $2007

HelloWorld:
    LDA #$00
    STA $2001   ;disable rendering
    
    ;first 8 lines we are going to leave blank
    LDX #00
    LDA $2002   ;read PPU status to reset high/low/latch
    LDA #$20
    STA $2006   ;write the high byte of screen address.
    STX $2006   ;write the low byte of screen address
    
    LDA #$24    ;blank charater in char set using YY-CHR
    
    ;Accumulator already has $20 (space character) so we donthave to set it.
    
    HelloWorld_topBlank:
        STA $2007   ;write character to screen
        INX 
        BNE HelloWorld_topBlank

    LDX #-1
    
    HelloWorld_printHello:
        LDA hello_string,X
        STA $2007
        INX
        CPX #$10
        BNE HelloWorld_printHello
        
        ;prepare 2-level loop to fill remainder of screen 
        LDX #$50    ;this is $50 due to $10(16) printed chracters and $40 (64) attribute bytes.
        LDY #3      ;loop through 256 (-80 first pass) 3 times
        LDA #$24    ;printing spaces.
    HelloWorld_bottomBlank:
        STA $2007
        INX
        BNE HelloWorld_bottomBlank
        DEY
        BNE HelloWorld_bottomBlank
       
        ;setup attribute table
        LDX #$40
        LDA #0
    HelloWorld_attributeTable:
        STA $2007
        DEX
        BNE HelloWorld_attributeTable

;Nothing will display yet because we have disabled the PPU, set screen scroll position correctly
;and enable background and do nothing 

    STA $2005
    STA $2005
    LDA #%00011000      ;enable background
    STA $2001
    
MainGameLoop:
    NOP ;do nothing
    JMP MainGameLoop
       
; ------------------------
; Functions
WaitForVBlank:
    BIT $2002
    BPL WaitForVBlank
    RTS
    
;we have data, for example the font and the text hello world, so we need to store it in a bank.
;we could use bank 0, but use bank 1 and setup jump vectors because we need them
;jump vectors are just addresses at the end of the cartridge that get used when the cartridge is reset.

; ------------------------
; Game Data

    .bank 1
    .org $E000
palette:            ;32bits total to set the 4 colors for the pallatte
    .db $0F,$19,$2B,$39, $0F,$17,$16,$06,  $0F,$39,$3A,$3B, $0F,$3D,$3E,$0F
    .db $0F,$14,$27,$39, $0F,$27,$06,$2D,  $0F,$0A,$29,$25, $0F,$02,$38,$3C
    
hello_string:
    ;Hardcoded hex using modified.chr   .db $11,$0E,$15,$15,$18,$24,$20,$18,$1B,$15,$0D     ;HELLO WORLD
    .db "HELLO WORLD", $00      ;this works because the palette file has the characters in the right spots
    
;jump vectors
    .org $FFFA      ;first of the three jump vectors starts here
    .dw 0           ;jump for NMIs if enabled 
    .dw RESET       ;jump for when RESET or first turned on
    .dw 0           ;external interrupt IRQ is not used.
    
; ------------------------
; Character Tables (tilesets)
    .bank 2
    .org $0000
    .incbin "ascii.chr"   ;includes 8KB graphics file from SMB1
        
    
        
    

