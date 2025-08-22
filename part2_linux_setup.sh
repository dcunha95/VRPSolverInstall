#!/bin/bash

# script -c "./myscript.sh" ./myscript.log   
# script part2_linux_setup_$(date +"%Y-%m-%d_%H:%M:%S").log

user_log() {
    echo -e "\nlog:$(date +"%Y-%m-%d %H:%M:%S") ====================================  $@\n"
}
minor_log() {
    echo -e "\nlog:$(date +"%Y-%m-%d %H:%M:%S") ===========  $@\n"
}


# get repo dir and run from it
ROOT_DIR=$(dirname "$(readlink -f "$0")")
cd $ROOT_DIR
user_log STARTING SETUP FROM $ROOT_DIR

user_log UPDATING SYSTEM
apt-get update

user_log INSTALLING SYSTEM DEPENDENCIES 
apt install cmake default-jre g++
apt-get install zlib1g-dev build-essential gdb

# user_log DOWNLOADING JULIA
# # curl -fsSL https://install.julialang.org | sh

# user_log INSTALLING CPLEX
# # ./cplex_studio2211.linux_x86_64.bin

# user_log INSTALLING UNZIP
# # apt-get install unzip

# user_log PREPARING BAPCOD
# LAST_BAPCOD=$(ls bapcod*zip | tail -n1)
# if [ -d "bapcodframework" ]; then
#     minor_log removing old folder
#     rm -r "bapcodframework"
# fi
# unzip -q $LAST_BAPCOD

# cd bapcodframework/Tools/
# if [ -f "rcsp.zip" ]; then
#     minor_log unzipping rcsp.zip
#     unzip -q rcsp.zip
# fi
# cd -

minor_log installing boost and lemon
cd bapcodframework

wget -P Tools/ https://archives.boost.io/release/1.76.0/source/boost_1_76_0.tar.gz
wget -P Tools/ http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.tar.gz
bash Scripts/shell/install_bc_lemon.sh
bash Scripts/shell/install_bc_boost.sh

# user_log VRPSOLVER INSTALL DEFINITIONS

# echo "export $VAR_NAME=\"$VAR_VALUE\"" >> "$BASHRC_FILE"

# export PATH="$PATH:/opt/ibm/ILOG/CPLEX_Studio2212/cplex/bin/x86-64_linux/"
# export CPLEX_ROOT="/opt/ibm/ILOG/CPLEX_Studio2212"
# export CPLEX_STUDIO_BINARIES="/opt/ibm/ILOG/CPLEX_Studio2212/cplex/bin/x86-64_linux"
# export BOOST_ROOT="/home/griffo/bapcodframework/Tools/boost_1_76_0/build"

# user_log END OF VRPSOLVER DEFINITIONS


# # file to record file list
# FILE_LIST="../kml_lines.txt"
# if [ -f "$FILE_LIST" ]; then
#     rm "$FILE_LIST"
# fi

# # unzip one file to get images folder
# for f in *.zip;
#     do unzip -q "$f";
#     rm doc.kml;
#     break;
# done

# exit

# python /opt/ibm/ILOG/CPLEX_Studio2211/python/setup.py install
