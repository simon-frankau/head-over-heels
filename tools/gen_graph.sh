#!/bin/sh

set -e

lua ./xrefs.lua ../out/HOH.list > ../out/HOH.dot
dot -Tsvg ../out/HOH.dot > ../out/HOH.svg

for FILE in sprite menus gameover screen end objfns 37 ct15 loop entry tablecall
do
  dot -Tsvg $FILE.dot > $FILE.svg
done
