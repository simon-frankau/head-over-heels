#!/bin/sh

set -e

lua ./xrefs.lua ../out/HOH.list > ../out/HOH.dot
dot -Tsvg -v ../out/HOH.dot > ../out/HOH.svg
