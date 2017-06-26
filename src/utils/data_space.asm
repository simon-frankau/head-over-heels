;;
;; data_space.asm
;;
;; Space for buffers etc.
;;

;; This data area sits in the space between where memory patch-up/128K
;; sound code starts (0xB7A8), and where the moved-down starts
;; (0xC1A0 - MAGIC_OFFSET = 0xC038).

;; Offscreen buffer that's the source for BlitScreen.
ViewBuff:       EQU $B800

;; 256 bytes used as a bit-reverse table.
RevTable:       EQU $B900

;; This buffer gets filled with info that DrawFloor reads.
;; 16 words describing the 16 double-columns
;;
;; NB: Page-aligned
;;
;; Byte 0: Y of wall bottom (0 = clear)
;; Byte 1: Id for wall panel sprite
;;         (0-3 - world-specific, 4 - columns, 5 - space, | $80 to flip)
BkgndData:      EQU $BA00
BkgndDataLen:   EQU $0040

;; Array where we actually write the objects.
Objects:        EQU $BA40
ObjectsLen:     EQU $03F0       ; Goes up to $BE20.

;;  Buffer area used by controls and sprite-rotation code.
Buffer:         EQU $BF20
;; TODO: Length?

;; This data area sits after the moved-down data.
;; (MoveDownEnd - MAGIC_OFFSET = 0xF944)

;; Buffer for drawing columns into.
ColBuf:         EQU $F944
ColBufLen:      EQU TALL_WALL * 2       ; 2 bytes wide.

;; Immediately follows ColBuf.
DoorwayBuf:     EQU $F9D8
DoorwayBufLen:  EQU 3 * 56 * 2          ; Includes image and mask.

;; Immediately follows DoorwayBuf.
;;  Where the other character's state is held. Starts with room id.
OtherState:     EQU $FB28
;; TODO: This appears to be the OtherState version of what's at LA2A2.
LFB49:          EQU OtherState + 33
