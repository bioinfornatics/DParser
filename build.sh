#!/usr/bin/env bash

# This file is part of DParser.
#
#    Foobar is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Foobar is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.


function usage(){
cat << EOF
usage: $0 options

This script install LDC, phobos2 library and druntime library over a machine.

OPTIONS:
    -h      Show this message
    -v      Verbose could be use twice time as -v -v for increase verbosity
    -q      No verbosity
    -s      Install static lib instead shared lib
    -c      Set compiler default ldc2
EOF
}

DC=ldc2
VERBOSE=0
SHARED_LIB=1
LIBDIR="lib"
LIBDIR_PATH=""
DOCDIR_PATH="../usr/doc/libDParser"
INCLUDEDIR="../usr/include/d"
DFLAGS="-w -g -op -c -od../build -Dd${DOCDIR_PATH} -Hd${INCLUDEDIR}"

while getopts “hvqscl” OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        v)
            let VERBOSE++
            ;;
        q)
            VERBOSE=0
            ;;
        s)
            SHARED_LIB=0
            ;;
        c)
            DC=$OPTARG
            ;;
        l)
            LIBDIR=$OPTARG
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done

LIBDIR_PATH="../usr/${LIBDIR}"
DOCDIR_PATH="../usr/doc/libDParser"

if [[ $VERBOSE -ge 1 ]]; then
    echo -e "\033[31mEntering is source directory\033[0;0m"
fi
cd src
#############################################################
if [[ $VERBOSE -ge 1 ]]; then
    echo -e "\033[31mSet DFLAGS\033[0;0m"
fi
case ${DC} in
    ldc | ldc2)
        DFLAGS="${DFLAGS} --output-o"
        if [[ $SHARED_LIB -eq 1 ]]; then
            DFLAGS="${DFLAGS} --output-bc -relocation-model=pic"
        fi
        ;;
    gdc)
        DC="gdmd"
        ;;
    gdmd | dmd)
        if [[ $SHARED_LIB -eq 1 ]]; then
            #DFLAGS="${DFLAGS} -fPIC"
            echo "Currently dmd do not support shared lib!"
            echo "Only ldc support it. So use ldc or use flag -s"
            usage
            exit 1
        fi
        ;;
    ?)
        echo "Unknow compiler: ${DC}"
        echo "Supported compiler ldc, ldc2, gdc, dmd"
        ;;
esac
#############################################################
if [[ $VERBOSE -ge 1 ]]; then
    echo -e "\033[31mCompile ...\033[0;0m"
fi
${DC} ${DFLAGS} *.d
#############################################################
if [[ $VERBOSE -ge 1 ]]; then
    echo -e "\033[31mEntering is build directory\033[0;0m"
fi
cd ../build
#############################################################
if [[ $VERBOSE -ge 1 ]]; then
    echo -e "\033[31mLinking ...\033[0;0m"
fi
if [ ! -e "${LIBDIR_PATH}" ]; then
    mkdir ${LIBDIR_PATH}
fi
case ${DC} in
    ldc | ldc2)
        if [[ $SHARED_LIB -eq 1 ]]; then
            llvm-ld -link-as-library -o libDparser.bc -lm -ldl -lrt -soname=Dparser *.bc;
            llc -relocation-model=pic libDparser.bc;
            gcc -shared libDparser.s -o ${LIBDIR_PATH}/libDparser.so;
        else
            ar rcs ${LIBDIR_PATH}/libDparser.a *.o
            ranlib ${LIBDIR_PATH}/libDparser.a
        fi
        ;;
    gdmd | dmd)
        if [[ $SHARED_LIB -eq 1 ]]; then
            echo "not supported"
        else
            ${DC} -link *.o -of ${LIBDIR_PATH}/libDparser.a
        fi
        ;;
    ?)
        echo "Unknow compiler: ${DC}"
        echo "Supported compiler ldc, ldc2, gdc, dmd"
        ;;
esac