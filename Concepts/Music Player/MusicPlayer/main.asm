; *****************************************************************************
; *                                                                           *
; * COPYRIGHT (C) 2017 NICOLA CIMMINO                                         *
; *                                                                           *
; *   THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY    *
; *   IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY    *
; *   THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR       *
; *   (AT YOUR OPTION) ANY LATER VERSION.                                     *
; *                                                                           *
; *  THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL,          *
; *   BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF          *
; *   MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  SEE THE           *
; *   GNU GENERAL PUBLIC LICENSE FOR MORE DETAILS.                            *
; *                                                                           *
; *   YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE       *
; *   ALONG WITH THIS PROGRAM.  IF NOT, SEE HTTP://WWW.GNU.ORG/LICENSES/.     *
; *                                                                           *
; *                                                                           *
; *****************************************************************************

; *****************************************************************************
; * BELOW ARE TBE BASIC TOKENS FOR 10 SYS49152                                *
; * WE STORE THEM AT THE BEGINNING OF THE BASIC RAM SO WHEN WE CAN LOAD       *
; * THE PROGRAM WITH AUTORUN (LOAD "*",8,1) AND SAVE TO TYPE THE SYS.         *

*=$801

        BYTE $0E, $08, $0A, $00, $9E, $34, $39, $31, $35, $32, $00, $00, $00
; *                                                                           *
; *****************************************************************************

INSTRP=$02
STEPR=$04

; *****************************************************************************
; * THIS IS THE ENTRY POINT INTO OUR PROGRAM. WE DO SOME SETUP AND THEN LET   *
; * THINGS ROLL FROM HERE.                                                    *

*=$C000

START   SEI             ; PREVENT INTERRUPTS WHILE WE SET THINGS UP.
        JSR  $FF81      ; RESET VIC, CLEAR SCREEN, THIS IS A KERNAL FUNCTION.

        LDA  #%00110101 ; DISABLE KERNAL AND BASIC ROMS WE GO BARE METAL.
        STA  $01        ; 

        LDA  #%01111111 ; DISABLE CIA-1/2 INTERRUPTS.
        STA  $DC0D      ;
        STA  $DD0D      ;
      
        LDA  #1         ; SET RASTER INTERRUPT FOR LINE 1. POSITION IS ACTUALLY
        STA  $D012      ; IRRELEVANT WE NEED A TIME BASE ONE CALL PER FRAME.
        LDA  #%01111111 ; CLEAR RST8 BIT, THE INTERRUPT LINE IS
        AND  $D011      ; ABOVE RASTER LINE 255.
        STA  $D011
       
        LDA  #<ISR      ; SET THE INTERRUPT VECTOR TO THE ISR ROUTINE.
        STA  $FFFE      ;
        LDA  #>ISR
        STA  $FFFF

        LSR  $D019      ; ACKNOWELEDGE VIDEO INTERRUPTS.
        LDA  #%00000001 ; ENABLE RASTER INTERRUPT.
        STA  $D01A      ;
        
        JSR MUINIT

        LDA  $DC0D      ; ACKNOWLEDGE CIA INTERRUPTS.
        
        CLI             ; LET INTERRUPTS COME.

        ; THIS IS OUR MAIN LOOP. NOTHING  USEFUL THE PAYER RUNS ONLY ONCE PER
        ; FRAME WHEN THE INTERRUPT HAPPENS.
        
        JMP  *

; *                                                                           *
; *****************************************************************************

MUINIT  LDA #0          ; Start from step 0
        STA STEPR
        STA STEPR+1

        LDA  #<INSTR    ; Instrument 0 (this will really come from the track)
        STA  INSTRP
        LDA  #>INSTR
        STA  INSTRP+1
        
        LDA  #$D6       ; A4 in freq reg, will really come from track
        STA $D400
        LDA  #$1C
        STA $D401

        LDA #%00001111  ; Volume max
        STA $D418
        
        RTS
 
; *****************************************************************************
; * THIS IS THE RASTER INTERRUPT  SERVICE ROUTINE. IN A FULL APP THIS WOULD DO* 
; * SEVERAL THINGS, WE HERE ONLY PROCESS THE MUSIC STUFF.                     *

ISR     
        
        LSR  $D019      ; ACKNOWELEDGE VIDEO INTERRUPTS.
        
        LDA  #1
        STA  $D020
        STA  $D021
        
        LDY  #0         ; LOAD CURRRENT INSTRUMENT COMMAND
        LDA  (INSTRP),Y

        ROR             ; GET HIGH NIBBLE*2 IN X
        ROR             ;
        ROR             ;
        AND  #%00011110 ;
        TAX             ;

        LDA CMDTBL,X    ; TRANSFER MSB OF CMD ADDRESS
        STA @JSRINS+1

        LDA CMDTBL+1,X
        STA @JSRINS+2
        
@JSRINS JSR  *
        
MUDONE  RTI

; *                                                                           *
; *****************************************************************************

*=$F000

CMDTBL  WORD $0000
        WORD $0000
        WORD WVR
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD $0000
        WORD END

WVR     LDA  #5
        STA  $D020
        STA  $D021

        RTS


END     LDA  #8
        STA  $D020
        STA  $D021

        RTS
               
INSTR   BYTE $25, $52   ; WVR 5, $52            AD
        BYTE $26, $F3   ; SR
        BYTE $24, $81   ; WVR 4, %10000001      NOISE + GATE ON
        BYTE $FF        ; END
