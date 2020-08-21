#!/bin/sh
set -e

# Go the sources directory to run commands
SOURCE="${BASH_SOURCE[0]}"
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd $DIR
echo $(pwd)

rm -rf ../fonts


echo "Generating Static fonts"
mkdir -p ../fonts/ttf
fontmake -m Caveat.designspace -i -o ttf --output-dir ../fonts/ttf/
# fontmake -m Caveat.designspace -i -o otf --output-dir ../fonts/otf/

echo "Generating VFs"
mkdir -p ../fonts/variable/
fontmake -m Caveat.designspace -o variable --output-path ../fonts/variable/Caveat[wght].ttf


rm -rf master_ufo/ instance_ufo/ instance_ufos/


echo "Post processing"
ttfs=$(ls ../fonts/ttf/*.ttf)
for ttf in $ttfs
do
	gftools fix-dsig -f $ttf;
	python3 -m ttfautohint $ttf "$ttf.fix";
	mv "$ttf.fix" $ttf;
done

vfs=$(ls ../fonts/variable/*.ttf)

echo "Post processing VFs"
for vf in $vfs
do
	gftools fix-dsig -f $vf;
	# ttfautohint-vf --stem-width-mode nnn $vf "$vf.fix";
	# mv "$vf.fix" $vf;
done



echo "Fixing VF Meta"
gftools fix-vf-meta $vfs;

echo "Dropping MVAR"
for vf in $vfs
do
	mv "$vf.fix" $vf;
	ttx -f -x "MVAR" $vf; # Drop MVAR. Table has issue in DW
	rtrip=$(basename -s .ttf $vf)
	new_file=../fonts/variable/$rtrip.ttx;
	rm $vf;
	ttx $new_file
	rm $new_file
done


echo "Fix Hinting"
for vf in $vfs
do
	gftools fix-nonhinting $vf $vf.fix;
	mv "$vf.fix" $vf;
done

for ttf in $ttfs
do
	gftools fix-hinting $ttf;
	mv "$ttf.fix" $ttf;
done

rm -f ../fonts/variable/*.ttx
rm -f ../fonts/ttf/*.ttx
rm -f ../fonts/variable/*gasp.ttf
rm -f ../fonts/ttf/*gasp.ttf
