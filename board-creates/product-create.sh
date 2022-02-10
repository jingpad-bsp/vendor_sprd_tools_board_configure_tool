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


platform=$1
soc=$2
board=$3
source_str=$4
target_str=$5
SOURCE_STR=${source_str^^}
TARGET_STR=${target_str^^}


function get_pwd_abs() {
    lcurdir=$(readlink -f .)
    while [ "${lcurdir}" != '/' ]; do
        if [ -e ${lcurdir}/build/envsetup.sh ]; then
            echo "${lcurdir}"
            break;
        fi
        lcurdir=$(readlink -f ${lcurdir}/..)
    done
}

ANDROID_TOP=`get_pwd_abs`
soc_path=device/sprd/$soc
board_path=$soc_path/$board
source_product=$board_path/${source_str}.mk
target_product=$board_path/${target_str}.mk
echo ${source_product}
echo ${target_product}

if [[ $platform == a11 ]];then
android=androidr
elif [[ $platform == a10 ]];then
android=androidq
fi

bsp_device=bsp/device/$soc/$android/$board
echo "$bsp_device"
list_name="$source_str:$target_str"
cd $ANDROID_TOP
# Step0 : test if git available first
echo "Step0 : test if git available first"
if which git >/dev/null; then
  # confirm first before reset&clean
  echo -e "\nrelative board repos will be reset&clean, save your repo modifications first if needed!!!"
  read -p "continue to reset relative board repos (y/n)" choice
  if [[ $choice = 'y' ]] || [[ $choice = 'Y' ]]; then
    (cd $soc_path && git clean -df && git reset --hard HEAD && cd ->/dev/null)
    (cd $bsp_device && git clean -df && git reset --hard HEAD && cd ->/dev/null)
    echo -e "Step 1: done\n"
  else
    exit 1
  fi
else
  echo "git is not available, skip Step 1!"
fi

# Step 1: create device product 
echo "Step 1: create device product"
pwd
rm -rf ${target_product}
cp ${source_product} ${target_product} -rf
echo "rename $list_name ${target_product}"
rename-formatter -i $list_name ${target_product}
echo -e "Step 1: done\n"

#step 2: modified AndroidProducts 
echo "Step 2: modified device product in AndroidProduct"
#source_str=ud710_2h10
#product_name=ud710_2h10_native
#target_str=ud710_2h10_overseas
echo "${source_str}"
echo "${board}"
echo "${target_str}"
echo "${soc_path}"
sed -i "s/\(.*\)${source_str}:\$(LOCAL_DIR)\/${board}\/${source_str}\.mk\(.*\)/\1${source_str}:\$(LOCAL_DIR)\/${board}\/${source_str}\.mk\2\n\1${source_str/$source_str/$target_str}:\$(LOCAL_DIR)\/${board}\/${source_str/$source_str/$target_str}\.mk\2/g" ${soc_path}/AndroidProducts.mk
sed -i "s/\(.*\)${source_str}-\(.*\)/\1${source_str}-\2\n\1${source_str/$source_str/$target_str}-\2/g" ${soc_path}/AndroidProducts.mk
echo -e "Step 2: done\n"

#step 3: create bsp device product
echo "step 3: create bsp device product"
pwd
#source_bsp_product_path=bsp/device/$soc/$android/$board/$source_str
source_bsp_product_path=${bsp_device}/${source_str}
#bsp_device=bsp/device/$soc/$android/$board
target_bsp_product_path=${bsp_device}/${target_str}
rm -rf ${target_bsp_product_path}
cp ${source_bsp_product_path} ${target_bsp_product_path} -rf
echo "cp ${source_product} -> ${target_product}"
echo -e "Step 3: done\n"

