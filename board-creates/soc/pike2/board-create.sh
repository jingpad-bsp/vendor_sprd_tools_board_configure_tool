#!/bin/bash
list_name="$source_str:$target_str \
           $SOURCE_STR:$TARGET_STR \
           ${source_str/_/-}:${target_str/_/-} \
           ${SOURCE_STR/_/-}:${TARGET_STR/_/-} \
           ${source_str/s9863a/sp9863a-}:${target_str/s9863a/sp9863a-} \
           ${SOURCE_STR/S9863A/SP9863A-}:${TARGET_STR/S9863A/SP9863A-} \
           ${source_str/s9863a/sp9863a_}:${target_str/s9863a/sp9863a_} \
           ${SOURCE_STR/S9863A/SP9863A_}:${TARGET_STR/S9863A/SP9863A_} \
           ${source_str/s9863a/sc9863a-}:${target_str/s9863a/sc9863a-} \
           ${SOURCE_STR/S9863A/SC9863A-}:${TARGET_STR/S9863A/SC9863A-} \
           ${SOURCE_STR/S9863A/SC9863A_}:${TARGET_STR/S9863A/SC9863A_} \
           ${source_str/s9863a/sc9863a_}:${target_str/s9863a/sc9863a_} "

echo "============================================="
echo "source_board_path:${source_board_path}"
echo "target_board_path:${target_board_path}"
echo "kernel_path:${kernel_path}"
echo -e "=============================================\n"

if [ ! -e ${source_board_path} ]; then
    echo "error: ${source_board_path} no exsit..."
    exit 1
fi

# Step 1: reset&clean relative repos first
echo "Step 1: reset&clean relative repos"
echo "***relative board repo***"
echo "device board:$soc_path"
echo "chipram board:$chipram_path"
echo "uboot board:$uboot_path"
echo "kernel board:$kernel_path"
echo "wcn board:$wcn_path"
echo "***relative board repo***"
# test if git available first
if which git >/dev/null; then
  # confirm first before reset&clean
  echo -e "\nrelative board repos will be reset&clean, save your repo modifications first if needed!!!"
  read -p "continue to reset relative board repos (y/n)" choice
  if [[ $choice = 'y' ]] || [[ $choice = 'Y' ]]; then
    cd $soc_path && git clean -df && git reset --hard HEAD && cd ->/dev/null
    cd $chipram_path && git clean -df && git reset --hard HEAD && cd ->/dev/null
    cd $uboot_path && git clean -df && git reset --hard HEAD && cd ->/dev/null
    cd $kernel_path && git clean -df && git reset --hard HEAD && cd ->/dev/null
    cd $bsp_device && git clean -df && git reset --hard HEAD && cd ->/dev/null
    cd $wcn_path && git clean -df && git reset --hard HEAD && cd ->/dev/null
    echo -e "Step 1: done\n"
  else
    exit 1
  fi
else
  echo "git is not available, skip Step 1!"
fi

# Step 2: create device board
echo "Step 2: create device board"
rm -rf $target_board_path
cp -fr $source_board_path $target_board_path
# copy&rename
echo "clone $source_board_path -> $target_board_path"
echo "rename $source_str -> $target_str"
cd $target_board_path
rename-formatter -i $list_name
cd ->/dev/null
# add AndroidProducts.mk config
for product_name in `grep PRODUCT_NAME -nr ${source_board_path} | awk -F ":= " '{print $2}'`; do
    echo $product_name
    sed -i "s/\(.*\)${product_name}:\$(LOCAL_DIR)\/${source_str}\/${product_name}\.mk\(.*\)/\1${product_name}:\$(LOCAL_DIR)\/${source_str}\/${product_name}\.mk\2\n\1${product_name/$source_str/$target_str}:\$(LOCAL_DIR)\/${target_str}\/${product_name/$source_str/$target_str}\.mk\2/g" ${soc_path}/AndroidProducts.mk
    sed -i "s/\(.*\)${product_name}-\(.*\)/\1${product_name}-\2\n\1${product_name/$source_str/$target_str}-\2/g" ${soc_path}/AndroidProducts.mk
    config=`grep ${product_name}: ${soc_path}/AndroidProducts.mk | head -1`
    if ! [[ $config = *"\\"* ]]; then
    sed -i "s/${product_name}:\$(LOCAL_DIR)\/${source_str}\/${product_name}\.mk\(.*\)/${product_name}:\$(LOCAL_DIR)\/${source_str}\/${product_name}\.mk\1 \\\/g" ${soc_path}/AndroidProducts.mk
    fi
    config=`grep ${product_name}- ${soc_path}/AndroidProducts.mk | head -1`
    if ! [[ $config = *"\\"* ]]; then
    sed -i "s/${product_name}-\(.*\)/${product_name}-\1 \\\/g" ${soc_path}/AndroidProducts.mk
    fi
done
echo -e "Step 2: done\n"

# Step 3: create bsp/device board
echo "Step 3: create bsp/device board"
source_bsp_board_path=bsp/device/$soc/androidq/$source_str
if [[ $soc == pike2 ]] || [[ $soc == sharkle ]];then
target_kernel_arch=arm
else
target_kernel_arch=arm64
fi
kernel_source=$source_str
target_bsp_board_path=bsp/device/$soc/androidq/$target_str
kernel_target=$target_str
# copy&rename
echo "clone $source_bsp_board_path -> $target_bsp_board_path"
echo "rename $kernel_source -> $kernel_target"
rm -rf $target_bsp_board_path
cp -fr $source_bsp_board_path $target_bsp_board_path
cd $target_bsp_board_path
rename-formatter -i $list_name
#deal with old dt file name
cd ->/dev/null
# deal with diff config
source_kernel_diff_config_path=bsp/kernel/kernel4.14/sprd-diffconfig/android/$soc/$target_kernel_arch/${kernel_source}_diff_config
target_kernel_diff_config_path=bsp/kernel/kernel4.14/sprd-diffconfig/android/$soc/$target_kernel_arch/${kernel_target}_diff_config
if [ -e $source_kernel_diff_config_path ]; then
    rm -rf $target_kernel_diff_config_path
    cp -fr $source_kernel_diff_config_path $target_kernel_diff_config_path
    echo "clone $source_kernel_diff_config_path -> $target_kernel_diff_config_path"
fi
# deal with dts file
source_dtb_str=`grep -nir "BSP_DTB.*=.*" $source_bsp_board_path | head -1 | sed 's/.*= *//' | sed 's/"//g'`
source_dtbo_str=`grep -nir "BSP_DTBO.*=.*" $source_bsp_board_path | head -1 | sed 's/.*= *//' | sed 's/"//g'`
target_dtb_str=`grep -nir "BSP_DTB.*=.*" $target_bsp_board_path | head -1 | sed 's/.*= *//' | sed 's/"//g'`
target_dtbo_str=`grep -nir "BSP_DTBO.*=.*" $target_bsp_board_path | head -1 | sed 's/.*= *//' | sed 's/"//g'`
echo $source_dtb_str $source_dtbo_str $target_dtb_str $target_dtbo_str
if [ $target_kernel_arch = "arm64" ]; then
    dts_path=arch/arm64/boot/dts/sprd
else
    dts_path=arch/arm/boot/dts
fi
source_dtb_path=${kernel_path}/${dts_path}/${source_dtb_str}.dts
target_dtb_path=${kernel_path}/${dts_path}/${target_dtb_str}.dts
source_dtbo_path=${kernel_path}/${dts_path}/${source_dtbo_str}.dts
target_dtbo_path=${kernel_path}/${dts_path}/${target_dtbo_str}.dts

echo "clone $source_dtb_path -> $target_dtb_path"
echo "clone $source_dtbo_path -> $target_dtbo_path"
echo "rename $source_str -> $target_str"
echo $target_dtb_path
echo $target_dtbo_path
rm -rf $target_dtb_path $target_dtbo_path
cp -fr $source_dtb_path $target_dtb_path
cp -fr $source_dtbo_path $target_dtbo_path
rename-formatter -i $list_name  $target_dtb_path $target_dtbo_path

# add config in ${kernel_path}/${dts_path}/Makefile
echo "add config in ${kernel_path}/${dts_path}/Makefile"
makefile_path=${kernel_path}/${dts_path}/Makefile
sed -i "s/\(.*\)${source_dtb_str}.dtb\(.*\)/\1${source_dtb_str}.dtb\2\n\1${target_dtb_str}.dtb\2/" $makefile_path
sed -i "s/\(.*\)${source_dtbo_str}.dtbo\(.*\)/\1${source_dtbo_str}.dtbo\2\n\1${target_dtbo_str}.dtbo\2/" $makefile_path
# deal with last one which is not end with '\'
config=`grep ${source_dtb_str} $makefile_path | head -1`
if ! [[ $config = *"\\"* ]]; then
  sed -i "s/${source_dtb_str}.dtb\(.*\)/${source_dtb_str}.dtb\1 \\\/g" $makefile_path
fi
config=`grep ${source_dtbo_str} $makefile_path | head -1`
if ! [[ $config = *"\\"* ]]; then
  sed -i "s/${source_dtbo_str}.dtbo\(.*\)/${source_dtbo_str}.dtbo\1 \\\/g" $makefile_path
fi
echo -e "Step 3: done\n"

# Step 4: create uboot board
echo "Step 4: create uboot board"
if [[ $source_str == *9863* ]] && [[ $source_str != *_* ]];then
echo 'This is sharkl3' $source_str
uboot_source=${source_str/s9863a/sp9863a_}
uboot_target=${target_str/s9863a/sp9863a_}
else
uboot_source=$source_str
uboot_target=$target_str
fi
# copy&rename
echo "clone bsp/bootloader/u-boot15/arch/arm/dts/${uboot_source}.dts -> bsp/bootloader/u-boot15/arch/arm/dts/${uboot_target}.dts"
echo "clone bsp/bootloader/u-boot15/board/spreadtrum/${uboot_source} -> bsp/bootloader/u-boot15/board/spreadtrum/${uboot_target}"
echo "clone bsp/bootloader/u-boot15/configs/${uboot_source}_defconfig -> bsp/bootloader/u-boot15/configs/${uboot_target}_defconfig"
echo "clone bsp/bootloader/u-boot15/include/configs/${uboot_source}.h -> bsp/bootloader/u-boot15/include/configs/${uboot_target}.h"
echo "rename $uboot_source -> $uboot_target"
rm -rf bsp/bootloader/u-boot15/arch/arm/dts/${uboot_target}.dts \
       bsp/bootloader/u-boot15/board/spreadtrum/${uboot_target} \
       bsp/bootloader/u-boot15/configs/${uboot_target}_defconfig \
       bsp/bootloader/u-boot15/include/configs/${uboot_target}.h
cp -fr bsp/bootloader/u-boot15/arch/arm/dts/${uboot_source}.dts bsp/bootloader/u-boot15/arch/arm/dts/${uboot_target}.dts
cp -fr bsp/bootloader/u-boot15/board/spreadtrum/${uboot_source} bsp/bootloader/u-boot15/board/spreadtrum/${uboot_target}
cp -fr bsp/bootloader/u-boot15/configs/${uboot_source}_defconfig bsp/bootloader/u-boot15/configs/${uboot_target}_defconfig
cp -fr bsp/bootloader/u-boot15/include/configs/${uboot_source}.h bsp/bootloader/u-boot15/include/configs/${uboot_target}.h
rename-formatter -i $list_name bsp/bootloader/u-boot15/arch/arm/dts/${uboot_target}.dts \
                               bsp/bootloader/u-boot15/configs/${uboot_target}_defconfig \
                               bsp/bootloader/u-boot15/include/configs/${uboot_target}.h

# Only for sharkl3
sed -i "s/${source_str/s9863a/ 9863a_}/${target_str/s9863a/ 9863a_}/g" bsp/bootloader/u-boot15/arch/arm/dts/${uboot_target}.dts
cd bsp/bootloader/u-boot15/board/spreadtrum/${uboot_target}
rename-formatter -i $list_name
cd ->/dev/null
# add config in u-boot15/arch/arm/dts/Makefile
echo "add config in bsp/bootloader/u-boot15/arch/arm/dts/Makefile"
uboot_makefile=bsp/bootloader/u-boot15/arch/arm/dts/Makefile
sed -i "s/\(.*\)${uboot_source}.dtb\(.*\)/\1${uboot_source}.dtb\2\n\1${uboot_target}.dtb\2/" $uboot_makefile

config=`grep ${uboot_source} $uboot_makefile | head -1`
if ! [[ $config = *"\\"* ]]; then
  sed -i "s/${uboot_source}.dtb\(.*\)/${uboot_source}.dtb\1 \\\/g" $uboot_makefile
fi
# add config in u-boot15/board/spreadtrum/Kconfig
echo "add config in bsp/bootloader/u-boot15/board/spreadtrum/Kconfig"
uboot_kconfig=bsp/bootloader/u-boot15/board/spreadtrum/Kconfig
line=`grep -n "\bTARGET_${uboot_source^^}\b" ${uboot_kconfig} | sed 's/:.*//'`
sed -n $line,+5p ${uboot_kconfig} | sed "s/${uboot_source^^}/${uboot_target^^}/" > temp.txt
sed -i "$(expr $line + 5)r temp.txt" ${uboot_kconfig}
rm temp.txt 2>/dev/null
sed -i "s/\(.*\)${uboot_source}\(.Kconfig.*\)/\1${uboot_source}\2\n\1${uboot_target}\2/" $uboot_kconfig
echo -e "Step 4: done\n"
ma=bsp/bootloader/u-boot15/scripts/Makefile.autoconf
echo $uboot_source
echo $uboot_target
#sed  -i "s/\(.*\)AUTO_ADAPTIVE_BOARD_LIST\(.*\)\"${uboot_source}\"/\1AUTO_ADAPTIVE_BOARD_LIST\2\"${uboot_source}\" \"${uboot_target}\"/" $ma
sed  -i "s/\"${uboot_source}\"/\"${uboot_source}\" \"${uboot_target}\"/" $ma

# Step 5: create chipram board
echo "Step 5: create chipram board"
if [[ $source_str == *9863* ]] && [[ $source_str != *_* ]];then
echo 'This is sharkl3' $source_str
chipram_source=${source_str/s9863a/sp9863a_}
chipram_target=${target_str/s9863a/sp9863a_}
else
chipram_source=$source_str
chipram_target=$target_str
fi
# copy&rename
echo "clone bsp/bootloader/chipram/include/configs/${chipram_source}.h -> bsp/bootloader/chipram/include/configs/${chipram_target}.h"
echo "rename $chipram_source -> $chipram_target"
rm -rf bsp/bootloader/chipram/include/configs/${chipram_target}.h
cp -fr bsp/bootloader/chipram/include/configs/${chipram_source}.h bsp/bootloader/chipram/include/configs/${chipram_target}.h
# add config in bsp/bootloader/chipram/board.def
echo "add config in bsp/bootloader/chipram/board.def"
chipram_board_def=bsp/bootloader/chipram/board.def
line=`grep -n "\b${chipram_source}_config\b" ${chipram_board_def} | sed 's/:.*//'`
sed -n $line,+2p ${chipram_board_def} | sed "s/${chipram_source}/${chipram_target}/" > temp.txt
sed -i "$(expr $line + 2)r temp.txt" ${chipram_board_def}
rm temp.txt 2>/dev/null
echo -e "Step 5: done\n"

# Step 6: create wcn board
echo "Step 6: create wcn board"
wcn_combo=`grep -nir "BOARD_HAVE_SPRD_WCN_COMBO.*=.*" ${target_board_path} | sed 's/.*= *//'`
wcn_connconfig=vendor/sprd/modules/wcn/connconfig
wcn_source=${wcn_connconfig}/${wcn_combo}/${source_str}
wcn_target=${wcn_connconfig}/${wcn_combo}/${target_str}
# copy&rename
echo "clone $wcn_source -> $wcn_target"
echo "rename $source_str -> $target_str"
rm -rf ${wcn_target}
cp -fr ${wcn_source} ${wcn_target}
echo -e "Step 6: done\n"
