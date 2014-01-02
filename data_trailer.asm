	;;
	;; data_trailer.asm
	;;
	;; Data that occurs after the main code section.
	;; 
	;; Mostly sprites, 128K code, and, er, the stack.
	;;
	;; FIXME: Disassemble the 128K code!
	;;
	;; FIXME: Identify the remaining bits and pieces.
	;;

	;; NB: This is 128K-specific patch code applied over the
	;; sound-playing code.
LB824:		LD	A,(Snd2)
		CP	$80
		RET	Z
		LD	B,$C3
		JP	PlaySound

XB82F:	DEFB $3E,$11,$01,$FD,$7F,$ED,$79,$C5,$CD,$35,$C0,$C1,$3E,$10,$ED,$79
XB83F:	DEFB $C9,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$50,$01,$FD,$7F,$3E
XB84F:	DEFB $11,$F3,$32,$67,$96,$ED,$79,$FB,$C5,$42,$CD,$16,$C2,$C1,$3E,$10
XB85F:	DEFB $F3,$32,$67,$96,$ED,$79,$FB,$C9

	;; NB: Not sure what this brief interlude is for!
XB867:	DEFB $F3,$21,$D3,$BD,$11,$00,$40,$01
XB86F:	DEFB $05,$00,$ED,$B0,$11,$00,$5B,$01,$00,$A5,$21,$54,$60,$C3,$00,$40
XB87F:	DEFB $ED,$B0,$C3,$30,$70

	;; NB: This is 128K-specific code, copied into another bank.
LB884:	DEFB $21,$23,$C5,$16,$00,$5E,$23,$CD,$11,$C0,$14
XB88F:	DEFB $7A,$FE,$0B,$20,$F5,$C9,$01,$FD,$FF,$ED,$51,$06,$BF,$ED,$59,$C9
XB89F:	DEFB $EE,$0E,$18,$0E,$4D,$0D,$8E,$0C,$DA,$0B,$2F,$0B,$8F,$0A,$F7,$09
XB8AF:	DEFB $68,$09,$E1,$08,$61,$08,$E9,$07,$77,$07,$3A,$4E,$96,$17,$D0,$CD
XB8BF:	DEFB $D8,$C0,$AF,$32,$D5,$C4,$3E,$3F,$32,$2A,$C5,$21,$D5,$C4,$46,$CD
XB8CF:	DEFB $EE,$C0,$38,$53,$CD,$20,$C3,$E5,$DD,$E1,$CB,$6E,$20,$49,$FD,$21
XB8DF:	DEFB $23,$C5,$5F,$16,$00,$D5,$CB,$23,$FD,$19,$21,$2B,$C5,$D1,$19,$DD
XB8EF:	DEFB $7E,$08,$FD,$77,$00,$DD,$7E,$09,$FD,$77,$01,$42,$DD,$5E,$01,$DD
XB8FF:	DEFB $56,$02,$EB,$DD,$4E,$03,$09,$EB,$1A,$E6,$0F,$28,$09,$DD,$86,$0B
XB90F:	DEFB $FE,$10,$38,$02,$3E,$0F,$77,$3A,$D5,$C4,$47,$04,$3E,$FF,$A7,$17
XB91F:	DEFB $10,$FD,$21,$2A,$C5,$A6,$77,$21,$D5,$C4,$3E,$02,$BE,$CA,$AE,$C0
XB92F:	DEFB $34,$18,$9B,$21,$E2,$C4,$3E,$08,$AE,$E6,$28,$C2,$00,$C0,$3A,$4E
XB93F:	DEFB $96,$1F,$DA,$00,$C0,$21,$29,$C5,$FD,$21,$1B,$C5,$FD,$7E,$07,$77
XB94F:	DEFB $23,$FD,$7E,$00,$E6,$01,$B6,$E6,$F7,$77,$C3,$00,$C0,$AF,$32,$D5
XB95F:	DEFB $C4,$47,$CD,$EE,$C0,$D4,$F6,$C0,$21,$D5,$C4,$7E,$FE,$02,$C8,$3C
XB96F:	DEFB $77,$18,$EE,$3A,$4E,$96,$04,$0F,$10,$FD,$C9,$21,$D5,$C4,$6E,$11
XB97F:	DEFB $DC,$C4,$26,$00,$29,$19,$22,$D3,$C4,$5E,$23,$56,$D5,$DD,$E1,$CD
XB98F:	DEFB $20,$C3,$E5,$FD,$E1,$CB,$4E,$C2,$B8,$C2,$FD,$35,$0D,$20,$13,$CD
XB99F:	DEFB $F9,$C2,$FD,$CB,$00,$5E,$C8,$FD,$21,$1B,$C5,$AF,$FD,$77,$03,$C3
XB9AF:	DEFB $AF,$C1,$FD,$35,$04,$CC,$CB,$C1,$FD,$6E,$08,$FD,$66,$09,$FD,$CB
XB9BF:	DEFB $00,$7E,$28,$2B,$3E,$01,$FD,$CB,$0C,$7E,$28,$02,$3E,$FF,$FD,$86
XB9CF:	DEFB $0F,$FD,$77,$0F,$47,$FD,$7E,$0C,$B8,$20,$07,$ED,$44,$FD,$77,$0C
XB9DF:	DEFB $ED,$44,$FD,$5E,$0E,$16,$00,$07,$38,$04,$ED,$52,$18,$01,$19,$FD
XB9EF:	DEFB $7E,$00,$E6,$50,$FE,$40,$20,$29,$FD,$5E,$11,$FD,$56,$12,$19,$54
XB9FF:	DEFB $5D,$FD,$4E,$06,$FD,$46,$07,$AF,$ED,$42,$17,$FD,$AE,$00,$E6,$01
XBA0F:	DEFB $EB,$20,$0E,$FD,$CB,$00,$E6,$AF,$FD,$77,$0F,$FD,$6E,$06,$FD,$66
XBA1F:	DEFB $07,$FD,$75,$08,$FD,$74,$09,$FD,$CB,$00,$5E,$C8,$FD,$21,$1B,$C5
XBA2F:	DEFB $FD,$35,$04,$C0,$CD,$CB,$C1,$A7,$20,$04,$FD,$B6,$03,$C0,$7E,$E6
XBA3F:	DEFB $0F
	
LBA40:		BIT		7,(IY+$00)
		JR		Z,LBA48
		NEG
LBA48:		ADD		A,(IY+$06)
		LD		(IY+$07),A
		RET

XBA4F:	DEFB $FD,$6E,$01,$FD,$66,$02,$FD,$5E,$03,$AF,$57,$19,$CB,$7E,$20,$1D
XBA5F:	DEFB $CB,$76,$28,$13,$FD,$CB,$00,$56,$FD,$CB,$00,$D6,$28,$0C,$FD,$CB
XBA6F:	DEFB $00,$96,$FD,$77,$03,$18,$03,$FD,$34,$03,$FD,$7E,$05,$FD,$77,$04
XBA7F:	DEFB $C9,$21,$4B,$96,$3A,$D5,$C4,$5F,$16,$00,$19,$36,$FF,$47,$04,$21
XBA8F:	DEFB $4E,$96,$AF,$37,$17,$10,$FD,$47,$B6,$77,$C9,$78,$E6,$3F,$FE,$3F
XBA9F:	DEFB $20,$02,$3E,$FF,$4F,$78,$07,$07,$E6,$03,$47,$FE,$03,$28,$46,$21
XBAAF:	DEFB $4B,$96,$58,$16,$00,$19,$7E,$B9,$C8,$FE,$80,$C8,$71,$79,$3C,$28
XBABF:	DEFB $CD,$21,$CD,$C6,$CB,$23,$19,$7E,$23,$66,$6F,$59,$CB,$23,$19,$7E
XBACF:	DEFB $23,$66,$6F,$E5,$21,$D6,$C4,$58,$CB,$23,$19,$E5,$78,$CD,$23,$C3
XBADF:	DEFB $54,$5D,$47,$CD,$09,$C2,$78,$E1,$C1,$71,$23,$70,$EB,$CB,$CE,$21
XBAEF:	DEFB $4E,$96,$AE,$77,$C9,$26,$00,$69,$29,$54,$5D,$29,$19,$11,$92,$C5
XBAFF:	DEFB $19,$3E,$03,$5E,$23,$56,$23,$D5,$E5,$3D,$CD,$23,$C3,$D1,$E5,$EB
XBB0F:	DEFB $A7,$20,$F0,$21,$4E,$96,$3E,$07,$B6,$77,$21,$4B,$96,$01,$80,$03
XBB1F:	DEFB $78,$71,$23,$10,$FC,$21,$D6,$C4,$D1,$C1,$71,$23,$70,$23,$EB,$CB
XBB2F:	DEFB $CE,$EB,$3D,$20,$F3,$21,$4E,$96,$3E,$F8,$A6,$77,$C9,$CD,$D1,$C2
XBB3F:	DEFB $01,$03,$02,$CD,$09,$C4,$FD,$72,$0A,$FD,$73,$0B,$DD,$23,$CD,$18
XBB4F:	DEFB $C4,$DD,$23,$C3,$F9,$C2,$2A,$D3,$C4,$11,$FA,$FF,$19,$5E,$23,$56
XBB5F:	DEFB $D5,$DD,$E1,$C9,$CD,$D1,$C2,$DD,$23,$18,$0E,$DD,$23,$DD,$BE,$00
XBB6F:	DEFB $28,$F2,$3D,$DD,$BE,$00,$CA,$FC,$C1,$CD,$18,$C4,$DD,$23,$FD,$CB
XBB7F:	DEFB $00,$A6,$DD,$7E,$00,$3C,$CA,$E6,$C2,$01,$07,$03,$CD,$09,$C4,$4A
XBB8F:	DEFB $21,$31,$C5,$16,$00,$19,$7E,$FD,$77,$0D,$AF,$B9,$20,$17,$FD,$CB
XBB9F:	DEFB $00,$EE,$C3,$F5,$C3,$3A,$D5,$C4,$21,$E2,$C4,$A7,$C8,$11,$13,$00
XBBAF:	DEFB $47,$19,$10,$FD,$C9,$FD,$CB,$00,$AE,$FD,$7E,$0A,$81,$01,$0C,$FF
XBBBF:	DEFB $04,$91,$30,$FC,$81,$87,$5F,$16,$00,$21,$1B,$C0,$19,$5E,$23,$56
XBBCF:	DEFB $23,$4E,$23,$7E,$04,$18,$08,$CB,$3F,$CB,$19,$CB,$3A,$CB,$1B,$10
XBBDF:	DEFB $F6,$47,$FD,$7E,$00,$E6,$42,$FE,$40,$20,$08,$FD,$73,$06,$FD,$72
XBBEF:	DEFB $07,$18,$06,$FD,$73,$08,$FD,$72,$09,$FD,$CB,$00,$7E,$28,$27,$EB
XBBFF:	DEFB $A7,$ED,$42,$CB,$3D,$CB,$3D,$FD,$7E,$10,$A7,$28,$12,$67,$7D,$FA
XBC0F:	DEFB $95,$C3,$CB,$0C,$38,$08,$87,$18,$F9,$1F,$CB,$0C,$30,$FB,$6F,$FD
XBC1F:	DEFB $75,$0E,$AF,$FD,$77,$0F,$FD,$7E,$00,$CB,$77,$28,$43,$CB,$4F,$28
XBC2F:	DEFB $06,$FD,$CB,$00,$E6,$18,$39,$FD,$6E,$06,$FD,$66,$07,$FD,$5E,$08
XBC3F:	DEFB $FD,$56,$09,$FD,$CB,$00,$1E,$AF,$ED,$52,$FD,$CB,$00,$16,$FD,$4E
XBC4F:	DEFB $0D,$1E,$80,$06,$08,$7B,$A1,$20,$04,$CB,$0B,$10,$F8,$0F,$38,$06
XBC5F:	DEFB $CB,$2C,$CB,$1D,$18,$F7,$FD,$75,$11,$FD,$74,$12,$FD,$CB,$00,$A6
XBC6F:	DEFB $FD,$36,$03,$00,$FD,$7E,$05,$FD,$77,$04,$FD,$CB,$00,$8E,$DD,$E5
XBC7F:	DEFB $D1,$13,$2A,$D3,$C4,$73,$23,$72,$C9,$01,$0F,$04,$18,$03,$DD,$56
XBC8F:	DEFB $00,$7A,$A1,$5F,$79,$2F,$A2,$57,$CB,$0A,$10,$FC,$C9,$01,$0F,$04
XBC9F:	DEFB $CD,$09,$C4,$3E,$02,$FD,$A6,$00,$FD,$77,$00,$CB,$52,$28,$04,$FD
XBCAF:	DEFB $CB,$00,$F6,$3E,$03,$A2,$28,$2E,$D5,$3D,$21,$2E,$C5,$5F,$16,$00
XBCBF:	DEFB $19,$56,$CD,$04,$C4,$FD,$73,$0C,$7A,$BB,$3E,$00,$28,$10,$30,$05
XBCCF:	DEFB $7A,$53,$5F,$3E,$80,$CB,$1B,$38,$04,$CB,$0A,$18,$F8,$B2,$FD,$77
XBCDF:	DEFB $10,$FD,$CB,$00,$FE,$D1,$21,$3F,$C5,$16,$00,$19,$56,$CD,$04,$C4
XBCEF:	DEFB $FD,$72,$05,$FD,$72,$04,$CD,$C4,$C4,$3A,$D5,$C4,$A7,$20,$04,$FD
XBCFF:	DEFB $CB,$00,$9E,$DD,$CB,$00,$7E,$C8,$DD,$23,$A7,$C0,$FD,$CB,$00,$DE
XBD0F:	DEFB $FD,$E5,$FD,$21,$1B,$C5,$DD,$5E,$00,$3E,$C0,$A3,$07,$FD,$77,$00
XBD1F:	DEFB $3E,$0F,$A3,$5F,$21,$39,$C5,$CB,$03,$16,$00,$19,$56,$CD,$04,$C4
XBD2F:	DEFB $FD,$72,$04,$FD,$72,$05,$23,$7E,$FD,$77,$06,$CD,$C4,$C4,$86,$FD
XBD3F:	DEFB $77,$07,$AF,$FD,$77,$03,$FD,$E1,$C9,$21,$4F,$C5,$16,$00,$19,$5E
XBD4F:	DEFB $19,$FD,$75,$01,$FD,$74,$02,$C9,$00,$00,$00,$00,$00,$00,$00,$00
XBD5F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XBD6F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XBD7F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XBD8F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XBD9F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
XBDAF:	DEFB $00,$00,$00,$81,$42,$48,$01,$02,$04,$06,$08,$0C,$10,$20,$12,$14
XBDBF:	DEFB $10,$0C,$36,$00,$22,$10,$42,$11,$24,$12,$41,$16,$25,$13,$34,$17
XBDCF:	DEFB $26,$44,$29,$18,$10,$09,$0F,$10,$12,$1D,$20,$2A,$2C,$2E,$04,$05
XBDDF:	DEFB $07,$09,$0A,$0B,$8C,$0C,$08,$04,$01,$80,$08,$00,$0C,$00,$07,$00
XBDEF:	DEFB $04,$00,$02,$00,$01,$80,$0C,$0A,$08,$45,$02,$00,$00,$04,$00,$00
XBDFF:	DEFB $06,$00,$00,$09,$00,$0C,$00,$40,$08,$0A,$0C,$0C,$0B,$0A,$09,$08
XBE0F:	DEFB $07,$06,$05,$04,$03,$02,$81,$CB,$C7,$CB,$C7,$CB,$C7,$3F,$C8,$53
XBE1F:	DEFB $C8,$68,$C8,$7D,$C8,$99,$C8,$B5,$C8,$12,$C6,$75,$C6,$A9,$C6,$B5
XBE2F:	DEFB $C6,$BD,$C6,$C5,$C6,$C3,$C8,$D6,$C8,$E7,$C8,$09,$C6,$FC,$C5,$EA
XBE3F:	DEFB $C5,$C8,$C5,$D2,$C5,$DF,$C5,$F8,$C8,$02,$C9,$0F,$C9,$A0,$7C,$30
XBE4F:	DEFB $3E,$FF,$7B,$5E,$FE,$FF,$FF,$B8,$7C,$31,$3E,$FF,$7B,$5E,$CE,$FF
XBE5F:	DEFB $52,$AE,$FF,$FF,$C3,$7C,$30,$3E,$FF,$FB,$44,$5E,$CE,$FF,$FF,$93
XBE6F:	DEFB $00,$95,$6A,$62,$6A,$7D,$6D,$FF,$82,$C0,$15,$FF,$03,$8D,$96,$FF
XBE7F:	DEFB $FF,$90,$23,$F5,$CA,$C2,$CA,$DD,$CD,$05,$5D,$6E,$FF,$FF,$60,$03
XBE8F:	DEFB $07,$06,$05,$A5,$B6,$FF,$FF,$90,$41,$31,$91,$95,$97,$84,$94,$FF
XBE9F:	DEFB $22,$96,$06,$CE,$06,$FF,$41,$51,$B1,$B5,$B7,$A4,$B4,$FF,$22,$B6
XBEAF:	DEFB $06,$CE,$06,$FF,$41,$59,$B9,$BD,$BF,$AC,$BC,$FF,$22,$BE,$06,$F6
XBEBF:	DEFB $06,$FF,$41,$31,$91,$95,$97,$84,$94,$FF,$22,$96,$06,$CE,$06,$FF
XBECF:	DEFB $41,$CA,$CD,$CF,$BC,$CC,$FF,$22,$CE,$06,$EE,$06,$FF,$41,$C9,$F1
XBEDF:	DEFB $F3,$03,$C9,$F1,$F3,$03,$07,$C9,$F1,$F3,$03,$FF,$55,$F2,$CA,$EA
XBEEF:	DEFB $DA,$B2,$CA,$BA,$92,$B2,$A4,$6A,$FF,$00,$62,$08,$36,$56,$6E,$7E
XBEFF:	DEFB $86,$7E,$6E,$56,$36,$56,$6E,$7E,$86,$7E,$6E,$56,$5E,$7E,$96,$A6
XBF0F:	DEFB $AE,$A6,$96,$7E,$36,$56,$6E,$7E,$86,$7E,$6E,$56,$6E,$8E,$A6,$B6
XBF1F:	DEFB $BE,$B6,$A6,$8E,$96,$7E,$6E,$56,$6E,$7E,$86,$8E,$FF,$00,$93,$05
XBF2F:	DEFB $34,$94,$54,$B4,$6C,$CC,$7C,$DC,$FF,$00,$60,$51,$32,$B5,$55,$32
XBF3F:	DEFB $FF,$FF,$C0,$51,$92,$CD,$95,$92,$FF,$FF,$60,$51,$92,$6D,$95,$92
XBF4F:	DEFB $FF,$FF,$F7,$C6,$E5,$C6,$D3,$C6,$CF,$C7,$E5,$C7,$F5,$C7,$09,$C8
XBF5F:	DEFB $15,$C8,$23,$C8,$28,$C8,$2D,$C8,$38,$C8,$03,$C7,$10,$C7,$23,$C7
XBF6F:	DEFB $46,$C7,$62,$C7,$71,$C7,$85,$C7,$94,$C7,$9D,$C7,$C8,$C7,$C2,$C7
XBF7F:	DEFB $DD,$C7,$B1,$C7,$A6,$C7,$BB,$C7,$C0,$0E,$34,$4E,$5C,$6C,$74,$6C
XBF8F:	DEFB $5E,$44,$26,$FF,$FF,$D0,$0E,$6E,$96,$6E,$56,$FF,$01,$34,$36,$FF
XBF9F:	DEFB $0E,$7C,$6C,$54,$6E,$47,$FF,$FF,$C3,$03,$94,$8C,$94,$8C,$FF,$26
XBFAF:	DEFB $76,$FF,$61,$6A,$72,$8A,$FF,$22,$8A,$FF,$03,$94,$8C,$74,$8C,$94
XBFBF:	DEFB $AC,$A4,$94,$FF,$26,$8F,$FF,$22,$80,$FF,$FF,$60,$02,$6C,$96,$04
XBFCF:	DEFB $96,$8C,$96,$94,$96,$FF,$0F,$8C,$FF,$01,$AA,$FF,$41,$B2,$FF,$22
XBFDF:	DEFB $B4,$FF,$02,$04,$96,$FF,$FF,$A8,$0F,$35,$35,$55,$6D,$6E,$04,$55
XBFEF:	DEFB $56,$04,$35,$36,$FF,$FF,$90,$0E,$0C,$36,$24,$35,$45,$4E,$44,$4D
XBFFF:	DEFB $35,$26,$34,$25,$0D,$FF,$0E,$27,$FF,$FF,$40,$02,$36,$0C,$24,$36
XC00F:	DEFB $0C,$24,$34,$4C,$0C,$4C,$36,$FF,$FF,$F0,$67,$10,$F6,$06,$16,$07
XC01F:	DEFB $FF,$FF,$27,$50,$51,$BB,$FF,$5D,$97,$FF,$FF,$03,$CA,$44,$F0,$0F
XC02F:	DEFB $FF,$8C,$01,$0C,$FF,$FF,$A0,$40,$30
	;; NB: This chunk gets destroyed by moving all the following data
	;; down during initialisation.
LC038:	DEFB $6C,$31,$6C,$41,$6C,$FF,$FF
XC03F:	DEFB $B3,$47,$10,$43,$00,$FF,$FF,$00,$86,$82,$12,$FF,$FF,$03,$86,$41
XC04F:	DEFB $11,$03,$FF,$FF,$D3,$29,$31,$51,$01,$41,$29,$01,$31,$19,$01,$29
XC05F:	DEFB $41,$01,$FF,$00,$F3,$EB,$E3,$DB,$FF,$FF,$D3,$09,$31,$51,$00,$41
XC06F:	DEFB $29,$00,$31,$19,$00,$29,$41,$00,$FF,$00,$D3,$09,$F3,$EB,$E3,$DB
XC07F:	DEFB $EB,$E3,$DB,$D3,$E3,$DB,$D3,$CB,$DB,$D3,$CB,$C3,$FF,$00,$D3,$09
XC08F:	DEFB $BB,$A3,$8B,$73,$5B,$43,$2B,$23,$FF,$00,$D3,$09,$13,$33,$53,$73
XC09F:	DEFB $93,$B3,$D3,$DB,$E3,$EE,$FF,$00,$78,$05,$33,$FF,$FF,$60,$25,$33
XC0AF:	DEFB $FF,$FF,$D3,$60,$34,$6A,$FF,$09,$01,$BA,$BA,$FF,$FF,$90,$44,$10
XC0BF:	DEFB $43,$00,$FF,$FF,$90,$41,$0C,$36,$FF,$02,$35,$35,$35,$45,$35,$45
XC0CF:	DEFB $FF,$41,$56,$FF,$21,$57,$FF,$FF,$90,$41,$0C,$6E,$FF,$02,$6D,$6D
XC0DF:	DEFB $6D,$7D,$6D,$7D,$FF,$41,$D5,$FF,$21,$D2,$D7,$FF,$FF,$90,$41,$0C
XC0EF:	DEFB $E6,$FF,$02,$B5,$B5,$B5,$C5,$B5,$C5,$FF,$41,$8D,$FF,$21,$8A,$8F
XC0FF:	DEFB $FF,$FF,$63,$02,$B2,$BA,$CC,$34,$34,$6A,$5A,$52,$6A,$92,$8A,$94
XC10F:	DEFB $C2,$CA,$DC,$44,$44,$A2,$92,$8A,$92,$8A,$7A,$6E,$FF,$FF,$C0,$03
XC11F:	DEFB $92,$8A,$94,$34,$54,$6A,$5A,$52,$6A,$92,$8A,$94,$8A,$92,$A4,$44
XC12F:	DEFB $64,$A2,$92,$8A,$92,$8A,$7A,$6D,$FF,$FF,$30,$02,$04,$36,$0E,$56
XC13F:	DEFB $36,$46,$1E,$64,$54,$47,$FF,$FF,$33,$43,$09,$33,$FF,$08,$36,$56
XC14F:	DEFB $5E,$66,$6C,$0C,$04,$FF,$02,$32,$37,$FF,$FF,$F0,$08,$04,$96,$86
XC15F:	DEFB $7E,$76,$6C,$06,$FF,$41,$94,$FF,$3E,$97,$FF,$FF,$C0,$22,$04,$96
XC16F:	DEFB $86,$7E,$76,$6C,$06,$FF,$41,$6C,$FF,$2E,$6F,$FF,$FF,$A0,$7B,$F0
XC17F:	DEFB $A6,$5E,$FF,$7C,$3E,$FF,$FF,$B8,$7B,$C0,$A6,$5E,$FF,$7C,$3E,$FF
XC18F:	DEFB $52,$27,$FF,$FF,$C3,$FC,$02,$C0,$A6,$5E,$FF,$FB,$44,$3E,$FF,$FF
XC19F:	DEFB $92
	;; End of 128K code.

	;; Start of area that gets moved down...
LC1A0:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XC1AF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

	;;  Background wall tiles
#include "panels.asm"

	DEFB $90,$00,$A0,$00

IMG_3x56:
#insert "img_3x56.bin"
IMG_3x32:	
#insert "img_3x32.bin"
IMG_3x24:			
#insert "img_3x24.bin"
IMG_4x28:			
#insert "img_4x28.bin"
IMG_2x24:
#insert "img_2x24.bin"
IMG_CHARS:
#insert "img_chars.bin"

XFA60:	DEFB $00,$03,$00,$03,$00,$3C,$00,$CF,$01,$F3,$0E,$7C,$3F,$9F,$FF
XFA6F:	DEFB $3C,$FC,$F3,$F3,$CF,$CF,$3E,$3C,$F8,$F3,$E4,$CF,$9C,$3E,$78,$79
XFA7F:	DEFB $F8,$67,$F0,$07,$C8,$78,$3C,$1F,$F0,$27,$C8,$38,$38,$5F,$F4,$4C
XFA8F:	DEFB $64,$73,$9C,$1E,$F0,$23,$88,$3C,$78,$1F,$F0,$27,$C8,$78,$3C,$7F
XFA9F:	DEFB $FC,$3F,$F8,$0F,$E0,$00,$00,$00,$00,$00,$00,$00,$00
	;; End of area that gets moved down.
	
XFAAC:	DEFB $00,$00,$00
XFAAF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFABF:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFACF:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFADF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFAEF:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFAFF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFB0F:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFB1F:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFB2F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFB3F:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFB4F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFB5F:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFB6F:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFB7F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFB8F:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFB9F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFBAF:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFBBF:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFBCF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFBDF:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFBEF:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFBFF:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFC0F:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFC1F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFC2F:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFC3F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFC4F:	DEFB $65,$72,$20,$20,$20,$20,$20,$20,$EA,$06,$00,$00,$48,$05,$0D,$00
XFC5F:	DEFB $00,$22,$0D,$80,$00,$00,$70,$5C,$00,$00,$00,$00,$00,$00,$00,$00
XFC6F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$65,$72,$20,$20,$20,$20,$20,$20
XFC7F:	DEFB $EA,$06,$00,$00,$48,$05,$0D,$00,$00,$22,$0D,$80,$00,$00,$70,$5C
XFC8F:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
XFC9F:	DEFB $65,$72,$20,$20,$42,$55,$47,$7E,$4F,$46,$46,$3B,$3B,$FD,$26,$FC
XFCAF:	DEFB $FD,$2E,$D1,$FD,$E3,$01,$2E,$00,$FD,$09,$FD,$5D,$FD,$54,$6B,$62
XFCBF:	DEFB $01,$E8,$02,$ED,$57,$E4,$08,$30,$ED,$5F,$AE,$77,$ED,$A0,$E0,$3B
XFCCF:	DEFB $3B,$E8,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
XFCDF:	DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
XFCEF:	DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
XFCFF:	DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$A7
XFD0F:	DEFB $ED,$52,$08,$21,$D1,$FC,$06,$3D,$36,$C9,$23,$10,$FB,$08,$CA,$37
XFD1F:	DEFB $FF,$FD,$21,$00,$00,$FD,$36,$75,$00,$FD,$23,$18,$F8,$3D,$20,$FD
XFD2F:	DEFB $A7,$04,$C8,$3E,$7F,$DB,$FE,$1F,$A9,$E6,$20,$28,$F4,$79,$2F,$4F
XFD3F:	DEFB $E6,$01,$F6,$08,$D3,$FE,$37,$C9,$F3,$14,$15,$3E,$02,$32,$40,$FD
XFD4F:	DEFB $3E,$0F,$D3,$FE,$21,$7E,$FF,$E5,$DB,$FE,$1F,$E6,$20,$4F,$BF,$CD
XFD5F:	DEFB $2C,$FD,$30,$FB,$21,$15,$04,$10,$FE,$2B,$7C,$B5,$20,$F9,$3E,$0A
XFD6F:	DEFB $CD,$2C,$FD,$30,$EA,$06,$C4,$3E,$16,$CD,$2C,$FD,$30,$E1,$3E,$D6
XFD7F:	DEFB $B8,$38,$F2,$06,$C4,$3E,$16,$CD,$2C,$FD,$30,$D3,$3E,$DF,$B8,$38
XFD8F:	DEFB $E4,$FD,$21,$88,$FF,$FD,$66,$00,$06,$C4,$3E,$16,$CD,$2C,$FD,$30
XFD9F:	DEFB $BE,$3E,$CD,$B8,$30,$DD,$24,$20,$EF,$06,$60,$3E,$16,$CD,$2C,$FD
XFDAF:	DEFB $30,$AD,$3E,$16,$CD,$2C,$FD,$30,$A6,$3E,$AB,$B8,$38,$0A,$FD,$23
XFDBF:	DEFB $FD,$7D,$FE,$8C,$20,$CF,$18,$C9,$3E,$01,$32,$40,$FD,$06,$B0,$2E
XFDCF:	DEFB $04,$3E,$0B,$18,$02,$3E,$0C,$CD,$2C,$FD,$D0,$00,$00,$3E,$0E,$CD
XFDDF:	DEFB $2C,$FD,$D0,$3E,$13,$3E,$C3,$B8,$CB,$15,$06,$B0,$D2,$D4,$FD,$3E
XFDEF:	DEFB $3A,$BD,$C2,$20,$FD,$26,$86,$26,$00,$06,$C4,$2E,$01,$FD,$21,$8C
XFDFF:	DEFB $FF,$3E,$07,$18,$16,$3E,$91,$AD,$C6,$86,$DD,$77,$00,$DD,$23,$1B
XFE0F:	DEFB $06,$C4,$2E,$01,$00,$3E,$05,$18,$02,$3E,$0C,$CD,$2C,$FD,$D0,$00
XFE1F:	DEFB $00,$3E,$0E,$CD,$2C,$FD,$D0,$3E,$13,$3E,$D7,$B8,$CB,$15,$06,$C4
XFE2F:	DEFB $D2,$18,$FE,$7C,$AD,$67,$7A,$B3,$20,$CB,$C3,$7D,$FF,$3E,$91,$AD
XFE3F:	DEFB $C6,$86,$DD,$77,$00,$DD,$23,$1B,$2E,$02,$3E,$04,$06,$B3,$CD,$B3
XFE4F:	DEFB $FE,$D0,$FD,$7E,$04,$B7,$28,$56,$69,$01,$FD,$7F,$ED,$79,$FD,$4E
XFE5F:	DEFB $00,$FD,$46,$01,$DD,$21,$00,$00,$DD,$09,$4D,$3E,$01,$2E,$02,$06
XFE6F:	DEFB $B3,$CD,$B3,$FE,$D0,$3E,$7F,$BD,$28,$03,$32,$36,$FF,$2E,$02,$3E
XFE7F:	DEFB $08,$06,$B3,$CD,$B3,$FE,$D0,$FD,$5E,$02,$FD,$56,$03,$69,$01,$05
XFE8F:	DEFB $00,$FD,$09,$4D,$7B,$B2,$06,$C4,$2E,$01,$3E,$05,$C2,$1A,$FE,$11
XFE9F:	DEFB $7D,$FF,$ED,$53,$3A,$FE,$11,$84,$03,$3E,$01,$C3,$1A,$FE,$3E,$06
XFEAF:	DEFB $18,$BB,$3E,$0C,$CD,$2C,$FD,$00,$00,$3E,$0E,$CD,$2C,$FD,$D0,$3E
XFEBF:	DEFB $DB,$B8,$CB,$15,$06,$B3,$D2,$B1,$FE,$C9,$CD,$47,$FD,$21,$00,$90
XFECF:	DEFB $06,$FF,$C5,$CD,$DE,$FE,$73,$23,$C1,$10,$F7,$CD,$FA,$FE,$C9,$1E
XFEDF:	DEFB $00,$4B,$06,$FF,$3E,$7F,$DB,$FE,$E6,$40,$A9,$28,$09,$1C,$79,$2F
XFEEF:	DEFB $E6,$40,$4F,$10,$EF,$C9,$00,$00,$C3,$F2,$FE,$21,$00,$00,$11,$32
XFEFF:	DEFB $90,$06,$32,$C5,$1A,$06,$00,$4F,$09,$13,$C1,$10,$F6,$E5,$21,$00
XFF0F:	DEFB $00,$11,$CD,$90,$06,$32,$C5,$1A,$06,$00,$4F,$09,$13,$C1,$10,$F6
XFF1F:	DEFB $C1,$7C,$FE,$0D,$30,$0D,$A7,$ED,$42,$D8,$01,$32,$00,$A7,$ED,$42
XFF2F:	DEFB $D8,$3E,$01,$32,$36,$FF,$C9,$00,$F3,$31,$FF,$FF,$21,$00,$58,$01
XFF3F:	DEFB $03,$00,$36,$00,$23,$10,$FB,$0D,$20,$F8,$DD,$21,$00,$A0,$11,$11
XFF4F:	DEFB $00,$CD,$C9,$FE,$DD,$21,$00,$40,$11,$FF,$1A,$21,$3C,$FE,$22,$3A
XFF5F:	DEFB $FE,$CD,$47,$FD,$3A,$36,$FF,$B7,$C4,$20,$FD,$FD,$21,$3A,$5C,$ED
XFF6F:	DEFB $56,$21,$58,$27,$D9,$AF,$ED,$4F,$31,$FF,$FF,$C3,$30,$70,$D1,$AF
XFF7F:	DEFB $D3,$FE,$7C,$FE,$01,$D8,$CD,$20,$FD,$18,$28,$22,$20,$A8,$61,$2F
XFF8F:	DEFB $23,$10,$D8,$D6,$D9,$23,$10,$04,$FE,$01,$00,$10,$3C,$FE,$03,$00
XFF9F:	DEFB $10,$D0,$84,$55,$2F,$10,$63,$FF,$19,$00,$10,$00,$5B,$AD,$06,$10
XFFAF:	DEFB $1E,$B4,$3F,$1F,$10,$00,$00,$00,$00,$00,$DD,$F9,$80,$FD,$CB,$01
XFFBF:	DEFB $A6,$2E,$24,$D9,$DD,$00,$80,$00,$00,$7C,$B8,$02,$0F,$B1,$33,$00
XFFCF:	DEFB $80,$00,$00,$8A,$B8,$02,$0F,$B1,$33,$00,$80,$00,$00,$E0,$B8,$02
XFFDF:	DEFB $0F,$B1,$33,$BB,$63,$6A,$32,$9B,$36,$65,$33,$B7,$2D,$BB,$63,$B6
XFFEF:	DEFB $63,$9C,$1E,$92,$1E,$50,$00,$1F,$BD,$FE,$25,$FE,$7E,$FF,$63,$FF
