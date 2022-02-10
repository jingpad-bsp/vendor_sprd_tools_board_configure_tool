#!/bin/bash

PROGRAM_PATH=$(dirname `readlink -f $0`)
PROGRAM_NAME=$(basename `readlink -f $0`)
PROGRAM=`readlink -f $0`
export PATH=${PROGRAM_PATH}:$PATH

if [ -e ${PROGRAM_PATH}/tools/board-rename -a -e ${PROGRAM_PATH}/tools/rename-formatter.stepN.sh -a -e ${PROGRAM_PATH}/tools/rename-formatter ];then
TOOL_PATH=$PROGRAM_PATH/tools/
echo "TOOL_PATH:$TOOL_PATH"
export PATH=${TOOL_PATH}:$PATH
else
echo " no board-rename & rename-formatter.stepN.sh & rename-formatter "
exit 0
fi

function usage() {
cat<<EOT
USAGE
    board-create.sh PLATFORM SOC PROCESSOR ARCH SOURCE TARGET [-r]
DESCRYPTION
Parameter 1(PLATFORM): Android8（a8）、Android9（a9）、Android10（a10）、Android11（a11）、kaios（k1）、...
Parameter 2(SOC): soc name(sharkle sharkl3 sharkl5 sharkl5Pro roc1 pike2 qogirl6 qogirn6pro...)，list all soc by 'ls /device/sprd/'
Parameter 3(PROCESSOR): Processor name(sp9863a sp7731e ud710 sp9832e ums512 ums312 ums9230 ums9620)
Parameter 4(ARCH): arm64 or arm (The arm version of the board you are based on... E.g arm:pike2,sharkle,*32b*)
Parameter 5(SOURCE): source board name, like ums312_1h10 ums512_1h10 udx710_2h10
ud710_2h10 s9863a1h10 s9863a1h10_go_32b ums9230_1h10 ums9230_1h10_go sp7731e_1h10 sp9832e_1h10_go ums9620_1h10, list all sharkle board by 'ls /device/sprd/sharkl5Pro'
Parameter 6(TARGET): target board name, like ums512_2h10 ums9230_2h10 ums9620_2h10...
Parameter 7(KERNEL VERSION):4.14 or 5.4
Parameter 8(RESET): -r (Parameter 8 not necessary!!! if you want to reset git local changes please add this parameter,Otherwise, there is no need to add this parameter)
EXAMPLE
    board-create.sh a11 sharkl5Pro ums512 arm64 ums512_1h10 ums512_8h10 5.4
    board-create.sh a11 sharkl5Pro ums512 arm64 ums512_1h10 ums512_8h10 5.4 -r
EOT
}

if [ $# -lt 3 ]; then
    echo "error: argument num less than 5, please check usage..."
    usage
    exit 1
fi

platform=$1
soc=$2
processor=$3
PROCESSOR=${processor^^}
target_kernel_arch=$4
source_str=$5
target_str=$6
SOURCE_STR=${source_str^^}
TARGET_STR=${target_str^^}
kernel_version=$7

if [[ "$1" = "" ]] || [[ "$2" = ""  ]] || [[ "$3" = "" ]] || [[ "$4" = "" ]] || [[ "$5" = "" ]] || [[ "$6" = "" ]] || [[ "$7" = "" ]];then
     echo "error: The parameter you entered is wrong, please re-enter according to the following prompts..."
     usage
     exit 1
fi

if [[ "$2" != "sharkl3" ]] && [[ "$2" != "sharkle" ]] && [[ "$2" != "roc1" ]] && [[ "$2" != "pick2" ]] && [[ "$2" != "qogirl6" ]] && [[ "$2" != "qogirn6pro" ]] && [[ "$2" != "sharkl5" ]] && [[ "$2" != "sharkl5Pro" ]];then
    echo "error: The parameter you entered is wrong, please re-enter according to the following prompts..."
	usage
	exit 1
fi

if [[ "$2" = "sharkl3" ]] && [[ "$3" != "sp9863a" ]];then
	echo "error: The parameter you entered is wrong, please re-enter according to the following prompts..."
    usage
	exit 1
fi


DO_RESET=
for r in $@; do
    [ "${r}" = "-r" ] && DO_RESET=1
done

platform_version="`echo ${platform} | tr '[a-z]' '[A-Z]' | tr -d '[A-Z]'`"
if [ "`echo ${platform} | egrep -i '^a[0-9].*|android'`" ]; then
platform_name="A"
platform_code="android`python -c "print(chr(103+int(${platform_version})))"`"
elif [ "`echo ${platform} | egrep -i '^k[0-9].*|kai'`" ]; then
platform_name="K"
fi
PLATFORM_ENTRY=${platform_name}${platform_version}

SKIP_PROCESS=1
source ${PROGRAM_PATH}/soc/common/${PLATFORM_ENTRY}
SKIP_PROCESS=

if [ -e ${PROGRAM_PATH}/soc/${soc}/${PLATFORM_ENTRY} ]; then
    source ${PROGRAM_PATH}/soc/${soc}/${PLATFORM_ENTRY}
else
    source ${PROGRAM_PATH}/soc/common/${PLATFORM_ENTRY}
fi
