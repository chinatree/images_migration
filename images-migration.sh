#!/bin/bash
# Author  : chinatree <chinatree2012@gmail.com>
# Date    : 2021-11-15
# Version : 1.0.0

# [global]
SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)
PROJECT_ROOT=$(cd "${SCRIPT_PATH}"; pwd)
RELATIVE_PATH=$(echo "${SCRIPT_PATH}" | sed 's#'$(pwd)'#\##g' | sed 's#^\##.#')
SCRIPT_NAME=$(basename "$0")


get_color()
{
    case "${2:-NONE}" in
    BOLD)
        echo -ne "\033[1m"$1"\033[0m"
        ;;
    UNDERLINE)
        echo -ne "\033[4m"$1"\033[0m"
        ;;
    RED)
        echo -ne "\033[0;31;40m"$1"\033[0m"
        ;;
    GREEN)
        echo -ne "\033[0;32;40m"$1"\033[0m"
        ;;
    BROWN)
        echo -ne "\033[33m"$1"\033[0m"
        ;;
    PURPLE)
        echo -ne "\033[0;35;40m"$1"\033[0m"
        ;;
    PEACH)
        echo -ne "\033[1;31;40m"$1"\033[0m"
        ;;
    YELLOW)
        echo -ne "\033[1;33;40m"$1"\033[0m"
        ;;
    CYANBLUE)
        echo -ne "\033[36m"$1"\033[0m"
        ;;
    PORTMPT)
        echo -ne "\033[5;37;44m"$1"\033[0m"
        ;;
    *)
        echo -ne "$1"
        ;;
    esac
}

get_fixed_width()
{
    local str="${1:-NONE}"
    local length="${2:-0}"
    local isEnter="${3:-NONE}"
    case "${length:-NONE}" in
    12)
        printf "%-12s" "${str}"
        ;;
    20)
        printf "%-20s" "${str}"
        ;;
    50)
        printf "%-50s" "${str}"
        ;;
    66)
        printf "%-66s" "${str}"
        ;;
    88)
        printf "%-88s" "${str}"
        ;;
    *)
        printf "%${length}s" "${str}"
        ;;
    esac
    if [ "${isEnter}" = "Y" ];
    then
        echo -ne "\n";
    fi
}

usage() {
    echo -e "$(get_color "Usage:" CYANBLUE) \
    \n    ${RELATIVE_PATH}/${SCRIPT_NAME} [-a <all|list|pull|tag|push|rmi|pull_tag>] [-pf <1|0>] [-f <image list file>] \
    \n      $(get_fixed_width "-a, --action" -24)do action, default: list \
    \n      $(get_fixed_width "-pf, --platform" -24)type for enable or disable plarform check and insert to path, default: 1 \
    \n      $(get_fixed_width "-f" -24)image list file, default: hub_to_harbor_common.list \
    \n\n`get_color "action:" PEACH` \
    \n    $(get_fixed_width $(get_color "all" GREEN) -40)contains $(get_color "pull、tag、push" GREEN) action \
    \n    $(get_fixed_width $(get_color "pull_tag" GREEN) -40)contains $(get_color "pull、tag" GREEN) action \
    \n    $(get_fixed_width $(get_color "list" GREEN) -40)list iamges \
    \n    $(get_fixed_width $(get_color "pull" GREEN) -40)pull images \
    \n    $(get_fixed_width $(get_color "tag" GREEN) -40)tag images \
    \n    $(get_fixed_width $(get_color "push" GREEN) -40)push images \
    \n    $(get_fixed_width $(get_color "rmi" GREEN) -40)deletes images \
    \n    ${RELATIVE_PATH}/${SCRIPT_NAME} -a all \
    \n    ${RELATIVE_PATH}/${SCRIPT_NAME} -a pull_tag -pf=0 \
    \n    ${RELATIVE_PATH}/${SCRIPT_NAME} -a pull -pf=0 \
    \n    ${RELATIVE_PATH}/${SCRIPT_NAME} -a tag -pf=0 -f hub_to_harbor_common.list"
    exit 2
}

# Parse args use while
parse_arguments_while() {
    while [ $# -gt 0 ]
    do
        case "${1:-NONE}" in
            -a|--action)
                shift
                ACTION="$1"
                ;;
            -pf|--platform)
                shift
                PLATFORM_ENABLE="$1"
                ;;
            -f)
                shift
                IMAGES_LIST_FILENAME="$1"
                ;;
            -h|--help)
                usage
                ;;
            -D|--debug)
                set -x
                ;;
        esac
        shift
    done
}

choice_platform() {
    platform=$(uname -m)
    if [ x"${platform}" == x"x86_64" ];
    then
        platform="amd64"
    elif [ x"${platform}" == x"aarch64" ];
    then
        platform="arm64"
    fi
    echo "${platform}"
    return 0
}

strip() {
    local str="${1}"
    echo "$(echo ${str} | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')"
    return 0
}

pull() {
    local annotation_flag name tag archs pull_image pull_host pull_prefix push_host push_prefix stage_prefix extend_tags
    while read line
    do
        annotation_flag=$(strip "$(echo "${line}" | grep -E "^#|^$" | wc -l)")
        test "${annotation_flag}" -eq 1 && continue
        name=$(strip "$(echo "${line}" | awk -F "|" "{print \$1}")")
        tag=$(strip "$(echo "${line}" | awk -F "|" "{print \$2}")")
        archs=$(strip "$(echo "${line}" | awk -F "|" "{print \$3}")")
        pull_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$4}")")
        pull_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$5}")")
        push_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$6}")")
        push_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$7}")")
        stage_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$8}")")
        extend_tags=$(strip "$(echo "${line}" | awk -F "|" "{print \$9}")")
        test -z "${archs}" && archs=$(choice_platform)

        pull_image="${name}:${tag}"
        test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && pull_image="$(choice_platform)/${pull_image}"
        test -n "${pull_prefix}" && pull_image="${pull_prefix}/${pull_image}"
        test -n "${pull_host}" && pull_image="${pull_host}/${pull_image}"

        echo "docker pull ${pull_image}"
        docker pull "${pull_image}"
    done < ${IMAGES_LIST_FILENAME}
    return 0
}

tag() {
    local annotation_flag name tag archs pull_image pull_host pull_prefix push_host push_prefix stage_prefix extend_tags
    while read line
    do
        annotation_flag=$(strip "$(echo "${line}" | grep -E "^#|^$" | wc -l)")
        test "${annotation_flag}" -eq 1 && continue
        name=$(strip "$(echo "${line}" | awk -F "|" "{print \$1}")")
        tag=$(strip "$(echo "${line}" | awk -F "|" "{print \$2}")")
        archs=$(strip "$(echo "${line}" | awk -F "|" "{print \$3}")")
        pull_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$4}")")
        pull_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$5}")")
        push_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$6}")")
        push_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$7}")")
        stage_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$8}")")
        extend_tags=$(strip "$(echo "${line}" | awk -F "|" "{print \$9}")")
        test -z "${archs}" && archs=$(choice_platform)

        pull_image="${name}:${tag}"
        test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && pull_image="$(choice_platform)/${pull_image}"
        test -n "${pull_prefix}" && pull_image="${pull_prefix}/${pull_image}"
        test -n "${pull_host}" && pull_image="${pull_host}/${pull_image}"
        echo "=============================="
        echo "==== ${pull_image}"
        echo "=============================="

        # 原始标签
        push_image="${name}:${tag}"
        test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
        test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
        test -n "${push_host}" && push_image="${push_host}/${push_image}"
        echo "docker tag ${pull_image} ${push_image}"
        docker tag "${pull_image}" "${push_image}"

        for extend_tag in $(echo "${extend_tags}" | awk -F ";" "{for(i=1;i<=NF;i++){print \$i}}")
        do
            # 别名标签，同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${pull_prefix}" && push_image="${pull_prefix}/${push_image}"
            test -n "${pull_host}" && push_image="${pull_host}/${push_image}"
            echo "docker tag ${pull_image} ${push_image}"
            docker tag "${pull_image}" "${push_image}"

            # 别名标签，不同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
            test -n "${push_host}" && push_image="${push_host}/${push_image}"
            echo "docker tag ${pull_image} ${push_image}"
            docker tag "${pull_image}" "${push_image}"
        done
    done < ${IMAGES_LIST_FILENAME}
    return 0
}

push() {
    local pull_image pull_host pull_prefix push_image push_host push_prefix
    while read line
    do
        annotation_flag=$(strip "$(echo "${line}" | grep -E "^#|^$" | wc -l)")
        test "${annotation_flag}" -eq 1 && continue
        name=$(strip "$(echo "${line}" | awk -F "|" "{print \$1}")")
        tag=$(strip "$(echo "${line}" | awk -F "|" "{print \$2}")")
        archs=$(strip "$(echo "${line}" | awk -F "|" "{print \$3}")")
        pull_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$4}")")
        pull_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$5}")")
        push_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$6}")")
        push_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$7}")")
        stage_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$8}")")
        extend_tags=$(strip "$(echo "${line}" | awk -F "|" "{print \$9}")")
        test -z "${archs}" && archs=$(choice_platform)

        pull_image="${name}:${tag}"
        test -n "${pull_prefix}" && pull_image="${pull_prefix}/${pull_image}"
        test -n "${pull_host}" && pull_image="${pull_host}/${pull_image}"
        echo "=============================="
        echo "==== ${pull_image}"
        echo "=============================="

        # 原始标签
        push_image="${name}:${tag}"
        test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
        test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
        test -n "${push_host}" && push_image="${push_host}/${push_image}"
        echo "docker push ${push_image}"
        docker push "${push_image}"

        for extend_tag in $(echo "${extend_tags}" | awk -F ";" "{for(i=1;i<=NF;i++){print \$i}}")
        do
            # 别名标签
            push_image="${name}:${extend_tag}"
            test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
            test -n "${push_host}" && push_image="${push_host}/${push_image}"
            echo "docker push ${push_image}"
            docker push "${push_image}"
        done
    done < ${IMAGES_LIST_FILENAME}
    return 0
}

rmi() {
    local pull_image pull_host pull_prefix push_image push_host push_prefix
    while read line
    do
        annotation_flag=$(strip "$(echo "${line}" | grep -E "^#|^$" | wc -l)")
        test "${annotation_flag}" -eq 1 && continue
        name=$(strip "$(echo "${line}" | awk -F "|" "{print \$1}")")
        tag=$(strip "$(echo "${line}" | awk -F "|" "{print \$2}")")
        archs=$(strip "$(echo "${line}" | awk -F "|" "{print \$3}")")
        pull_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$4}")")
        pull_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$5}")")
        push_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$6}")")
        push_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$7}")")
        stage_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$8}")")
        extend_tags=$(strip "$(echo "${line}" | awk -F "|" "{print \$9}")")
        test -z "${archs}" && archs=$(choice_platform)

        pull_image="${name}:${tag}"
        test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && pull_image="$(choice_platform)/${pull_image}"
        test -n "${pull_prefix}" && pull_image="${pull_prefix}/${pull_image}"
        test -n "${pull_host}" && pull_image="${pull_host}/${pull_image}"
        echo "=============================="
        echo "==== ${name}:${tag}"
        echo "=============================="
        echo "docker rmi ${pull_image}"
        docker rmi "${pull_image}"

        # 原始标签
        push_image="${name}:${tag}"
        test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
        test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
        test -n "${push_host}" && push_image="${push_host}/${push_image}"
        echo "docker rmi ${push_image}"
        docker rmi "${push_image}"

        for extend_tag in $(echo "${extend_tags}" | awk -F ";" "{for(i=1;i<=NF;i++){print \$i}}")
        do
            # 别名标签，同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${pull_prefix}" && push_image="${pull_prefix}/${push_image}"
            test -n "${pull_host}" && push_image="${pull_host}/${push_image}"
            echo "docker rmi ${push_image}"
            docker rmi "${push_image}"

            # 别名标签，不同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
            test -n "${push_host}" && push_image="${push_host}/${push_image}"
            echo "docker rmi ${push_image}"
            docker rmi "${push_image}"
        done
    done < ${IMAGES_LIST_FILENAME}
    return 0
}

list() {
    local pull_image pull_host pull_prefix push_image push_host push_prefix
    while read line
    do
        annotation_flag=$(strip "$(echo "${line}" | grep -E "^#|^$" | wc -l)")
        test "${annotation_flag}" -eq 1 && continue
        name=$(strip "$(echo "${line}" | awk -F "|" "{print \$1}")")
        tag=$(strip "$(echo "${line}" | awk -F "|" "{print \$2}")")
        archs=$(strip "$(echo "${line}" | awk -F "|" "{print \$3}")")
        pull_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$4}")")
        pull_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$5}")")
        push_host=$(strip "$(echo "${line}" | awk -F "|" "{print \$6}")")
        push_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$7}")")
        stage_prefix=$(strip "$(echo "${line}" | awk -F "|" "{print \$8}")")
        extend_tags=$(strip "$(echo "${line}" | awk -F "|" "{print \$9}")")
        test -z "${archs}" && archs=$(choice_platform)

        pull_image="${name}:${tag}"
        test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && pull_image="$(choice_platform)/${pull_image}"
        test -n "${pull_prefix}" && pull_image="${pull_prefix}/${pull_image}"
        test -n "${pull_host}" && pull_image="${pull_host}/${pull_image}"
        echo "=============================="
        echo "==== ${pull_image}"
        echo "=============================="
        echo "${pull_image}"

        # 原始标签
        push_image="${name}:${tag}"
        test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
        test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
        test -n "${push_host}" && push_image="${push_host}/${push_image}"
        echo "${push_image}"

        for extend_tag in $(echo "${extend_tags}" | awk -F ";" "{for(i=1;i<=NF;i++){print \$i}}")
        do
            # 别名标签，同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${pull_prefix}" && test -n "${pull_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${pull_prefix}" && push_image="${pull_prefix}/${push_image}"
            test -n "${pull_host}" && push_image="${pull_host}/${push_image}"
            echo "${push_image}"

            # 别名标签，不同地址不同标签
            push_image="${name}:${extend_tag}"
            test -n "${push_prefix}" && test -n "${push_host}" && test ${PLATFORM_ENABLE} -eq 1 && push_image="$(choice_platform)/${push_image}"
            test -n "${push_prefix}" && push_image="${push_prefix}/${push_image}"
            test -n "${push_host}" && push_image="${push_host}/${push_image}"
            echo "${push_image}"
        done
    done < ${IMAGES_LIST_FILENAME}
    return 0
}

cd "${PROJECT_ROOT}"
PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin"
export PATH
ACTION="list"
PLATFORM_ENABLE=1
IMAGES_LIST_FILENAME="hub_to_harbor_common.list"
parse_arguments_while $@
test ! -f ${IMAGES_LIST_FILENAME} && echo "The file ${IMAGES_LIST_FILENAME} not exists, please check it and try again!" && exit 2


case "${ACTION}" in
list)
    list
    ;;
pull)
    pull
    ;;
tag)
    tag
    ;;
push)
    push
    ;;
rmi)
    rmi
    ;;
pull_tag)
    pull
    tag
    ;;
all)
    pull
    tag
    push
    ;;
*)
    usage
    ;;
esac

exit 0
