#!/bin/bash


DEBUG=`test 0 = 0`


# EDIT THESE:
diaspora_main_url="http://diaspora.fs2downloads.com/Diaspora_R1_Linux.tar.lzma.torrent"
diaspora_patch_url="https://copy.com/8wo3AQnYu0bj?download=1"
dest_dir="./opt_Diaspora/"


#Install torrent client
#yaourt -S aria2

#Main alias, automatically resumes
aria2_d="aria2c --console-log-level=error -V -c --seed-time=0 -O"

#Get main file and 1.1 patch
outfold=$(readlink -f ./)

diaspora_main=$outfold/"Diaspora_R1_Linux.tar.lzma"
diaspora_patch=$outfold/"Diaspora_1_1_1_patch.tar.lzma"

clear
$DEBUG && echo "$diaspora_main $diaspora_patch"


echo ""
echo "Downloading Main file (torrent)"
$aria2_d 1=$diaspora_main $diaspora_main_url
echo ""
echo "Downloading Patch"
$aria2_d 1=$diaspora_patch $diaspora_patch_url


echo "Finished Downloading"
echo ""
echo "Unpacking Main file"
mkdir -p $dest_dir
tar -C $dest_dir --lzma -xvf $diaspora_main
echo ""
#echo "Unpacking Patch file"
#tar -C $dest_dir
