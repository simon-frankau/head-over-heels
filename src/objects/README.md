# objects directory: Object manipulation

This is a mixture of object creation/manipulation, object running and
object list manipulation.

It contains:

 * **objects.asm** provides a few basic object-handling functions,
   plus definitions for objects.
 * **obj_fns.asm** contains the functions that implement the objects
   behaviours.
 * **depthcmp.asm** sorts two objects into depth order, a requirement
   of the sort object linked list.
 * **procobj.asm** performs various operations on these linked lists.

The files other than obj_fns.asm rely on these symbols:

 * IntersectObj
 * MaxU
 * MaxV
 * MinU
 * MinV
 * ObjDest
 * ObjListAPtr
 * ObjListBPtr
 * ObjListIdx
 * SPR_*
 * SetFacingDir
 * SetObjList
 * SetSound
 * SortObj
 * SyncDoubleObject

obj_fns.asm, as it implements a whole pile of different object
behaviours, depends on a bunch of extra symbols:

 * CharDir
 * Character
 * ChkSatOn
 * DoContact2
 * GetCharObj
 * LookupDir
 * Move
 * ObjectLists
 * PlaySound
 * Random
 * RemoveObject
 * SetFacingDirEx
 * StoreObjExtents
 * UnionAndDraw
 * UpdateCurrPos
 * WorldMask

They export the following symbols used elsewhere:

 * ANIM_FISH
 * AddObject
 * CallObjFn
 * CurrObject
 * Enlist
 * EnlistAux
 * GetUVZExtentsB
 * GetUVZExtentsE
 * InitObj
 * OBJFN_26
 * OBJFN_DISAPPEAR
 * OBJFN_FADE
 * ObjFn36Val
 * Relink
 * SetObjSprite
 * Unlink
