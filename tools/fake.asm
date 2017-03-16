;; Fake edges for computed jumps and self-modifying code and self-modifying code

;; TODO: Extra self-modifying code at L72F0, L7348, L8763

CallObjFn:
        CALL ObjFnPushable
        CALL ObjFnRollers1
        CALL ObjFnRollers2
        CALL ObjFnRollers3
        CALL ObjFnRollers4
        CALL ObjFnVisor1
        CALL ObjFnMonocat
        CALL ObjFnAnticlock
        CALL ObjFnRandB
        CALL ObjFnBall
        CALL ObjFnBee
        CALL ObjFnRandQ
        CALL ObjFnRandR
        CALL ObjFnSwitch
        CALL ObjFnHomeIn
        CALL ObjFnHeliplat3
        CALL ObjFnFade
        CALL ObjFnHeliplat
        CALL ObjFn19
        CALL ObjFnDissolve2
        CALL ObjFn21
        CALL ObjFn22
        CALL ObjFnHeliplat2
        CALL ObjFnDissolve
        CALL ObjFnFire
        CALL ObjFn26
        CALL ObjFnTeleport
        CALL ObjFnSpring
        CALL ObjFnRobot
        CALL ObjFnJoystick
        CALL ObjFnHushPuppy
        CALL ObjFn32
        CALL ObjFn33
        CALL ObjFnDisappear
        CALL ObjFn35
        CALL ObjFn36
        CALL ObjFnCrowny
        RET

ObjFnDissolve:
        JP ObjFnDissolve2

ObjFnHeliplat2:
        JP ObjFnHeliplat

GSP_2:
        CALL PickUp2
        CALL BoostDonuts
        CALL BoostSpeed
        CALL BoostSpring
        CALL BoostInvuln
        CALL BoostLives
        CALL SaveContinue
        CALL GetCrown
        RET

DoTurn:
        ;; TODO
        RET

BC_Copy:
        CALL OneColBlitL
        CALL OneColBlitR
        CALL TwoColBlit
        RET

BC_Clear:
        CALL ClearOne
        CALL ClearTwo
        RET

BC_Bottom:
        CALL ClearOne
        CALL ClearTwo
        RET

BC_Clear2:
        CALL ClearOne
        CALL ClearTwo
        RET

DBE_L:
        CALL OneColBlitL
        CALL OneColBlitR
        CALL TwoColBlit
        RET

DoCopy:
        CALL OneColBlitL
        CALL OneColBlitR
        CALL TwoColBlit
        RET

DoClear:
        CALL ClearOne
        CALL ClearTwo
        RET

BlitFloorFnPtr:
        CALL BlitFloorL
        CALL BlitFloorR
        CALL BlitFloor
        RET

SensFnCall:
        CALL LowSensFn
        CALL HighSensFn
        RET

WhichEdge:
        CALL DBE_R
        CALL DBE_C
        CALL DBE_L
        RET

BR_2:
        CALL BlitRot2on3
        CALL BlitRot4on3
        CALL BlitRot6on3
        CALL BlitRot2on4
        CALL BlitRot4on4
        CALL BlitRot6on4
        RET

BR_3:
        CALL BlitRot2on3
        CALL BlitRot4on3
        CALL BlitRot6on3
        CALL BlitRot2on4
        CALL BlitRot4on4
        CALL BlitRot6on4
        RET

PrintChar:
        CALL PrintCharBase
        CALL PrintFn5
        CALL PrintFn7
        CALL PrintFn6
        CALL PrintFn6b
        RET

BO_2:
        CALL BlitMask1of3
        CALL BlitMask2of3
        CALL BlitMask3of3
        CALL BlitMask1of4
        CALL BlitMask2of4
        CALL BlitMask3of4
        CALL BlitMask4of4
        CALL BlitMask1of5
        CALL BlitMask2of5
        CALL BlitMask3of5
        CALL BlitMask4of5
        CALL BlitMask5of5
        RET

DoMoveAux:
        CALL PostMove
        CALL Up
        CALL Down
        CALL Left
        CALL Right
        CALL UpLeft
        CALL UpRight
        CALL DownLeft
        CALL DownRight
        RET

;        CALL SomeTableArg0
;        CALL SomeTableArg2
;        CALL SomeTableArg4
;        CALL SomeTableArg6
