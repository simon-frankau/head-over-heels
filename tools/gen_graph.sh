#!/bin/sh

set -e

lua ./xrefs.lua ../out/HOH.list
dot -Tsvg ../out/HOH.dot > ../out/HOH.svg

for FILE in sprite menus gameover enter screen end tablecall objfns 37 ct15 loop entry
do
  dot -Tsvg $FILE.dot > $FILE.svg
done
