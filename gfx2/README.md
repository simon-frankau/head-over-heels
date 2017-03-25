# gfx2 directory: Higher-level graphics routines

This directory contains the routines to draw a room full of objects.
Specifically:

 * **columns.asm** draws the columns on which door stand.
 * **get_sprite.asm** accesses the sprites neede (with flipping, etc.).
 * **background.asm** draws the floor and walls.
 * **scene.asm** renders the scene

The files in this directory depend upon utils/fill_zero.asm and
gfx1/*.asm.

They rely on the following symbols defined elsewhere:

 * IMG_2x24
 * IMG_3x24
 * IMG_3x32
 * IMG_3x56
 * IMG_4x28
 * IMG_ColBottom
 * IMG_ColMid
 * IMG_ColTop
 * BkgndData
 * CornerX
 * DoorwayTest
 * HasDoor
 * HasNoWall
 * L0606
 * L0808
 * L84C7
 * L84C8
 * MAGIC_OFFSET
 * ObjectLists
 * PanelBase
 * PanelFlipsPtr
 * SpriteFlips

They export the following symbols used elsewhere:

 * CheckAndDraw
 * CheckYAndDraw
 * CornerPos
 * DoCopy
 * DoorwayBuf
 * DoorwayFlipped
 * FloorFn
 * GetObjExtents2
 * GetSpriteAddr
 * InitRevTbl
 * IntersectObj
 * LeftAdj
 * RightAdj
 * SPR_*
 * SetColHeight
 * SetFloorAddr
 * Sprite3x56
 * SpriteCode
 * SpriteFlags
 * StoreObjExtents
 * UnionAndDraw
 * ViewXExtent
 * ViewYExtent
