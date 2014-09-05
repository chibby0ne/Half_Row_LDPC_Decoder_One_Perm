#!/bin/bash

sed -i.bak '/2,/d' $1
sed -i.bak 's/, /\'$'\n/g' $1
sed -i.bak '/Starting/d' $1
sed -i.bak '/Ending/d' $1
sed -i.bak '/SNR/d' $1
sed -i.bak '/^$/d' $1
