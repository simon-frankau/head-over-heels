;;
;; sound48k.asm
;;
;; 48K sound production
;;

;; Main exported functions:
;; * PlayTune
;; * IrqFn
;; * PlaySound

;; The last sound played. Gets copied to IntSnd for interrupt-based playing.
CurrSnd:        DEFB $00

;; The sound currently playing via interrupts.
;; $FF = Nothing playing right now
;; $00 = Don't play any sounds on interrupts
;; Three bytes for 128K. 48K only uses first byte.
IntSnd:         DEFB $FF,$00,$00

;; Top bit set if sound enabled.
SndEnable:      DEFB $80

;; (Overwritten by 128K patch)
PlayTune:       LD      A,(IntSnd)
                CP      $00
                RET     Z               ; Don't play if disabled.
                LD      B,$C3           ; Play the HoH theme music
                JP      PlaySound

;; (Overwritten by 128K patch)
IrqFn:          JP      SndHandler

;; Ratio between elements are twelth root of two - definitions for
;; notes in a scale.
;; (Overwritten by 128K patch)
;;
;; 3.5MHz clock, count of 4 takes 24 T-states, 2 edges per cycle, so this
;; list is for the octave below the one containing middle C.
;;
;; I think the base octave in the code is the next octave up
;;                   A    A#   B    C    C#   D   D#  E   F   F#  G   G#
ScaleTable:     DEFW 1316,1241,1171,1105,1042,983,927,875,825,778,734,692

;; Plays a sound. Sound is passed in in B.
;; May play the sound either immediately or using the interrupt-driven
;; mechanism.
;; (Overwritten by 128K patch)
PlaySound:
        ;; Exit early if sound is disabled.
                LD      A,(SndEnable)
                RLA
                RET     NC
        ;; If sound is currently playing, don't play again.
                LD      HL,IntSnd
                LD      A,(HL)
                CP      B
                RET     Z
        ;; If the bottom 6 bits are not all set, play...
                LD      A,B
                AND     $3F
                CP      $3F
                JR      NZ,PS_2
        ;; If B is $FF, stop playing...
                INC     B
                JR      Z,PS_1
        ;; If IntSnd is 0, return immediately.
                LD      A,(HL)
                AND     A
                RET     Z
        ;; Otherwise, only if the current top bits match, do we stop
        ;; playing. i.e. It's a more selective stop.
                LD      A,B
                DEC     A
                XOR     (HL)
                AND     $C0
                RET     NZ
        ;; Set IntSnd to $FF to stop playing.
PS_1:           LD      A,$FF
                LD      (HL),A
                RET
        ;; At this point, masked sound in A, unmasked in B.
PS_2:           LD      C,A
                LD      A,B
                LD      D,$00
                DEC     HL      ; HL = CurrSnd
                LD      (HL),A  ; Store unmasked sound id.
                RLCA
                RLCA
                AND     $03
                LD      B,A     ; Store top 2 bits at the bottom of B.
                CP      $03
                JR      NZ,PS_3
        ;; Top two bits set - use SoundTable3 directly.
        ;; Note that SoundTable3 bypasses the silencing...
        ;; And once the sound finishes playing the silencing is no
        ;; longer in place?
                XOR     A
                LD      (HL),A
                LD      HL,SoundTable3
                JR      PS_6
        ;; If IntSnd == 0, return.
PS_3:           LD      A,(IntSnd)
                AND     A
                RET     Z
        ;; Look up into the SoundTable list, with weird adjustments.
                LD      A,B
                CP      $02
                JR      Z,PS_5  ; Top two bits = $02 - go indirect.
                CP      $01
                LD      A,$F9   ; Top bits = $01, adjust C by -7
                JR      Z,PS_4
                LD      A,$FC   ; Top bits = $00, adjust C by -4
PS_4:           ADD     A,C
                RET     NC
                LD      C,A
        ;; Two layers of indirection. B indexes into top-level table...
PS_5:           LD      HL,SoundTable
                LD      E,B
                SLA     E
                ADD     HL,DE
                LD      E,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,E
        ;; HL now contains second-level table.
        ;; C contains index into list of scores.
        ;; Load the address of the score (the ScorePtr) into DE.
PS_6:           LD      E,C
                SLA     E
                ADD     HL,DE
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
        ;; If $04 set on the first byte of score, play immediately
                LD      A,(DE)
                AND     $07
                LD      C,A
                AND     $04
                JR      NZ,PlayImm
        ;; Otherwise, play using interrupts.
        ;; NB: Fall through.

;; Interrupt-driven sound-playing.
;; ScorePtr in DE, flags in C
PlayInt:
                LD      A,C
        ;; Cases for C & $03:
        ;; 0: B =             $02 - usual
        ;; 1: B = $80 | $10 | $02 - glissando
        ;; 2: B = $08 |       $02 - stacatto
        ;; Basically same flags as in PlayNextPhrase.
                AND     $02
                LD      B,$0A
                JR      NZ,PI_2
                LD      B,$92
                RR      C
                JR      C,PI_2
                LD      B,$02
        ;; We scribble over locations the interrupt handler cares about.
        ;; So, disable interrupts.
PI_2:           DI
        ;; Copy CurrSnd into IntSnd.
                LD      HL,CurrSnd
                LD      A,(HL)
                INC     HL
                LD      (HL),A
        ;; Then write the main sound-triggering variables
                LD      HL,SndCtrl
                LD      (HL),B          ; Write SndCtrl
                INC     HL
                INC     HL
                LD      (HL),E          ; Write ScorePtr
                INC     HL
                LD      (HL),D
                XOR     A
                INC     HL
                LD      (HL),A          ; Clear ScoreIdx
                EI
                RET

;; Set up a sound to play immediately.
;; ScorePtr in DE, flags in C
PlayImm:        EX      DE,HL
                LD      B,(HL)  ; First byte in B
                INC     HL
                LD      E,(HL)  ; Then E
                INC     HL
                LD      D,(HL)  ; Then D
        ;; If $02 set on first byte, stop any running sound.
                LD      A,B
                AND     $02
                JR      Z,PI_3
                LD      A,(IntSnd)
                AND     A
                JR      Z,PI_3
                LD      A,$FF
                LD      (IntSnd),A
        ;; Set SndNotImm to 0 as we play, then $FF when completed,
        ;; to stop interrupt sound from playing.
PI_3:           XOR     A
                LD      (SndNotImm),A
                CALL    DoSound ; Play B cycles of length DE.
                LD      A,$FF
                LD      (SndNotImm),A
                RET

;; Sound interrupt handler.
SndHandler:     LD      IY,SndCtrl
        ;; If IntSnd == $FF, nothing to do.
                LD      A,(IntSnd)
                INC     A
                RET     Z
        ;; Generate the current score pointer, put it in IX.
                LD      IX,(ScorePtr)
                LD      DE,(ScoreIdx)
                LD      D,$00
                ADD     IX,DE
        ;; If $02 bit of SndCtrl is set, start the score
                BIT     1,(IY+SND_CTRL)
                JR      NZ,PlayNextPhrase
        ;; If the note hasn't finished, play more of it.
                LD      A,(NoteLen)
                AND     A
                JP      NZ,DoNoteCont
        ;; If note length has reached zero, at which point we pick
        ;; up the next note.
                RES     4,(IY+SND_CTRL) ; Disable 'glissando complete'
                CALL    GetScoreByte
                LD      D,A
                INC     A
                JR      NZ,PlayNextNote ; Usual next-note case.
        ;; If next byte is $FF, it's a special case:
                CALL    GetScoreByte
                CP      D
                JR      NZ,SH_1
        ;; Following byte also $FF? End of score. Set IntSnd to $FF and return.
                LD      (IntSnd),A
                RET
SH_1:           AND     A
                JR      NZ,PlayNextPhrase
        ;; Follwing byte was $00. Loop to start of score.
                LD      (ScoreIdx),A
                LD      IX,(ScorePtr)
        ;; NB: Fall through.

;; Read the next byte and start playing...
PlayNextPhrase: LD      D,(IX+$00)
                CALL    UnpackD
        ;; Load an absolute value for the note.
                LD      (IY+SND_NOTE),D
        ;; Cases for E & $03:
        ;; 0: B = $00 - usual
        ;; 1: B = $80 - glissando
        ;; 2: B = $08 - stacatto
                LD      B,$08
                LD      A,E
                AND     $02
                JR      NZ,PNP_2
                LD      B,$80
                RRC     E
                JR      C,PNP_2
                LD      B,$00
        ;; Set up the control flags for the new phrase...
PNP_2:          LD      A,(SndCtrl)
                AND     $02             ; Only keep 'new score' flag.
                OR      B
                LD      E,A
        ; Copy $02 flag to $10 - no glissando at start of score.
                AND     $02
                RLA
                RLA
                RLA
        ;; And add in the new phrase control flags.
                OR      E
                LD      (SndCtrl),A
        ;; And now get the first byte to play...
                CALL    GetScoreByte
                LD      D,A
        ;; There's a score byte in D.

;; Play the next note.
PlayNextNote:   LD      A,(SndCtrl)
                AND     ~$06
                LD      (SndCtrl),A     ; Turn off new phrase and rest flags
        ;; Unpack the score byte to length and pitch delta from previous...
                CALL    UnpackD
                LD      C,D
                LD      D,$00
                LD      HL,NoteLens
                ADD     HL,DE
                LD      A,(HL)
                LD      (NoteLen),A
                LD      A,C
                AND     A
        ;; then play it.
                JR      NZ,DoNote       ; Tail call
                SET     2,(IY+SND_CTRL) ; Set rest (silence) if pitch was 0.
                RET

;; Update both the in-register pointer, and the index in memory, and
;; fetch the next byte of score (in A).
GetScoreByte:   INC     IX              ; Contains ScorePtr + ScoreIdx
                INC     (IY+SCORE_IDX)
                LD      A,(IX+$00)
                RET

;; Play a new note, specified in Sound Note.
;; Note is passed in in A, as an offset from the base note.
DoNote:         ADD     A,(IY+SND_NOTE)
        ;; Divide A by 12 to get octave and note:
        ;; Result plus one in C (octave), remainder in A (note in scale).
                LD      B,12
                LD      H,0
                LD      C,H
DN_0:           INC     C
                SUB     B
                JR      NC,DN_0
                ADD     A,B
        ;; Look up the delay constant in the scale table, put in DE.
                LD      L,A
                ADD     HL,HL
                LD      DE,ScaleTable
                ADD     HL,DE
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
                INC     HL              ; (Seems unnecessary??)
        ;; Calculate the sound length:
        ;; Base it on the octave - each octave makes the note last half as
        ;; many cycles, so we'll double the number of cycles to keep the
        ;; note length more-or-less constant.
                LD      B,C
                LD      A,$02
DN_1:           RLCA
                DJNZ    DN_1
        ;; If 'glissando complete' is not set, make the note run a bit longer:
                BIT     4,(IY+SND_CTRL)
                JR      NZ,DN_2
        ;; Double the constant and add 8.
                RLCA
                ADD     A,$08
        ;; Then store it in SndLen.
DN_2:           LD      (SndLen),A
        ;; Now shift the delay constant (in DE), according to the
        ;; octave we're in, to get a note pitched to the right octave.
                LD      B,C
DN_3:           SRL     D
                RR      E
                DJNZ    DN_3
        ;; Now some octave-specific cases:
        ;; I assume this is a minor tweak to improve the tuning.
                LD      A,C
                DEC     A
                JR      Z,DN_5  ; No adjustment for bottom octave (C == 1)
                LD      B,$09
                LD      A,$04
                SUB     C
                JR      C,DN_4  ; B = 9 for octave > 4
                RLA             ; A = 2 * (4 - C)
                NEG             ; A = 2 * C - 8
                ADD     A,B     ; A = 2 * C + 1
                LD      B,A     ; B = 2 * C + 1
DN_4:           LD      A,E     ; And then subtract B from DE
                SUB     B
                LD      E,A
                JR      NC,DN_5
                DEC     D
        ;; Check for glissando
DN_5:           LD      A,(SndCtrl)
                AND     $90
                CP      $80     ; Need glissando set, glissando not complete.
                JR      NZ,DN_8
        ;; Glissando case
                LD      (SndWavelenTgt),DE
                LD      HL,(SndWavelen)
                EX      DE,HL
                XOR     A
                SBC     HL,DE   ; Now contains difference between current and target.
                LD      A,(NoteLen)
        ;; Count significant bits in A.
                LD      B,$08
DN_6:           RLA
                DEC     B
                JR      NC,DN_6
        ;; Divide through by that.
DN_7:           SRA     H
                RR      L
                DJNZ    DN_7
        ;; And that gives us our delta to finish in the appropriate timeframe.
                LD      (SndWavelenDelta),HL
                RES     4,(IY+SND_CTRL) ; Glissando not complete.
                JR      DoCurrSound     ; Tail call
        ;; Non-glissando case
DN_8:           LD      (SndWavelen),DE
        ;; NB: Fall through

;; Play the sound with the current length (cycle count) and wavelength.
DoCurrSound:    LD      B,(IY+SND_LEN)
                LD      DE,(SndWavelen)
        ;; If immediate sound is running, don't interrupt it.
                LD      A,(SndNotImm)
                INC     A
                RET     NZ
        ;; Fall through!

;; Writes out B edges with a delay constant of DE.
DoSound:        LD      A,E
        ;; Bottom two bits control the overwrite of the jump to DS_1 -
        ;; back jump to the OUT, or one of the INC HLs.
                AND     $03
                NEG
                ADD     A,$F0
                LD      (DS_3+1),A
        ;; Divide DE by 4.
                SRL     D
                RR      E
                SRL     D
                RR      E
        ;; Load up previously written value...
                LD      A,(LastOut)
        ;; Jump target area... these are simply delay ops.
                INC     HL
                INC     HL
                INC     HL
        ;; Write/toggle the sound bit.
DS_1:           OUT     ($FE),A
                XOR     $30
        ;; Delay loop.
                LD      C,A
                PUSH    DE
DS_2:           DEC     DE              ; 6 T-states
                LD      A,D             ; 4 T-states
                OR      E               ; 4 T-states
                JP      NZ,DS_2         ; 10 T-states
                POP     DE              ; Total: 24 T-states
                LD      A,C
        ;; And loop.
DS_3:           DJNZ    DS_1            ; Target of self-modifying code!
                RET

;; Play an existing note, performing glissando update step etc. as needed.
DoNoteCont:
        ; Do nothing if NoteLen is zero, and not glissando.
                LD      A,(SndCtrl)
                LD      B,A
                DEC     (IY+NOTE_LEN)
                JR      NZ,DNC_1
                AND     $80
                RET     Z
                LD      A,B
        ;; Silent if 0x08 (stacatto) or 0x04 (rest) bit set in SndCtrl
DNC_1:          AND     $0C
                RET     NZ
        ;; Just go play sound if not glissando (SndCtrl & 0x90 != 0x80)
                LD      A,B
                AND     $90
                CP      $80
                JR      NZ,DoCurrSound  ; Jump if not glissando.
        ;; With glissando, apply delta to wavelength
                LD      HL,(SndWavelen)
                LD      DE,(SndWavelenDelta)
                ADD     HL,DE
                LD      E,L
                LD      D,H
        ;; Now check if we've hit the limit of the glissando:
                LD      BC,(SndWavelenTgt)
                XOR     A
                SBC     HL,BC
                RRA                     ; Put carry in high bit of A.
        ;; And compare with sign of SndWavelenDelta high byte - have
        ;; we gone past in the right direction?
                XOR     A,(IY+SND_WAVELEN_DELTA)
                RLA
                JR      C,DNC_2
        ;; We have passed the target:
        ;; Set glissando complete bit...
                SET     4,(IY+SND_CTRL)
        ;; And use the target frequency...
                LD      DE,(SndWavelenTgt)
        ;; Update SndWavelen and run the sound.
DNC_2:          LD      (SndWavelen),DE
                JR      DoCurrSound     ; Tail call

;; Given a byte in D, put the bottom three bits in E, and the next
;; five in D (rotated to the bottom).
UnpackD:        LD      BC,$0307
                LD      A,D
                AND     C
                LD      E,A             ; Mask bottom 3 bits into E.
                LD      A,C
                CPL
                AND     D
                LD      D,A             ; Mask top 5 bits of D.
UnpackD_1:      RRC     D
                DJNZ    UnpackD_1
                RET                     ; And rotate into bottom position.

;; Look-up table of note lengths.
;; At 50Hz, assuming $04 = crotchet, we're at a somewhat insane 750
;; BPM. This conversion factor may be inappropriate!
NoteLens:       DEFB $01,$02,$04,$06,$08,$0C,$10,$20

;; Flags for SndCtrl:
;; $02 - start score
;; $04 - is a rest - silence
;; $08 - stacatto - only plays for first frame
;; $10 - glissando completed
;; $80 - glissando wanted

;; This is set by sounds playing immediately, so they're not interrupted by
;; the sounds that play in interrupts.
SndNotImm:      DEFB $FF

SndCtrl:                DEFB $00         ; Flags controlling how sound plays.
NoteLen:                DEFB $00         ; Time until note completes.
ScorePtr:               DEFW $0000       ; Pointer to current score.
ScoreIdx:               DEFB $00         ; Index into the score.
SndNote:                DEFB $00         ; Base musical scale note number.
SndWavelenTgt:          DEFW $0000       ; Target wavelen for glissando.
SndWavelen:             DEFW $0000       ; Delay between edges to play.
SndLen:                 DEFB $00         ; Number of edges to play.
SndWavelenDelta:        DEFW $0000       ; Delta to apply when glissando-ing.

;; Offsets from SndCtrl, used with IY.
SND_CTRL:               EQU 0
NOTE_LEN:               EQU 1
SCORE_PTR:              EQU 2
SCORE_IDX:              EQU 4
SND_NOTE:               EQU 5
SND_WAVELEN_TGT:        EQU 6
SND_WAVELENGTH:         EQU 8
SND_LEN:                EQU 10
SND_WAVELEN_DELTA:      EQU 11

SoundTable:     DEFW SoundTable0,SoundTable1,SoundTable2

SoundTable2:    DEFW S_80,S_81,S_82,S_83,S_84,S_85,S_86,S_87,S_88
SoundTable1:    DEFW S_47,S_48
SoundTable0:    DEFW S_04,S_05
SoundTable3:    DEFW S_C0,S_C1,S_C2,S_C3,S_C4,S_C5,S_C6,S_C7,S_C8

S_C6:
#insert "../../bin/sound/C6.bin"
S_04:
#insert "../../bin/sound/04.bin"        ; Immediate
S_05:
#insert "../../bin/sound/05.bin"        ; Immediate
S_80:
#insert "../../bin/sound/80.bin"
S_81:
#insert "../../bin/sound/81.bin"
S_82:
#insert "../../bin/sound/82.bin"
S_83:
#insert "../../bin/sound/83.bin"
S_84:
#insert "../../bin/sound/84.bin"
S_85:
#insert "../../bin/sound/85.bin"        ; Immediate
S_86:
#insert "../../bin/sound/86.bin"        ; Immediate
S_87:
#insert "../../bin/sound/87.bin"        ; Fall through...
S_C0:
#insert "../../bin/sound/C0.bin"
S_88:
#insert "../../bin/sound/88.bin"        ; Immediate
S_48:
#insert "../../bin/sound/48.bin"
S_47:
#insert "../../bin/sound/47.bin"
S_C1:
#insert "../../bin/sound/C1.bin"
S_C2:
#insert "../../bin/sound/C2.bin"
S_C4:
#insert "../../bin/sound/C4.bin"
S_C5:
#insert "../../bin/sound/C5.bin"
S_C7:
#insert "../../bin/sound/C7.bin"
S_C8:
#insert "../../bin/sound/C8.bin"
S_C3:
#insert "../../bin/sound/C3.bin"
