
	;; Pointer to object in HL
RemoveObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	Unlink
		POP	IY
		POP	HL
		CALL	DrawObject
		POP	IX
		SET	7,(IX+$04)
	;; Transfer top bit of Phase to IX+$0A
		LD	A,(Phase)
		LD	C,(IX+$0A)
		XOR	C
		AND	$80
		XOR	C
		LD	(IX+$0A),A
		RET

DrawObject:     PUSH    IY
        ;; Bump to an obj+2 pointer for call to GetObjExtents.
                INC     HL
                INC     HL
                CALL    GetObjExtents
        ;; Move X extent from BC to HL, Y extent from HL to DE.
                EX      DE,HL
                LD      H,B
                LD      L,C
        ;; Then draw where the thing is.
                CALL    Draw
                POP     IY
                RET

InsertObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	EnlistAux
		POP	IY
		POP	HL
		CALL	DrawObject
		POP	IX
		RES	7,(IX+$04)
		LD	(IX+$0B),$FF
		LD	(IX+$0C),$FF
		RET
