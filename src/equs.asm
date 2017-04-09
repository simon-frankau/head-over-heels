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

OtherState:	EQU $FB28       ; Where the other character's state is held. Starts with room id.
LFB49:	EQU $FB49
