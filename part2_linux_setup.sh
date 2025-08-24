#!/bin/bash

# script -c "./myscript.sh" ./myscript.log   
# script part2_linux_setup_$(date +"%Y-%m-%d_%H:%M:%S").log

# utility functions
user_log() {
    echo -e "\nlog : $(date +"%Y-%m-%d %H:%M:%S") ====================================  $@\n"
}
minor_log() {
    echo -e "\nlog : $(date +"%Y-%m-%d %H:%M:%S") ===========  $@\n"
}

if_dir_exists_remove() {
    if [ -d "$1" ]; then
        minor_log removing old $1
        rm -r "$1"
    fi
}
if_file_exists_remove() {
    if [ -f "$1" ]; then
        minor_log removing old $1
        rm -r "$1"
    fi
}


# get repo dir and run from it
ROOT_DIR=$(dirname "$(readlink -f "$0")")
cd $ROOT_DIR
user_log STARTING SETUP FROM $ROOT_DIR

# update system
user_log UPDATING SYSTEM
sudo apt-get update

# install dependencies
user_log INSTALLING REQUIREMENTS 
sudo apt install -y cmake default-jre g++ python-is-python3 python3-full
sudo apt-get -y install zlib1g-dev build-essential gdb unzip expect

# julia
user_log DOWNLOADING JULIA
curl -fsSL https://install.julialang.org | sh

# cplex
user_log INSTALLING CPLEX
# sudo ./cplex_studio2211.linux_x86_64.bin
sudo ./cplex_studio2211.linux_x86_64.bin -f "./misc/cplex_installation_options.properties"

# unzipping bapcod
user_log PREPARING BAPCOD
LAST_BAPCOD=$(ls bapcod*zip | tail -n1)
if_dir_exists_remove bapcodframework
unzip -q $LAST_BAPCOD

cd bapcodframework/Tools/
if [ -f "rcsp.zip" ]; then
    minor_log unzipping rcsp.zip
    unzip -q rcsp.zip
fi
cd -

minor_log installing boost and lemon
cd bapcodframework

# boost
if_file_exists_remove Tools/boost_1_76_0.tar.gz
if_dir_exists_remove Tools/boost_1_76_0
wget -P Tools/ https://archives.boost.io/release/1.76.0/source/boost_1_76_0.tar.gz
bash Scripts/shell/install_bc_boost.sh

# lemon
if_file_exists_remove Tools/lemon-1.3.1.tar.gz
if_dir_exists_remove Tools/lemon-1.3.1
wget -P Tools/ http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.tar.gz
bash Scripts/shell/install_bc_lemon.sh

# environment variables
user_log SETTING ENV VARIABLES
# Find and return full path of last folder alphabetically
# CPLEX_ROOT=/opt/ibm/ILOG/CPLEX_Studio2211
CPLEX_ROOT=$(find "/opt/ibm/ILOG/" -maxdepth 1 -type d -name "CPLEX_Studio*" | sort | tail -n 1)
CPLEX_STUDIO_BINARIES=$CPLEX_ROOT/cplex/bin/x86-64_linux/

BOOST_ROOT=$ROOT_DIR/bapcodframework/Tools/boost_1_76_0/build

# doesn't exist yet, but whatever
BAPCOD_RCSP_LIB=$ROOT_DIR/bapcodframework/build/Bapcod/libbapcod-shared.so


print_and_export() {
    echo "export $1=\"$2\""
    export $1=$2
}
print_and_export CPLEX_ROOT $CPLEX_ROOT
print_and_export CPLEX_STUDIO_BINARIES $CPLEX_STUDIO_BINARIES
print_and_export BOOST_ROOT $BOOST_ROOT
print_and_export BAPCOD_RCSP_LIB $BAPCOD_RCSP_LIB
# export CPLEX_STUDIO_BINARIES=/opt/ibm/ILOG/CPLEX_Studio2211/cplex/bin/x86-64_linux/


# Writing to .bashrc
BASHRC_FILE="$HOME/.bashrc"
user_log WRITING TO $BASHRC_FILE
SECTION_START="# === VRPSOLVER INSTALL DEFINITIONS START ==="
SECTION_END="# === VRPSOLVER INSTALL DEFINITIONS END ==="

# Remove existing section if it exists
if grep -q "$SECTION_START" "$BASHRC_FILE" 2>/dev/null; then
    sed -i "/$SECTION_START/,/$SECTION_END/d" "$BASHRC_FILE"
fi

# Add/update new section
cat >> "$BASHRC_FILE" << EOF

$SECTION_START
export CPLEX_ROOT=$CPLEX_ROOT
export CPLEX_STUDIO_BINARIES=$CPLEX_STUDIO_BINARIES
export BOOST_ROOT=$BOOST_ROOT
export BAPCOD_RCSP_LIB=$BAPCOD_RCSP_LIB

export MY_VAR="some_value"
export PATH="\$PATH:/my/custom/path"
alias ll="ls -la"
alias grep='grep --color=auto'

my_custom_function() {
    echo "Hello from my script"
}
$SECTION_END
EOF

# refresh bashrc
source ~/.bashrc

# Bapcod
user_log BUILDING BAPCOD
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j3 bapcod

minor_log running VertexColoring test
cd Demos/VertexColoringDemo
make -j3
sh ./tests/runTests.sh 
cd -

minor_log making shared library
make -j3 bapcod-shared


# end of bapcod setup

cd $ROOT_DIR

user_log INSTALLING VRPSolverDemos
git clone https://github.com/artalvpes/VRPSolverDemos.git
cd VRPSolverDemos

user_log Testing: julia src/run.jl data/A/A-n37-k6.vrp -m 6 -M 6 -u 950

julia src/run.jl data/A/A-n37-k6.vrp -m 6 -M 6 -u 950

user_log DONE
minor_log May Dantzig-Wolfe help you in your journey

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

