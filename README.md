## shell版v2ex客户端

### Install:

基本使用依赖需安装jq用于命令行解析json，另外签到功能还需额外安装httpie：

OS X: 

```
brew install jq
brew install httpie
```

Ubuntu:

```
sudo apt-get install jq
sudo apt-get install httpie
```

其他平台按照可参见 [jq官方文档](https://stedolan.github.io/jq/download/)，[httpie官方文档](https://github.com/jkbrzt/httpie)

### Usage:

```
➜  v2ex-shell-client git:(master) ✗ ./v2ex.sh
NONE # help
---------------------------------------------------------------------------------------------------------------
    hot             | 热门主题
    late            | 最新主题
    login/relogin   | 登录/重新登录
    daily           | 领取每日签到奖励
    cate <catename> | 获取指定分类的主题<tech|creative|play|apple|jobs|deals|city|qna|hot|all|r2|nodes|members>
    node <nodename> | 获取节点的主题
    <num>           | 查看指定主题序号的所有回复
    open <num>      | 使用默认浏览器查看指定主题贴
    help            | 查看帮助
    q|quit          | 退出
---------------------------------------------------------------------------------------------------------------
```

![image](https://raw.githubusercontent.com/six-ddc/v2ex-shell-client/master/capture/a.png)

主题的回复内容将单独显示，而不影响主题列表

![image](https://raw.githubusercontent.com/six-ddc/v2ex-shell-client/master/capture/b.png)
![image](https://raw.githubusercontent.com/six-ddc/v2ex-shell-client/master/capture/c.png)

### TODO：

* 翻页支持
* ~~登录支持~~
* 回复功能
* 常用节点选择
* 排版优化
