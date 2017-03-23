	;; 
	;; equs.asm
	;;
	;; Constants file.
	;;
	
	;; All 16-bit constants have been replaced with a 'LXXXX'
	;; label, allowing search and replace of interesting constants
	;; with nice names.
	;;
	;; This file EQUs up those ugly names.
	;;
	;; FIXME: It should go away!
	;; 

L0000:	EQU $0000
L0001:	EQU $0001
L0002:	EQU $0002
L0003:	EQU $0003
L0004:	EQU $0004
L0005:	EQU $0005
L0006:	EQU $0006
L0007:	EQU $0007
L0008:	EQU $0008
L0009:	EQU $0009
L000A:	EQU $000A
L0010:	EQU $0010
L0012:	EQU $0012
L0018:	EQU $0018
L0020:	EQU $0020
L0040:	EQU $0040
L0043:	EQU $0043
L0048:	EQU $0048
L00F8:	EQU $00F8
L00FE:	EQU $00FE
L00FF:	EQU $00FF
L0100:	EQU $0100
L0104:	EQU $0104
L0401:	EQU $0401
L040F:	EQU $040F
L05FF:	EQU $05FF
L0606:	EQU $0606
L0804:	EQU $0804
L0808:	EQU $0808
L080C:	EQU $080C
L091B:	EQU $091B
L1004:	EQU $1004
L1800:	EQU $1800
L180C:	EQU $180C
L390C:	EQU $390C
L4000:	EQU $4000
L40C0:	EQU $40C0
L4C50:	EQU $4C50
L5800:	EQU $5800
L6088:	EQU $6088
L7FFD:	EQU $7FFD 		; Numeric constant

	;; References into code area.
L8940:	EQU $8940		; Numeric constant? Tail start room?
L8A40:	EQU $8A40		; Numeric constant? Head start room?
LA800:	EQU $A800		; Numeric constant?

LAF80:	EQU $AF80		; Numeric constant?
        
	;; Data-ish stuff
Buffer:	EQU $BF20               ; Buffer area used by controls and sprite-rotation code.
LC000:	EQU $C000
LC043:	EQU $C043
LC0C0:	EQU $C0C0
OtherState:	EQU $FB28       ; Where the other character's state is held. Starts with room id.
LFB49:	EQU $FB49
LFEFE:	EQU $FEFE
LFF7F:	EQU $FF7F
LFFEE:	EQU $FFEE
LFFF5:	EQU $FFF5
LFFFE:	EQU $FFFE
LFFFF:	EQU $FFFF
