#!/bin/sh

# set -xe

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
HTTP=""

USER_NAME=""
MODE="none"
ARRAY=()
RRAY_TITLE=()
ARRAY_CONTENT=()

TEMP_FILE="/tmp/ddc.v2ex.shell.tmp"
COOKIE_FILE="cookie.jar"
LOGIN_STATE=0

_topics() {
    if [ "$1" = "topics" ]; then
        if test "$HTTP"; then
            $HTTP "https://www.v2ex.com/api/topics/$2.json" > $TEMP_FILE
        else
            curl -s -o $TEMP_FILE "https://www.v2ex.com/api/topics/$2.json"
        fi
    elif [ "$1" = "node" ]; then
        if test "$HTTP"; then
            $HTTP -f GET "https://www.v2ex.com/api/topics/show.json?node_name=$2" > $TEMP_FILE
        else
            curl -s -o $TEMP_FILE "https://www.v2ex.com/api/topics/show.json?node_name=$2"
        fi
    else
        return
    fi
    if [ "$(cat $TEMP_FILE | jq -r '. | type')" != "array" ]; then
        printf "${red}节点名不存在，另外节点名称不支持中文，如酷工作请使用jobs${reset}\n"
        return
    fi
    LENGTH=$(cat $TEMP_FILE | jq ". | length")
    if ! test $LENGTH; then
        return
    fi
    ARRAY=()
    ARRAY_TITLE=()
    ARRAY_CONTENT=()
    for((i = 0; i < $LENGTH; i++))
    do
        # 替换百分号可能引起的printf输出异常，只能在jq后解析，而不能单独通过echo解析
        title=$(jq -r ".[$i].title" $TEMP_FILE | sed "s/\%/\%\%/g")
        content=$(jq -r ".[$i].content" $TEMP_FILE | sed "s/\%/\%\%/g")
        member=$(jq -r ".[$i].member.username" $TEMP_FILE)
        node_title=$(jq -r ".[$i].node.title" $TEMP_FILE | sed "s/\%/\%\%/g")
        replies=$(jq -r ".[$i].replies" $TEMP_FILE)
        title="$blue$node_title$reset $green$title$reset $pink$member$reset($cyan$replies$reset)"
        id=$(jq -r ".[$i].id" $TEMP_FILE)
        ARRAY[$(($i+1))]=$id
        ARRAY_TITLE[$(($i+1))]="$title"
        ARRAY_CONTENT[$(($i+1))]="$content"
        printf "%2d. $title\n" "$(($i+1))"
    done
    # echo ${ARRAY[@]}
}

_date() {
    if [ $(uname) = "Darwin" ]; then
        if [ $(date +%Y) -eq $(date -r $1 +%Y) ]; then
            if [ $(date +%m) -eq $(date -r $1 +%m) ] && [ $(date +%d) -eq $(date -r $1 +%d) ]; then
                RET=$(date -r $1 +"%H:%M:%S")
            else
                RET=$(date -r $1 +"%m-%d %H:%M:%S")
            fi
        else
            RET=$(date -r $1 +"%Y-%m-%d %H:%M:%S")
        fi
    else
        if [ $(date +%Y) -eq $(date -d @$1 +%Y) ]; then
            if [ $(date +%m) -eq $(date -d @$1 +%m) ] && [ $(date +%d) -eq $(date -d @$1 +%d) ]; then
                RET=$(date -d @$1 +"%H:%M:%S")
            else
                RET=$(date -d @$1 +"%m-%d %H:%M:%S")
            fi
        else
            RET=$(date -d @$1 +"%Y-%m-%d %H:%M:%S")
        fi
    fi
}

_categories() {
    if test "$HTTP"; then
        # $HTTP --session v2ex -f GET "https://www.v2ex.com/?tab=$1" > $TEMP_FILE
        curl -s -b $COOKIE_FILE -o $TEMP_FILE "https://www.v2ex.com/?tab=$1"
    else
        curl -s -b $COOKIE_FILE -o $TEMP_FILE "https://www.v2ex.com/?tab=$1"
    fi
    # grep的文件和重定向不能是同一个文件
    grep '<span class="item_title">' $TEMP_FILE > $TEMP_FILE.grep
    reg_id='<a href="/t/([0-9]+)'
    ARRAY=()
    ARRAY_TITLE=()
    ARRAY_CONTENT=()
    i=1
    while read line
    do
        if [[ $line =~ $reg_id ]]; then
            id=${BASH_REMATCH[1]}
            if test "$HTTP"; then
                # 对于重定向的循环中，httpie需要忽略标准输入
                $HTTP --ignore-stdin -f GET "https://www.v2ex.com/api/topics/show.json?id=$id" > $TEMP_FILE
            else
                curl -s -o $TEMP_FILE "https://www.v2ex.com/api/topics/show.json?id=$id"
            fi
            title=$(jq -r ".[0].title" $TEMP_FILE | sed "s/\%/\%\%/g")
            content=$(jq -r ".[0].content" $TEMP_FILE | sed "s/\%/\%\%/g")
            member=$(jq -r ".[0].member.username" $TEMP_FILE)
            node_title=$(jq -r ".[0].node.title" $TEMP_FILE | sed "s/\%/\%\%/g")
            replies=$(jq -r ".[0].replies" $TEMP_FILE)
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
    done < $TEMP_FILE.grep
}

_replies() {
    id=${ARRAY[$1]}
    if ! test $id; then
        printf "${red}列表序列号越界${reset}\n"
        _usage
        return
    fi
    replies_tmpfile="$TEMP_FILE.less"
    printf "${ARRAY_TITLE[$1]}\n${green}${ARRAY_CONTENT[$1]}${reset}\n" > $replies_tmpfile
    if test "$HTTP"; then
        $HTTP -f GET "https://www.v2ex.com/api/replies/show.json?topic_id=$id" > $TEMP_FILE
    else
        curl -s -o $TEMP_FILE "https://www.v2ex.com/api/replies/show.json?topic_id=$id"
    fi
    LENGTH=$(cat $TEMP_FILE | jq ". | length")
    if ! test $LENGTH; then
        return
    fi
    for((i = 0; i < $LENGTH; i++))
    do
        content=$(jq -r ".[$i].content" $TEMP_FILE | sed "s/\%/\%\%/g")
        member=$(jq -r ".[$i].member.username" $TEMP_FILE)
        created=$(jq -r ".[$i].created" $TEMP_FILE)
        thanks=$(jq -r ".[$i].thanks" $TEMP_FILE)
        _date $created
        created=$RET
        id=$(jq -r ".[$i].member.id" $TEMP_FILE)
        if [ $thanks != "0" ]; then
            printf "\n${blue}%3dL${reset}. $pink$member$reset $cyan$created$reset ♥️ $RED$thanks$reset\n${green}$content${reset}\n" "$(($i+1))" >> $replies_tmpfile
        else
            printf "\n${blue}%3dL${reset}. $pink$member$reset $cyan$created$reset\n${green}$content${reset}\n" "$(($i+1))" >> $replies_tmpfile
        fi
    done
    # 只有加上-r选项，多行文本的ascii color才会被当作一行处理显示，但是却有回滚时颜色不连续的异常，属于less的bug，暂不能解决。
    less -rCm $replies_tmpfile
}

_sel() {
    if [ ${#ARRAY[@]} -gt 0 ]; then
        _replies $1
    else
        printf "${red}请先获取主题列表${reset}\n"
        _usage
    fi
}

_login() {
    v2ex_sign='https://www.v2ex.com/signin'
    if test "$HTTP"; then
        if test "$1"; then
            USER_NAME=""
            rm -f ~/.httpie/sessions/www.v2ex.com/v2ex.json > /dev/null
        fi
        $HTTP --session v2ex $v2ex_sign > $TEMP_FILE
    else
        if test "$1"; then
            curl -s -o $TEMP_FILE -c $COOKIE_FILE $v2ex_sign
        else
            curl -s -o $TEMP_FILE -c $COOKIE_FILE -b $COOKIE_FILE $v2ex_sign
        fi
    fi
    grep '登出' $TEMP_FILE > /dev/null
    if [ $? != 0 ]; then
        once=$(grep 'name="once"' $TEMP_FILE)
        reg_once='value="([0-9]+)" name="once"'
        if [[ $once =~ $reg_once ]]; then
            once=${BASH_REMATCH[1]}
            printf "username: "
            read username
            printf "password: "
            read -s password
            printf "\n"
            if test "$HTTP"; then
                $HTTP --session v2ex -f POST $v2ex_sign u=${username} p=${password} once=${once} next=/ Referer:$v2ex_sign > $TEMP_FILE
            else
                curl -s -o $TEMP_FILE -c $COOKIE_FILE -b $COOKIE_FILE -d "u=${username}&p=${password}&once=${once}&next=/" -e "$v2ex_sign" $v2ex_sign
            fi
            grep '用户名和密码无法匹配' $TEMP_FILE > /dev/null
            if [ $? -eq 0 ]; then
                printf "${red}用户名或密码错误...${reset}\n"
                return 1
            fi
        else
            printf "${red}登录异常...${reset}\n"
            return 1
        fi
    fi
    # printf "获取用户信息...\n"
    if test "$HTTP"; then
        $HTTP --session v2ex https://www.v2ex.com/ > $TEMP_FILE
    else
        curl -s -o $TEMP_FILE -b $COOKIE_FILE https://www.v2ex.com/
    fi
    user_info=$(grep "bigger.*member" $TEMP_FILE)
    reg_user='member.*>(.*)</a>'
    if [[ $user_info =~ $reg_user ]]; then
        USER_NAME="${BASH_REMATCH[1]}"
    else
        printf "${red}获取用户信息异常...${reset}\n"
        return 1
    fi
    user_info=$(grep "/notifications" $TEMP_FILE)
    reg_user='balance_area.*>[ ]*([0-9]+)[ ]*<img.*silver.*>[ ]*([0-9]+)[ ]*<img.*/notifications.*>(.+)</a></div>$'
    if [[ $user_info =~ $reg_user ]]; then
        silver=${BASH_REMATCH[1]}
        bronze=${BASH_REMATCH[2]}
        notifi=${BASH_REMATCH[3]}
        if [[ notifi =~ [1-9] ]]; then
            notifi="$notifi (https://www.v2ex.com/notifications)"
        fi
        printf "$pink$USER_NAME$reset $green$silver 银币 $bronze 铜币 $notifi$reset\n"
    else
        # 只有银币的情况
        reg_user='balance_area.*>[ ]*([0-9]+)[ ]*<img.*silver.*>.*/notifications.*>(.+)</a></div>$'
        if [[ $user_info =~ $reg_user ]]; then
            silver=${BASH_REMATCH[1]}
            notifi=${BASH_REMATCH[2]}
            if [[ notifi =~ [1-9] ]]; then
                notifi="$notifi (https://www.v2ex.com/notifications)"
            fi
            printf "$pink$USER_NAME$reset $green$silver 银币 $notifi$reset\n"
        else
            printf "${red}获取用户信息异常...${reset}\n"
            return 1
        fi
    fi
    LOGIN_STATE=1
    return 0
}

_daily() {
    if ! test $HTTP; then
        printf "${red}签到需要依赖的执行程序httpie不存在，安装参考README.md${reset}\n"
        return 1
    fi
    if [ $LOGIN_STATE -eq 0 ]; then
        _login
    fi
    user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
    mission_daily="https://www.v2ex.com/mission/daily"
    if test "$HTTP"; then
        $HTTP --session v2ex $mission_daily "Referer:https://www.v2ex.com" "User-Agent:$user_agent" > $TEMP_FILE
    else
        curl -s -o $TEMP_FILE -b $COOKIE_FILE -c $COOKIE_FILE -e "https://www.v2ex.com" -A "$user_agent" $mission_daily
    fi
    redeem=$(grep 'mission/daily/redeem' $TEMP_FILE)
    if ! test "$redeem"; then
        printf "${green}今天已经签到...${reset}\n"
        return 1
    fi
    reg_redeem="/mission/daily/redeem\?once=(.*)'"
    if [[ $redeem =~ $reg_redeem ]]; then
        if test "$HTTP"; then
            $HTTP --session v2ex -f GET "https://www.v2ex.com/mission/daily/redeem?once=${BASH_REMATCH[1]}" "Referer:$mission_daily" "User-Agent:$user_agent" > $TEMP_FILE
            $HTTP --session v2ex $mission_daily "Referer:$mission_daily" "User-Agent:$user_agent" > $TEMP_FILE
        else
            curl -s -o $TEMP_FILE -b $COOKIE_FILE -c $COOKIE_FILE -e $mission_daily -A "$user_agent" "https://www.v2ex.com/mission/daily/redeem?once=${BASH_REMATCH[1]}"
            curl -s -o $TEMP_FILE -b $COOKIE_FILE -c $COOKIE_FILE -e $mission_daily -A "$user_agent" $mission_daily
        fi
        grep '每日登录奖励已领取' $TEMP_FILE > /dev/null
        if [ $? -eq 0 ]; then
            cont=$(grep '已连续登录' $TEMP_FILE)
            reg_cont="(已连续登录.*天)"
            if [[ $cont =~ $reg_cont ]]; then
                printf "${green}签到成功，${BASH_REMATCH[1]}${reset}\n"
                return 0
            fi
        fi
    fi
    printf "${red}签到异常...${reset}\n"
    return 1
}

_test() {
    printf "test...\n"
}

_usage() {
    cat << EOF
---------------------------------------------------------------------------------------------------------------
    hot             | 热门主题
    late            | 最新主题
    login/relogin   | 登录/重新登录
    daily           | 领取每日签到奖励
    cate <catename> | 获取指定分类的主题<tech|creative|play|apple|jobs|deals|city|qna|hot|all|r2|nodes|members>
    node <nodename> | 获取节点的主题
    <num>           | 查看指定主题序号的所有回复
    help            | 查看帮助
    q|quit          | 退出
---------------------------------------------------------------------------------------------------------------
EOF
}

type jq >/dev/null 2>/dev/null
if [ $? != 0 ]; then
    printf "${red}脚本依赖的执行程序jq不存在，安装参考README.md${reset}\n"
    exit 1
fi

type http >/dev/null 2>/dev/null
if [ $? = 0 ]; then
    HTTP=http
fi

while true
do
    if [ $# -gt 0 ]; then
        data=$@
    else
        UPMODE=$(echo $MODE | tr "[:lower:]" "[:upper:]")
        if test "$USER_NAME"; then
            printf "($pink$USER_NAME$reset) $UPMODE # "
        else
            printf "$UPMODE # "
        fi
        read data
        if ! test "$data"; then
            continue
        fi
    fi
    op=$(echo $data | cut -d " " -f 1)
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
            name=$(echo $data | cut -d " " -f 2)
            if [ $name != $op ]; then
                _categories $name
                MODE=$op
            else
                printf "${red}使用cate <catename>格式${reset}\n"
            fi
            ;;
        login | relogin)
            if [ $op = "relogin" ]; then
                _login  1
            else
                _login
            fi
            if [ $? -eq 0 ]; then
                MODE="LOGIN"
            fi
            ;;
        daily)
            _daily
            ;;
        node)
            node=$(echo $data | cut -d " " -f 2)
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
                # 是数字
                _sel $op
            else
                _usage
            fi
            ;;
    esac
    if [ $# -gt 0 ]; then
        break
    fi
done
