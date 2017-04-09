;;
;; screen_vars.asm
;;
;; Variables related to screen-drawing stuff
;;

;; Room origin, in double-pixel coordinates, for attrib-drawing.
RoomOrigin:     DEFW $0000

;; Attributes array for different styles of attribs.
Attrib0:        DEFB $00
Attrib1:        DEFB $43
Attrib2:        DEFB $45
Attrib3:        DEFB $46
