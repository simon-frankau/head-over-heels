# rooms directory: Decode room description to current room state

This directory contains the routines to set all the current-room state
in line with the compressed room data definitions.

It includes:

 * **room_utils.asm** A couple of utilities, including the function to
   read bit-packed data.
 * **room_data.asm** The bit-packed room definitions.
 * **walls.asm** The code to handle the walls of the room.
 * **room.asm** The code to handle the main room definition.

The files in this directory depend upon utils/fill_zero.asm and
gfx[12]/*.asm.

They rely on the following further symbols defined elsewhere:

 * AddObject
 * AddSpecials
 * IMG_WALLS
 * InitObj
 * LAF92
 * ObjDest
 * OccludeDoorway
 * PanelFlips
 * RoomId
 * RoomMask
 * SetObjList
 * ToDoorId

Many of the symbols exported are used by the gfx2 layer.

They export the following symbols used elsewhere:

 * AddObjOpt
 * AttribScheme
 * BuildRoom2
 * BuildRoom
 * DoorLocsCopy
 * FloorAboveFlag
 * FloorCode
 * HasDoor
 * HasNoWall
 * MaxU
 * MaxV
 * MinU
 * MinV
 * SetTmpObjUVZ
 * SetUVZ
 * TmpObj
 * WorldId
