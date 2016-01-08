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
    ARRAY=()
    ARRAY_TITLE=()
    ARRAY_CONTENT=()
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
    for((i = 0; i < $LENGTH; i++))
    do
        title=`jq -r ".[$i].title" $tmpfile`
        content=`jq -r ".[$i].content" $tmpfile`
        member=`jq -r ".[$i].member.username" $tmpfile`
        node_title=`jq -r ".[$i].node.title" $tmpfile`
        replies=`jq -r ".[$i].replies" $tmpfile`
        id=`jq -r ".[$i].id" $tmpfile`
        title="$blue$node_title$reset $green$title$reset $pink$member$reset($cyan$replies$reset)"
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

_replies() {
    id=${ARRAY[$1]}
    if ! test $id; then
        printf "${red}列表序列号越界${reset}\n"
        _usage
        return
    fi
    printf "${ARRAY_TITLE[$1]}\n$cyan${ARRAY_CONTENT[$1]}$reset\n"
    tmpfile="/tmp/ddc.v2ex.replies.json"
    curl -s -o $tmpfile "https://www.v2ex.com/api/replies/show.json?topic_id=$id"
    LENGTH=`cat $tmpfile | jq ". | length"`
    if ! test $LENGTH; then
        return
    fi
    for((i = 0; i < $LENGTH; i++))
    do
        content=`jq -r ".[$i].content" $tmpfile`
        member=`jq -r ".[$i].member.username" $tmpfile`
        created=`jq -r ".[$i].created" $tmpfile`
        _date $created
        created=$RET
        id=`jq -r ".[$i].member.id" $tmpfile`
        printf "%3dL. $pink$member$reset $cyan$content$reset $created\n" "$(($i+1))"
    done
}

_sel() {
    case "$MODE" in
        hot | late | node)
            _replies $1
            ;;
        *)
            ;;
    esac
}

_usage() {
    printf "Usage:\n"
    printf "\thot: 热门主题\n"
    printf "\tlate: 最新主题\n"
    printf "\tnode <nodename>: 获取节点的主题\n"
    printf "\t<num>: 获取指定主题的回复列表\n"
    printf "\thelp: 查看帮助\n"
    printf "\tq|quit: 退出\n"
}

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
        node)
            node=`echo $data | cut -d " " -f 2`
            if [ $node != $op ]; then
                _topics node $node
                MODE=node
            else
                _usage
            fi
            ;;
        help)
            _usage
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
