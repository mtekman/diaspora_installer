#!/bin/bash

#sudo pacman -S python2-markdown tar aria2 jansson

#runner="echo"

# EDIT THESE:
diaspora_main_url="http://diaspora.fs2downloads.com/Diaspora_R1_Linux.tar.lzma.torrent"
diaspora_patch_url="https://copy.com/8wo3AQnYu0bj?download=1"
dest_dir="./opt_Diaspora/"


#Main alias, automatically resumes
aria2_d="aria2c --console-log-level=error -V -c --seed-time=0 -O"
aria2_d="aria2c --console-log-level=error -V --seed-time=0 -O"


#Get main file and 1.1 patch
outfold=/$(readlink -f ./)

diaspora_main=$outfold/"Diaspora_R1_Linux.tar.lzma"
diaspora_patch=$outfold/"Diaspora_R1_Patch_1.1.tar.lzma"

clear

if [ : ]; then

echo "Diaspora Installer Script"
echo "========================="
#wget -O "main.torrent" $diaspora_main_url
echo ""
echo "Stage 1a: Downloading Main file (torrent)"
$runner $aria2_d 1=/$diaspora_main $diaspora_main_url
#$runner $aria2_d 1="main.torrent" $diaspora_main_url
#$runner $aria2_d 1=$diaspora_main "main.torrent"
echo ""
echo "Stage 1b: Downloading Patch"
$runner $aria2_d 1=/$diaspora_patch $diaspora_patch_url
echo ""

fi

function untar_all(){
	to=$1
	file=$2
    tar -C $to --checkpoint=300 --checkpoint-action='ttyout=\r%u' --lzma -xf  $file
}


echo "Stage 2a: Unpacking Main file"
$runner mkdir -p $dest_dir
$runner untar_all $dest_dir $diaspora_main 
echo ""
echo "Stage 2b: Unpacking Patch file"
$runner untar_all $dest_dir $diaspora_patch

patch_file_tar=$(readlink -f $(find $dest_dir -name "*Patch*.tar"))
diaspora_fold=$(readlink -f $(find $dest_dir -type d -name "Diaspora"))


echo "Stage 2c: Applying Patch..."
$runner tar -C $diaspora_fold --checkpoint=1000 --checkpoint-action=dot -xf $patch_file_tar
echo ""

cd $diaspora_fold

echo ""
echo "Stage 3a: Building FS2 Open"
cd fs2_open
$runner LDFLAGS="-l:liblua.so.5.1 $LDFLAGS" CXXFLAGS="-I/usr/include/lua5.1 $CXXFLAGS" ./autogen.sh
$runner make
$runner mv code/fs2_open_* ../fs2_open_diaspora
cd ..


echo ""
echo "Stage 3b: Building wxLauncher"

launcher_patch_url=https://wxlauncher.googlecode.com/issues/attachment?aid=930010000&name=wxlauncher_homedir.patch&token=ABZ6GAdjC8In36ECIYOtPby8m0jYh99_3Q%3A1412610881778
launcher_patch="wxLauncher.patch"
apply_place="code/apis/"

cd wxlauncher
echo "Stage 3bi: Applying fix"
$runner wget -O $launcher_patch $launcher_patch_url
$runner mv $launcher_patch $apply_place
cd $apply_place
$runner patch < $launcher_patch
cd ../../

#back into wxLauncher
cd build/
$runner cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python2\
 -D USE_OPENAL=1\
 -D CMAKE_BUILD_TYPE=RelWithDebInfo\
 -D DEVELOPMENT_MODE=1\
 -DwxWidgets_CONFIG_EXECUTABLE=/usr/bin/wx-config-2.8 ../
$runner make
cd ../../

#back into Diaspora fold
echo ""
echo "Stage 4: Configuring Launcher"
profile=pro00099.ini
$runner cp pro00099.template.ini $profile
$runner chmod 644 $profile
$runner sed -i "s~^folder=.*~folder=`pwd`~" $profile

$runner ./wxlauncher/build/wxlauncher --add-profile --profile=Diaspora --file=$profile
$runner ./wxlauncher/build/wxlauncher --select-profile --profile=Diaspora

echo ""
echo ""
echo "Finished: Run \"$(readlink -f ./wxlauncher/build/wxlauncher)\""
