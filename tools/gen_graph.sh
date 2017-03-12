#!/bin/sh

set -e

mkdir -p ../out/graphs

lua ./xrefs.lua ../out/HOH.list
dot -Tsvg ../out/graphs/HOH.dot > ../out/graphs/HOH.svg

for FILE in sprite menus gameover enlist enter1 enter screen background \
  end tablecall objfns 37 ct15 loop entry
do
  dot -Tsvg ../out/graphs/$FILE.dot > ../out/graphs/$FILE.svg
done
