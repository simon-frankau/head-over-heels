# gfx2 directory: Higher-level graphics routines

This directory contains the routines to draw a room full of objects.
Specifically:

 * **columns.asm** draws the columns on which door stand.
 * **get_sprite.asm** accesses the sprites neede (with flipping, etc.).
 * **background.asm** draws the floor and walls.
 * **init_bkgnd.asm** initialises various of the variables used.
 * **scene.asm** renders the scene
 * **occlude.asm** Code to fix up door sprites when they're occluded
   by the walls.

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
 * ScreenMaxV
 * ScreenMaxU
 * MAGIC_OFFSET
 * ObjectLists
 * PanelBase
 * PanelFlipsPtr
 * SpriteFlips

They export the following symbols used elsewhere:

 * DoorwayBuf
 * Draw
 * DrawXSafe
 * GetObjExtents
 * GetSpriteAddr
 * InitRevTbl
 * IntersectObj
 * JpIX
 * OccludeDoorway
 * SPR_*
 * SetColHeight
 * SetFloorAddr
 * SpriteCode
 * SpriteFlags
 * StoreObjExtents
 * UnionAndDraw
 * ViewXExtent
 * ViewYExtent
