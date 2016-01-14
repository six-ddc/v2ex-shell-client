#!/bin/bash

reset="\e[0m"

red="\e[0;31m"
green="\e[0;32m"
yellow="\e[0;33m"
blue="\e[0;34m"
pink="\e[0;35m"
cyan="\e[0;36m"

RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
PINK="\e[1;35m"
CYAN="\e[1;36m"

red_back="\e[0;41m"
green_back="\e[0;42m"
yellow_back="\e[0;43m"
blue_back="\e[0;44m"
pink_back="\e[0;45m"
cyan_back="\e[0;46m"

RET=""

MODE="none"
ARRAY=()
RRAY_TITLE=()
ARRAY_CONTENT=()

_topics() {
    if [ "$1" = "topics" ]; then
        tmpfile="/tmp/ddc.v2ex.topics.$2.json"
        curl -s -o $tmpfile "https://www.v2ex.com/api/topics/$2.json"
    elif [ "$1" = "node" ]; then
        tmpfile="/tmp/ddc.v2ex.node.$2.json"
        curl -s -o $tmpfile "https://www.v2ex.com/api/topics/show.json?node_name=$2"
    else
        return
    fi
    if [ `cat $tmpfile | jq -r ". | type"` != "array" ]; then
        printf "${red}节点名不存在，另外节点名称不支持中文，如酷工作请使用jobs${reset}\n"
        return
    fi
    LENGTH=`cat $tmpfile | jq ". | length"`
    if ! test $LENGTH; then
        return
    fi
    ARRAY=()
    ARRAY_TITLE=()
    ARRAY_CONTENT=()
    for((i = 0; i < $LENGTH; i++))
    do
        # 替换百分号可能引起的printf输出异常，只能在jq后解析，而不能单独通过echo解析
        title=`jq -r ".[$i].title" $tmpfile | sed "s/\%/\%\%/g"`
        content=`jq -r ".[$i].content" $tmpfile | sed "s/\%/\%\%/g"`
        member=`jq -r ".[$i].member.username" $tmpfile`
        node_title=`jq -r ".[$i].node.title" $tmpfile | sed "s/\%/\%\%/g"`
        replies=`jq -r ".[$i].replies" $tmpfile`
        title="$blue$node_title$reset $green$title$reset $pink$member$reset($cyan$replies$reset)"
        id=`jq -r ".[$i].id" $tmpfile`
        ARRAY[$(($i+1))]=$id
        ARRAY_TITLE[$(($i+1))]="$title"
        ARRAY_CONTENT[$(($i+1))]="$content"
        printf "%2d. $title\n" "$(($i+1))"
    done
    # echo ${ARRAY[@]}
}

_date() {
    if [ `uname` = "Darwin" ]; then
        if [ `date +%Y` -eq `date -r $1 +%Y` ]; then
            if [ `date +%m` -eq `date -r $1 +%m` ] && [ `date +%d` -eq `date -r $1 +%d` ]; then
                RET=`date -r $1 +"%H:%M:%S"`
            else
                RET=`date -r $1 +"%m-%d %H:%M:%S"`
            fi
        else
            RET=`date -r $1 +"%Y-%m-%d %H:%M:%S"`
        fi
    else
        if [ `date +%Y` -eq `date -d @$1 +%Y` ]; then
            if [ `date +%m` -eq `date -d @$1 +%m` ] && [ `date +%d` -eq `date -d @$1 +%d` ]; then
                RET=`date -d @$1 +"%H:%M:%S"`
            else
                RET=`date -d @$1 +"%m-%d %H:%M:%S"`
            fi
        else
            RET=`date -d @$1 +"%Y-%m-%d %H:%M:%S"`
        fi
    fi
}

_categories() {
    cate_tmpfile="/tmp/ddc.v2ex.cate.tmp"
    curl -s -o $cate_tmpfile "https://www.v2ex.com/?tab=$1"
    # grep的文件和重定向不能是同一个文件
    grep '<span class="item_title">' $cate_tmpfile > $cate_tmpfile.grep
    reg_id='<a href="/t/([0-9]+)'
    ARRAY=()
    ARRAY_TITLE=()
    ARRAY_CONTENT=()
    i=1
    while read line
    do
        if [[ $line =~ $reg_id ]]; then
            id=${BASH_REMATCH[1]}
            curl -s -o $cate_tmpfile "https://www.v2ex.com/api/topics/show.json?id=$id"
            title=`jq -r ".[0].title" $cate_tmpfile | sed "s/\%/\%\%/g"`
            content=`jq -r ".[0].content" $cate_tmpfile | sed "s/\%/\%\%/g"`
            member=`jq -r ".[0].member.username" $cate_tmpfile`
            node_title=`jq -r ".[0].node.title" $cate_tmpfile | sed "s/\%/\%\%/g"`
            replies=`jq -r ".[0].replies" $cate_tmpfile`
            title="$blue$node_title$reset $green$title$reset $pink$member$reset($cyan$replies$reset)"
            ARRAY[$i]=$id
            ARRAY_TITLE[$i]="$title"
            ARRAY_CONTENT[$i]="$content"
            printf "%2d. $title\n" "$i"
            i=$(($i+1))
            if [ $i -gt 10 ]; then
                break
            fi
        fi    
    done < $cate_tmpfile.grep
}

_replies() {
    id=${ARRAY[$1]}
    if ! test $id; then
        printf "${red}列表序列号越界${reset}\n"
        _usage
        return
    fi
    replies_tmpfile="/tmp/ddc.v2ex.replies.tmp"
    printf "${ARRAY_TITLE[$1]}\n${green}${ARRAY_CONTENT[$1]}${reset}\n" > $replies_tmpfile
    tmpfile="/tmp/ddc.v2ex.replies.json"
    curl -s -o $tmpfile "https://www.v2ex.com/api/replies/show.json?topic_id=$id"
    LENGTH=`cat $tmpfile | jq ". | length"`
    if ! test $LENGTH; then
        return
    fi
    for((i = 0; i < $LENGTH; i++))
    do
        content=`jq -r ".[$i].content" $tmpfile | sed "s/\%/\%\%/g"`
        member=`jq -r ".[$i].member.username" $tmpfile`
        created=`jq -r ".[$i].created" $tmpfile`
        thanks=`jq -r ".[$i].thanks" $tmpfile`
        _date $created
        created=$RET
        id=`jq -r ".[$i].member.id" $tmpfile`
        if [ $thanks != "0" ]; then
            printf "\n${blue}%3dL${reset}. $pink$member$reset $cyan$created$reset ♥️ $RED$thanks$reset\n${green}$content${reset}\n" "$(($i+1))" >> $replies_tmpfile
        else
            printf "\n${blue}%3dL${reset}. $pink$member$reset $cyan$created$reset\n${green}$content${reset}\n" "$(($i+1))" >> $replies_tmpfile
        fi
    done
    # 只有加上-r选项，多行文本的ascii color才会被当作一行处理显示，但是却有回滚时颜色不连续的异常，属于less的bug，暂不能解决。
    less -rms $replies_tmpfile
}

_sel() {
    case "$MODE" in
        hot | late | node | cate)
            _replies $1
            ;;
        *)
            ;;
    esac
}

_login() {
    tmpfile="/tmp/ddc.v2ex.signin.html"
    cookie_file="/tmp/ddc.v2ex.cookie.txt"
    v2ex_sign='https://www.v2ex.com/signin'
    curl -s -o $tmpfile -c $cookie_file -b $cookie_file $v2ex_sign
    grep '登出' $tmpfile > /dev/null
    if [ $? -eq 0 ]; then
        printf "${green}已经登录...${reset}\n"
    else
        once=`grep 'name="once"' $tmpfile`
        reg_once='value="([0-9]+)" name="once"'
        if [[ $once =~ $reg_once ]]; then
            once=${BASH_REMATCH[1]}
            echo $once
            curl -s -c $cookie_file -b $cookie_file -d "u=$1&p=$2&once=${once}&next=/" -e "$v2ex_sign" $v2ex_sign
        else
            printf "${red}登录异常...${reset}\n"
            return 1
        fi
    fi
    printf "获取用户信息...\n"
    curl -s -o $tmpfile -b $cookie_file https://www.v2ex.com/
    user_info=`grep "/notifications" $tmpfile`
    reg_user='balance_area.*>[ ]*([0-9]+)[ ]*<img.*silver.*>[ ]*([0-9]+)[ ]*<img.*/notifications.*>(.+)</a></div>$'
    if [[ $user_info =~ $reg_user ]]; then
        silver=${BASH_REMATCH[1]}
        bronze=${BASH_REMATCH[2]}
        notifi=${BASH_REMATCH[3]}
        printf "$green$silver 银币 $bronze 铜币 $notifi$reset\n"
    else
        printf "${red}获取用户信息异常...${reset}\n"
        return 1
    fi
    return 0
}

_test() {
    printf "test...\n"
}

_usage() {
    printf "Usage:\n"
    printf "\thot: 热门主题\n"
    printf "\tlate: 最新主题\n"
    printf "\tlogin <username> <password>: 登录\n"
    printf "\tcate <tech|creative|play|apple|jobs|deals|city|qna|hot|all|r2|nodes|members>: 获取指定分类的主题\n"
    printf "\tnode <nodename>: 获取节点的主题\n"
    printf "\t<num>: 获取指定主题的回复列表\n"
    printf "\thelp: 查看帮助\n"
    printf "\tq|quit: 退出\n"
}

which jq > /dev/null
if [ $? != 0 ]; then
    printf "${red}脚本依赖的执行程序jq不存在，安装参考README.md${reset}\n"
    exit 1
fi

while true
do
    UPMODE=`echo $MODE | tr "[:lower:]" "[:upper:]"`
    printf "$UPMODE # "
    read data
    if ! test "$data"; then
        continue
    fi
    op=`echo $data | cut -d " " -f 1`
    case "$op" in
        q | quit)
            break
            ;;
        late)
            _topics topics latest
            MODE=$op
            ;;
        hot)
            _topics topics hot
            MODE=$op
            ;;
        cate)
            name=`echo $data | cut -d " " -f 2`
            if [ $name != $op ]; then
                _categories $name
                MODE=$op
            else
                printf "${red}使用cate <catename>格式${reset}\n"
            fi
            ;;
        login)
            username=`echo $data | cut -d " " -f 2`
            password=`echo $data | cut -d " " -f 3`
            if [ $password != $op ]; then
                _login $username $password
                if [ $? -eq 0 ]; then
                    MODE=$op
                fi
            else
                printf "${red}使用login <username> <password>格式${reset}\n"
            fi
            ;;
        node)
            node=`echo $data | cut -d " " -f 2`
            if [ $node != $op ]; then
                _topics node $node
                MODE=$op
            else
                printf "${red}使用node <nodename>格式${reset}\n"
            fi
            ;;
        help)
            _usage
            ;;
        test)
            _test
            exit 0
            ;;
        *)
            if [ $op -eq $op ] 2>/dev/null ; then
                if [ $MODE = "none" ]; then
                    printf "${red}请先选择主题列表${reset}\n"
                    _usage
                fi
                _sel $op
            else
                _usage
            fi
            ;;
    esac
done
