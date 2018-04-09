#!/bin/bash
#./mgcatin.sh
# Shell script to concatenate household data files into a single microgrid file 
# and insert a column identifying rows belonging to each household.  Microgrid 
# file, which is loaded into relational database, is input to computer 
# simulations.

workdir=$PWD
datadir=/Users/starca/projects/microgrid/dev/data
indir=$datadir/salisbury/20170530
echo "Input data directory: $indir"
outdir=$datadir/salisbury
echo "Output data directory: $outdir"
outfile=salisbury_30min.csv

cd $indir
for file in *.csv
do
	# Extract hhid from filename
	hhid=${file##*_}
	hhid=${hhid%%.*}
	# Remove header (first) row from data file
	# sed -i.bak '1d' $file (sed -i '' will not back-up original file)
	sed -i '' '1d' $file
	# Remove first column (row number) from data file
	cut -d, -f2,3,4,5,6,7,8,9 $file | sponge $file
	# Insert column with Household ID (use double quotes to expand variable $hhid)
	sed -i '' "s/^/$hhid,/g" $file
	# Count rows in file
	echo "$(wc -l $file)"
done

# Concatentate household data files into single microgrid file
files=$(ls *.csv)
cat $files > $outdir/$outfile
echo "$(wc -l $files)"
echo "$(wc -l $outdir/$outfile)"

