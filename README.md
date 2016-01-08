## shell版v2ex客户端

### Install:

使用依赖需安装jq用于命令行解析json：

OS X: 

```
brew install jq

```

Ubuntu:

```
sudo apt-get install jq
```

其他平台按照可参见 [jq官方文档](https://stedolan.github.io/jq/download/)

### Usage:

```
➜  v2ex-shell-client git:(master) ✗ ./v2ex.sh
NONE # help
Usage:
        hot: 热门主题
        latest: 最新主题
        node <nodename>: 获取节点的主题
        <num>: 获取指定主题的回复列表
        help: 查看帮助
        q|quit: 退出
```

![image](https://raw.githubusercontent.com/six-ddc/v2ex-shell-client/master/capture.png)


### TODO：

* 翻页支持
* 登录支持
* 回复功能
* 常用节点选择
* 排版优化
