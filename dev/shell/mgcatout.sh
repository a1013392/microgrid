#!/bin/bash
#./mgcatout.sh
# Shell script to concatenate output files from computer simulation into a
# single file.

datadir=/Users/starca/projects/microgrid/dev/data
indir=$datadir/out/miqp/oneprd
echo "Input data directory: $indir"
outdir=$datadir/out/miqp/oneprd
outfile=miqp_oneprd_75HH.csv
echo "Output data file: $outdir/$outfile"
simrun=QP75HHONEPRD

cd $indir
for file in *_HH????.csv
do
	# Delete header row and insert column identifying simulation run in each output
	# files from computer simulation, and concatenate files into a single file
	sed -e '1d' -e "s/^/$simrun,/g" $file >> $outdir/$outfile
	# Count rows in file
	echo "$(wc -l $file)"
done

echo "$(wc -l $outdir/$outfile)"

