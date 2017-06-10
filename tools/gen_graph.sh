#!/bin/sh

set -e

mkdir -p ../out/graphs

lua ./xrefs.lua $(find ../src -name '*.asm')

# dot -Tsvg ../out/graphs/HOH.dot > ../out/graphs/HOH.svg

for FILE in ../out/graphs/*.dot
do
  DEST=$(echo $FILE | sed 's/dot$/svg/')
  dot -Tsvg $FILE > $DEST
done
