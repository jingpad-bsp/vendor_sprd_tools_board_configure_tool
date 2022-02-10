#!/bin/bash
#
# Copyright (C) 2018 UNISOC Communications Inc.
#
# program_name=$(echo $0 | xargs basename)
program_name="rename-formatter.stepN.sh"
SPACE_TOKEN='~'
do_help_only=
function usage() {
    if [ "${do_replace_action_help}" ]; then
        echo "${do_replace_action_help}" <&2
    else
cat 1<&2 <<__AEOF

${program_name} [-D] [-i] src_token1:dst_token1 src_token2:dst_token2 ...

    -D not dry-run
    -i replace src token to dst token in place actually under current directory

    Example : 3 steps are needed
    Step 1. ${program_name} sharkl5:sharkl5pro SHARKL5:SHARKL5PRO
    Step 2. ${program_name} -D sharkl5:sharkl5pro SHARKL5:SHARKL5PRO
    Step 3. ${program_name} -D -i sharkl5:sharkl5pro SHARKL5:SHARKL5PRO

__AEOF
    fi
    do_help_only=1
}

do_replace_action_in_dirs=()
do_replace_action_in_files=()
do_replace_action_in_df=()
do_replace_action_help=
do_final_replace_action=
do_replace_action_dry_run=1
do_replace_action_silent=

function process_args() {
    tokens=()
    if [ "${in_bashrc}" ]; then
        for op in $@; do
            case $op in
                -i)
                    do_final_replace_action=1
                    shift 1
                ;;
                -f)
                    do_replace_action_in_files=("${do_replace_action_in_files[@]}" "$OPTARG")
                    shift 2
                ;;
                -d)
                    do_replace_action_in_dirs=("${do_replace_action_in_dirs[@]}" "$OPTARG")
                    shift 2
                ;;
                -H)
                    do_replace_action_help="$OPTARG"
                    shift 1
                ;;
                -D)
                    do_replace_action_dry_run=
                    shift 1
                ;;
                *)
                    break
                    # usage; return
                ;;
            esac
        done
    else
        while getopts if:d:H:hDS op; do
            case $op in
                i)
                    do_final_replace_action=1
                ;;
                f)
                    do_replace_action_in_files=("${do_replace_action_in_files[@]}" "$OPTARG")
                ;;
                d)
                    do_replace_action_in_dirs=("${do_replace_action_in_dirs[@]}" "$OPTARG")
                ;;
                H)
                    do_replace_action_help="$OPTARG"
                ;;
                D)
                    do_replace_action_dry_run=
                ;;
                S)
                    do_replace_action_silent=1
                ;;
                *)
                    usage; return
                ;;
            esac
        done
        shift `expr $OPTIND - 1`
    fi
    tokens=($@)
}

if [ "${0:((${#0}-4))}" = "bash" ]; then
    in_bashrc=1
    process_args $@
else
    in_bashrc=
    process_args $@
fi

function update_find_data() {
    [ "${PROCESS_FILES[0]}${PROCESS_DIRS[0]}" ] && {
        FS=(${PROCESS_FILES[@]})
        if [ "${PROCESS_DIRS[0]}" ]; then
            FS=(${FS[@]} $(find ${PROCESS_DIRS[@]} -type f | sed 's/\.\///;/^\./d;/\/\./d'))
            FD=("$(find ${PROCESS_DIRS[@]} -type d | sed 's/\.\///;/^\./d;/\/\./d')")
            for f in $(find ${PROCESS_DIRS[@]} -type l | sed 's/\.\///;/^\./d;/\/\./d'); do
                [ -f "${f}" ] && FS=(${FS[@]} ${f})
                [ -d "${f}" ] && FD=(${FD[@]} ${f})
            done
        fi
        return
    }
    FS=("$(find ${do_replace_action_in_fd[@]} -type f | sed 's/\.\///;/^\./d;/\/\./d')")
    FD=("$(find ${do_replace_action_in_fd[@]} -type d | sed 's/\.\///;/^\./d;/\/\./d')")
    for f in $(find ${do_replace_action_in_fd[@]} -type l | sed 's/\.\///;/^\./d;/\/\./d'); do
        [ -f "${f}" ] && FS=(${FS[@]} ${f})
        [ -d "${f}" ] && FD=(${FD[@]} ${f})
    done
    # FS=("$(find ${do_replace_action_in_fd[@]} -type f -o -type l | sed 's/\.\///;/^\./d;/\/\./d')")
    # FSE=("$(find ${do_replace_action_in_fd[@]} -type f -o -type l | sed 's/\.\///;/^\./d;/\/\./d' | egrep -i "${EGREP}")")
    # FDE=("$(find ${do_replace_action_in_fd[@]} -type d | sed 's/\.\///;/^\./d;/\/\./d' | egrep -i "${EGREP}")")
    # FD=("$(find ${do_replace_action_in_fd[@]} -type d -empty | sed 's/\.\///;/^\./d;/\/\./d')")
    # echo ${FS[@]}
    # echo ${FD[@]}
}

function process_rename() {
    local cur=`pwd`
    cd "$(dirname $1)"
    local f=$(basename $1)
    # echo $f | egrep "${EGREP}"
    if [ "${do_replace_action_dry_run}" ]; then
        [ "$(echo "$f" | egrep -i "${EGREP}")" ] && {
            # echo "Rename Dir : `pwd`/$f" | sed -e "s!${BASE_DIR}/!!" | egrep -i "${EGREP}"
            if [ -d ${f} ]; then
                echo -e "\033[33mRename Dir  `pwd`/$f\033[0m" | sed -e "s!${BASE_DIR}/!!" | egrep -i "${EGREP}"
            else
                echo -e "\033[32mRename File `pwd`/$f\033[0m" | sed -e "s!${BASE_DIR}/!!" | egrep -i "${EGREP}"
            fi
        }
    else
        f2="$(echo $f | sed ""${SEDS}"")"
        # echo "mv $f ${f2}"
        [ "${f}" != "${f2}" ] && {
            if [ "${f2}" ]; then
                mv $f ${f2}
            else
                [ "$f" = "ahquoo5Oa0oochie7ach" ] && rm -rf $f
            fi
        }
    fi
    cd "${cur}"
}

function process_dir() {
    if [ '' ]; then
        cd "$1"
        local cur="`pwd`"
        local parent=$2/$1
        # echo $parent
        for d in $(find -maxdepth 1 -type d | sed 's/\.\///;/^\./d;/\/\./d'); do
            cd "${cur}"
            process_dir ${d} ${parent}
        done
        cd "${cur}"
        for f in $(find -maxdepth 1 -type f -o -type l | sed 's/\.\///;/^\./d;/\/\./d'); do
            process_rename ${f}
        done
        cd ..
        process_rename $(basename $1)
    else
        cd "$1"/..
        process_rename $(basename $1)
    fi
}

function main() {
    [ "${tokens[0]}" ] || { usage; return; }

    # Check Parameter legitimacy
    Tokens=()
    TokensID="LUTHER-TOKEN-"
    TokensIDC=0
    PROCESS_FILES=()
    PROCESS_DIRS=()
    for t in ${tokens[@]}; do
        ts=($(echo "${t}" | sed 's/:/ /g'))
        [ "$(echo ${t} | grep ':')" ] || {
            [ -e "${t}" ] || {
                usage
                return
            }
            # t=$(readlink -f "${t}")
            [ "`echo "${t}" | grep ' '`" ] && { echo "Space can't be used in ${t}"; exit; }
            if [ -d "${t}" ]; then
                PROCESS_DIRS=(${PROCESS_DIRS[@]} "${t}")
            else
                PROCESS_FILES=(${PROCESS_FILES[@]} "${t}")
            fi
            continue
        }
        ((${#ts[@]} > 2)) && { usage; return; }
        if ((TokensIDC < 10)); then
            TokensIDTag=${TokensIDC}
        else
            TokensIDTag=$(echo ${TokensIDC} | awk '{printf("%c", $1+65-10)}')
        fi
        ((TokensIDC++))
        if ((${#ts[@]} >= 2)); then
            Tokens=("${Tokens[@]}" "$(echo ${ts[@]} | sed 's/ /:/'):${TokensID}${TokensIDTag}")
        else
            Tokens=("${Tokens[@]}" "${ts[0]}:ahquoo5Oa0oochie7ach:${TokensID}${TokensIDTag}")
        fi
    done

    SEDS=""
    SEDSEG=""
    SEDSD="s/\"/\\\\\"/g;s/'/\\\'/g;"
    SEDSDR=""
    #SEDSD="s/\"//g;s/'//g;"
    EGREP=""
    EGREPE=""
    FIND=""
    # Process Parameter
    for t in ${Tokens[@]}; do
        # echo ${t}
        ts=($(echo "${t}" | sed 's/:/ /g'))
        ts0=`echo ${ts[0]} | sed "s/${SPACE_TOKEN}/ /g"`
        ts1=`echo ${ts[1]} | sed "s/${SPACE_TOKEN}/ /g"`
        ts2=`echo ${ts[2]} | sed "s/${SPACE_TOKEN}/ /g"`
        src_token=${ts0}
        if [ "${ts1}" = "ahquoo5Oa0oochie7ach" ]; then
            dst_token=
            ids_token=${ts1}
        else
            dst_token=${ts1}
            ids_token=${ts2}
        fi

        [ "${EGREP}" ] && EGREP="${EGREP}|"
        EGREP="${EGREP}${src_token}"

        if [ "${do_final_replace_action}" ]; then
            SEDS="${SEDS};s/${ids_token}/${dst_token}/g"
            [ "${EGREPE}" ] && EGREPE="${EGREPE}|"
            EGREPE="${EGREPE}${ids_token}"
        else
            SEDS="${SEDS};s/${src_token}/${ids_token}/g"
        fi

        [ "${dst_token}" ] && {
            SEDSEG="${SEDSEG};s/${dst_token}/${ids_token}D/g"
            SEDSDR="${SEDSDR};s/${ids_token}D/${dst_token}/g"
        }
        SEDSEG="${SEDSEG};s/${src_token}/${ids_token}/g"
        SEDSDR="${SEDSDR};s/${ids_token}/${dst_token}/g"

        c=0
        SRC_TOKEN=
        while ((c < ${#src_token})); do
            chr=${src_token:${c}:1}
            if [[ ${chr} =~ ^[a-z\|A-Z]+$ ]]; then
                chr="[$(echo ${chr} | tr '[A-Z]' '[a-z]')$(echo ${chr} | tr '[a-z]' '[A-Z]')]"
            fi
            SRC_TOKEN="${SRC_TOKEN}${chr}"
            ((c++))
        done
        SEDSD="${SEDSD};s/\\(${SRC_TOKEN}\\)/\\\\\\\\033[4;31m\\1\\\\\\\\033[0m/g"

        # find . \( -name ".[a-zA-Z]*" \) -prune -o -name 'RE*' -o -name '*log*' -print
        # find . | sed 's/\.\///;/^\./d;/\/\./d'
        # [ "${FIND}" ] && FIND="${FIND};"
    done
    if [ "${EGREPE}" ]; then
        EGREPE="${EGREPE}|${EGREP}"
    else
        EGREPE="${EGREP}"
    fi

    do_replace_action_in_fd=$("${do_replace_action_in_files[@]}" "${do_replace_action_in_dirs[@]}")
    [ "${do_replace_action_in_fd[@]}" ] || do_replace_action_in_fd=(.)
    update_find_data

    [ "${do_replace_action_dry_run}" ] || echo ${FS[@]} | xargs sed -i "${SEDS}"

    BASE_DIR="`pwd`"
    [ "`echo $(readlink -f "${BASE_DIR}") | grep ' '`" ] && { echo "Space can't be used in ${BASE_DIR}"; exit; }

    # for d in ${do_replace_action_in_fd[@]}; do
    if [ "${PROCESS_FILES[0]}${PROCESS_DIRS[0]}" ]; then
        # for d in $(find . -type f -o -type l -o -type d | sed 's/\.\///;/^\./d;/\/\./d' | egrep -i "${EGREPE}" | sort -r); do
        for d in $(echo -e ${FS[@]} ${FD[@]} | sed 's/  */ /g;s/ /\n/g' | sed 's/\.\///;/^\./d;/\/\./d' | egrep -i "${EGREPE}" | sort -r); do
            cd "${BASE_DIR}"
            if [ -d ${d} ]; then
                process_dir ${d} ${d}
            else
                process_rename ${d}
            fi
        done
    else
        for d in $(find . -type f -o -type l -o -type d | sed 's/\.\///;/^\./d;/\/\./d' | egrep -i "${EGREPE}" | sort -r); do
            cd "${BASE_DIR}"
            if [ -d ${d} ]; then
                process_dir ${d} ${d}
            else
                process_rename ${d}
            fi
        done
    fi

    [ "${do_replace_action_silent}" ] && return

    cd "${BASE_DIR}"
    if [ '' ]; then
        update_find_data
        if [ "${do_replace_action_dry_run}" ]; then
            egrep -i "${EGREP}" ${FS[@]}
        else
            egrep -i "${EGREP}" ${FS[@]} | sed "${SEDSEG}" | egrep -i "${EGREP}"
        fi
    else
        if [ "${do_replace_action_dry_run}" ]; then
            if [ "${in_bashrc}" ]; then
                egrep -inr --exclude="tags" --exclude="cscope.*" --exclude=".gitignore" --exclude-dir=".repo" --exclude-dir=".git" --exclude-dir=".recoll" --exclude-dir=".beagle" "${EGREP}" ${PROCESS_FILES[@]} ${PROCESS_DIRS[@]} | sed "${SEDSDR}"
            else
                egrep -inr --exclude="tags" --exclude="cscope.*" --exclude=".gitignore" --exclude-dir=".repo" --exclude-dir=".git" --exclude-dir=".recoll" --exclude-dir=".beagle" "${EGREP}" ${PROCESS_FILES[@]} ${PROCESS_DIRS[@]} | sed "${SEDSD}" | sed "${SEDSDR}" | xargs -L1 echo -e | sed '/^$/d'
            fi
        else
            if [ "${in_bashrc}" ]; then
                egrep -inr --exclude="tags" --exclude="cscope.*" --exclude=".gitignore" --exclude-dir=".repo" --exclude-dir=".git" --exclude-dir=".recoll" --exclude-dir=".beagle" "${EGREP}" ${PROCESS_FILES[@]} ${PROCESS_DIRS[@]} | sed "${SEDSEG}" | egrep -i "${EGREP}" | sed "${SEDSDR}"
            else
                egrep -inr --exclude="tags" --exclude="cscope.*" --exclude=".gitignore" --exclude-dir=".repo" --exclude-dir=".git" --exclude-dir=".recoll" --exclude-dir=".beagle" "${EGREP}" ${PROCESS_FILES[@]} ${PROCESS_DIRS[@]} | sed "${SEDSEG}" | egrep -i "${EGREP}" | sed "${SEDSD}" | sed "${SEDSDR}" | xargs -L1 echo -e | sed '/^$/d'
            fi
        fi
    fi
}

[ "${do_help_only}" ] || main
