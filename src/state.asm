StatusReinit:	DEFB $09	; Number of bytes to reinit with
	
		DEFB $00	; Inventory reset
		DEFB $00	; Speed reset
		DEFB $00	; Springs reset
		DEFB $00	; Heels invuln reset
		DEFB $00	; Head invuln reset
		DEFB $08	; Heels lives reset
		DEFB $08	; Head lives reset
		DEFB $00	; Donuts reset
		DEFB $00	; FIXME
	
Inventory:	DEFB $00	; Bit 0 purse, bit 1 hooter, bit 2 donuts FIXME
Speed:		DEFB $00	; Speed
		DEFB $00	; Springs
Invuln:		DEFB $00	; Heels invuln
		DEFB $00	; Head invuln
Lives:		DEFB $04	; Heels lives
		DEFB $04	; Head lives
Donuts:		DEFB $00	; Donuts
LA293:		DEFB $00
Character:	DEFB $03	; $3 = Both, $2 = Head, $1 = Heels
InSameRoom:	DEFB $01
LA296:	DEFB $00
LA297:	DEFB $00
InvulnModulo:	DEFB $03
SpeedModulo:	DEFB $02
	
ReinitThing:	DEFB $03	; Three bytes to reinit with
	
		DEFB $00
		DEFB $00
		DEFB $FF
	
LA29E:		DEFB $00
LA29F:		DEFB $00
IsStill:	DEFB $FF        ; $00 if moving, $FF if still

TickTock:	DEFB $02         ; Phase for moving
LA2A2:		DEFB $00
EntryPosn:	DEFB $00,$00,$00 ; Where we entered the room (for when we die).
LA2A6:		DEFB $03
Carrying:	DEFW $0000	 ; Pointer to carried object.
	
FiredObj:	DEFB $00,$00,$00,$00,$20
		DEFB $28,$0B,$C0
		DEFB $24,$08
		DEFB $12
		DEFB $FF,$FF,$00,$00
		DEFB $08,$00,$00
	
CharDir:	DEFB $0F        ; Bitmask of direction, suitable for passing to LookupDir.
SavedObjListIdx:	DEFB $00
OtherSoundId:	DEFB $00
SoundId:	DEFB $00	 ; Id of sound, +1 (0 = no sound)
Movement:	DEFB $FF
	
HeelsObj:	DEFB $00
LA2C1:	DEFB $00,$00,$00,$08
LA2C5:	DEFB $28,$0B,$C0
HeelsFrame:	DEFB $18,$21,$00,$FF,$FF
LA2CD:	DEFB $00,$00,$00,$00
LA2D1:	DEFB $00
	
HeadObj:	DEFB $00,$00,$00,$00,$08
LA2D7:	DEFB $28,$0B,$C0
HeadFrame:	DEFB $1F,$25,$00,$FF,$FF
LA2DF:	DEFB $00,$00
LA2E1:	DEFB $00,$00,$00

HeelsLoop:      DEFB $00,SPR_HEELS1,SPR_HEELS2,SPR_HEELS1,SPR_HEELS3,$00
HeelsBLoop:     DEFB $00,SPR_HEELSB1,SPR_HEELSB2,SPR_HEELSB1,SPR_HEELSB3,$00
HeadLoop:       DEFB $00,SPR_HEAD1,SPR_HEAD2,SPR_HEAD1,SPR_HEAD3,$00
HeadBLoop:      DEFB $00,SPR_HEADB1,SPR_HEADB2,SPR_HEADB1,SPR_HEADB3,$00
VapeLoop1:      DEFB $00, SPR_VAPE1, $80 | SPR_VAPE1
                DEFB $80 | SPR_VAPE2, SPR_VAPE2, $80 | SPR_VAPE2
                DEFB $80 | SPR_VAPE3, SPR_VAPE3, SPR_VAPE3, $80 | SPR_VAPE3, $80 | SPR_VAPE3
                DEFB SPR_VAPE3, SPR_VAPE3, $00
VapeLoop2:      DEFB $00, SPR_VAPE3, $80 | SPR_VAPE3, SPR_VAPE3, $80 | SPR_VAPE3
                DEFB $80 | SPR_VAPE2, SPR_VAPE2, SPR_VAPE1, $80 | SPR_VAPE2, $00
