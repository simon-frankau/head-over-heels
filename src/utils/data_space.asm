;;
;; data_space.asm
;;
;; Space for buffers etc. that overlaps with the 128K sound code.
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
;; Byte 0: Y start (0 = clear)
;; Byte 1: Id for wall panel sprite
;;         (0-3 - world-specific, 4 - blank, 5 - columns, | $80 to flip)
BkgndData:      EQU $BA00

;; TODO
LBA40:          EQU $BA40
LBA48:          EQU $BA48

;;  Buffer area used by controls and sprite-rotation code.
Buffer:         EQU $BF20
;; TODO: Length?
