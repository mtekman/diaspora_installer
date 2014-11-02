#!/bin/bash

# Arch:
#sudo pacman -S python2-markdown tar aria2 jansson

# Debian
#sudo apt-get install\
# libsdl1.2-dev libogg-dev libvorbis-dev\
# libtheora-dev libopenal-dev libjansson-dev liblua5.1-0-dev libwxgtk2.8-dev


progressfilt ()
{
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag; then
            printf '%c' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]; then
                count=0
            else
                ((count++))
                if ((count > 1)); then
                    flag=true
                fi
            fi
        fi
    done
}


#runner="echo"

### Config
OS="ubuntu"
#downloading="Y"
#unpacking="Y"
#patching="Y"
building="Y"
configuring="Y"


# EDIT THESE:
diaspora_main_url="http://diaspora.fs2downloads.com/Diaspora_R1_Linux.tar.lzma.torrent"
diaspora_patch_url="https://copy.com/8wo3AQnYu0bj?download=1"
dest_dir="./opt_Diaspora/"


#Main alias, automatically resumes
aria2_d="aria2c --console-log-level=error -V -c --seed-time=0 -O"
aria2_d="aria2c --console-log-level=error -V --seed-time=0 -O"


#Get main file and 1.1 patch
outfold=~/Desktop/temp_bob

#launcher_patch_url="https://wxlauncher.googlecode.com/issues/attachment?aid=930010000&name=wxlauncher_homedir.patch&token=ABZ6GAdjC8In36ECIYOtPby8m0jYh99_3Q%3A1412610881778"
#launcher_patch="wxLauncher.patch"
wx_patchfile=$(readlink -f ./wxlauncher_homedir.patch)

diaspora_main=$outfold/"Diaspora_R1_Linux.tar.lzma"
diaspora_patch=$outfold/"Diaspora_R1_Patch_1.1.tar.lzma"

clear

function untar_all(){
	to=$1
	file=$2
    tar -C $to --checkpoint=300 --checkpoint-action='ttyout=\r%u' --lzma -xf  $file
}






mkdir -p $outfold
##########################################
if [ -n "$downloading" ]; then

cd $outfold

echo "Diaspora Installer Script"
echo "========================="
#wget -O "main.torrent" $diaspora_main_url
echo ""
echo "Stage 1a: Downloading Main file (torrent)"
$runner $aria2_d 1="$(basename $diaspora_main)" $diaspora_main_url
[ "$?" != "0" ] && exit -1

echo ""
echo "Stage 1b: Downloading Patch"
#$runner $aria2_d 1="$(basename $diaspora_patch)" $diaspora_patch_url
$runner wget -c --progress=bar:force\
 -O "$(basename $diaspora_patch)" $diaspora_patch_url\
 2>&1 | progressfilt

[ "$?" != "0" ] && exit -1
echo ""

cd -

fi

#########################################
if [ -n "$unpacking" ]; then

echo ""
echo "Stage 2a: Unpacking Main file"
$runner mkdir -p $dest_dir
$runner untar_all $dest_dir $diaspora_main 
echo ""
echo "Stage 2b: Unpacking Patch file"
$runner untar_all $dest_dir $diaspora_patch

fi

patch_file_tar=$(readlink -f $(find $dest_dir -name "*Patch*.tar"))
diaspora_fold=$(readlink -f $(find $dest_dir -type d -name "Diaspora"))

#################################################
if [ -n "$patching" ]; then

	echo "Stage 2c: Applying Patch..."
	$runner tar -C $diaspora_fold --checkpoint=1000 --checkpoint-action=dot -xf $patch_file_tar
	echo ""

fi

##################################################
if [ -n "$building" ]; then

cd $diaspora_fold

	echo ""
	echo "Stage 3a: Building FS2 Open"
	cd fs2_open
	[ "$OS" = "arch" ] && $runner eval "LDFLAGS=\"-l:liblua.so.5.1 $LDFLAGS\" CXXFLAGS=\"-I/usr/include/lua5.1 $CXXFLAGS\" ./autogen.sh"
	[ "$OS" = "ubuntu" ] && $runner eval "./autogen.sh"
	$runner make
	$runner mv code/fs2_open_* ../fs2_open_diaspora
cd ..

echo ""
echo "Stage 3b: Building wxLauncher"

apply_place="code/apis/"

cd wxlauncher
#if [ "$OS" = "arch" ];then
	echo "Stage 3bi: Applying fix"
	#$runner wget -O $launcher_patch $launcher_patch_url
	$runner cp $wx_patchfile $apply_place
	cd $apply_place
	$runner patch < $(basename $wx_patchfile)
	cd ../../
#fi

#back into wxLauncher
cd build/
$runner cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python2\
 -D USE_OPENAL=1\
 -D CMAKE_BUILD_TYPE=RelWithDebInfo\
 -D DEVELOPMENT_MODE=1\
 -DwxWidgets_CONFIG_EXECUTABLE=/usr/bin/wx-config-2.8 ../
$runner make
cd ../../


fi


##################################################
if [ -n "$configuring" ];then

#back into Diaspora fold
echo ""
echo "Stage 4: Configuring Launcher"


profile=pro00099.ini
$runner cp pro00099.template.ini $profile
$runner chmod 644 $profile
$runner sed -i "s~^folder=.*~folder=`pwd`^M~" $profile

$runner ./wxlauncher/build/wxlauncher --add-profile --profile=Diaspora --file=$profile
$runner ./wxlauncher/build/wxlauncher --select-profile --profile=Diaspora

echo ""
echo ""
echo "Finished: Run \"$(readlink -f ./wxlauncher/build/wxlauncher)\""

fi
