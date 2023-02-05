Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_docker(){
    check_root
    curl -fsSL https://get.docker.com | bash -s docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "docker 安装完成"
}

install_ironfish(){
    read -p " 请输入节点名字（跟官方注册的一样）:" name
    echo "你输入的节点名字是 $name"
    read -r -p "请确认输入的节点名字正确，正确请输入Y，否则将退出 [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo "继续安装"
            ;;

        *)
            echo "退出安装..."
            exit 1
            ;;
    esac
    docker pull ghcr.io/iron-fish/ironfish:latest
    docker run -itd --name node --net host --volume /root/.node:/root/.ironfish ghcr.io/iron-fish/ironfish:latest start
    sleep 5
    docker exec -it node bash -c "ironfish config:set blockGraffiti ${name}"
    docker exec -it node bash -c "ironfish config:set enableTelemetry true"
    echo "启动成功！"
}

run_ironfish(){
    docker start $(docker ps -a | grep node | awk '{ print $1}')
    echo "启动成功！"
    echo "请使用检查状态功能确保正常运行"
    echo "假如没正常启动，请运行命令 'docker ps -a 显示的CONTAINER ID' "
    echo "再运行命令 'docker start 显示的CONTAINER ID' "
}

stop_ironfish(){
    docker exec -it node bash -c "ironfish stop"
    sleep 5
    echo "停止成功！"
}

mine_ironfish(){
    echo "开始挖矿,此功能只能挂机请务关闭或退出"
    echo "需要退出请使用键盘按键 ctrl+c"
    docker exec -itd node bash -c "ironfish miners:start"
}

send_ironfish(){
    echo "发送转账请在节点同步完后进行,否则会提示错误"
    echo "流程请参考https://ironfish.network/docs/onboarding/send-receive-iron-fish-transactions"
    docker exec -it node bash -c "ironfish wallet:send"
}

creat_ironfish(){
    echo "正在创建钱包"
    docker exec -it node bash -c "ironfish wallet:create"
    echo "新钱包创建成功，挖矿时请记得更改为你需要使用的钱包"
}

set_ironfish(){
    echo "正在导出所有的本地钱包名字↓"
    docker exec -it node bash -c "ironfish wallet:accounts"
    read -p " 请输入你想使用的钱包名字（如上）:" name
    docker exec -it node bash -c "ironfish wallet:use ${name}"
    echo "设置成功!挖矿和转账所使用的钱包已更改为 ${name}"
}

export_ironfish(){
    echo "正在导出所有的本地钱包名字↓"
    docker exec -it node bash -c "ironfish wallet:accounts"
    read -p " 请输入你想导出的钱包名字（如上）:" name
    docker exec -it node bash -c "ironfish wallet:export ${name}"
    echo "成功导出 ${name} 钱包,请备份"
}

import_ironfish(){
    echo "请输入导入的 钱包名字 和 spendingKey (这些信息在导出时提供)"
    docker exec -it node bash -c "ironfish wallet:import"
}

balance_ironfish(){
    echo "正在显示钱包余额,请确保节点已同步完成并领水...."
    docker exec -it node bash -c "ironfish wallet:balance"
}


read_ironfish(){
    echo "正在检查实时状态，如需退出请按 CTRL+C"
    docker exec -it node bash -c "ironfish status -f"
}

update_ironfish(){
    echo "开始升级，请耐心等待"
    echo "请注意,更新之后老版本钱包将会无法导入(导出格式不同，意味着领的水也会丢失得重新领取),然后要重新同步节点"
    sleep 5
    docker exec -it node bash -c "ironfish stop"
    docker rm $(docker ps -a | grep node | awk '{ print $1}')
    rm -rf .node/
    read -p " 请输入节点名字（跟官方注册的一样）:" name
    echo "你输入的节点名字是 $name"
    read -r -p "请确认输入的节点名字正确，正确请输入Y，否则将退出 [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo "继续更新"
            ;;

        *)
            echo "退出更新..."
            exit 1
            ;;
    esac
    docker pull ghcr.io/iron-fish/ironfish:latest
    docker run -itd --name node --net host --volume /root/.node:/root/.ironfish ghcr.io/iron-fish/ironfish:latest start
    sleep 5
    docker exec -it node bash -c "ironfish config:set blockGraffiti ${name}"
    docker exec -it node bash -c "ironfish config:set enableTelemetry true"
    echo "启动成功！升级完成"
}

faucet_ironfish(){
    echo "请在下方输入注册账号的邮箱,领水需要排队"
    echo "请过段时间和同步完节点的后再查询钱包余额"
    docker exec -it node bash -c "ironfish faucet"
}

mintAsset(){
    echo "正在铸造资产...."
    echo "Mint成功后就是链上资产，可以用于燃烧和转账到官方地址"
    echo "下方asset name和metadata必须跟账号名字一样"
    echo "mint amount比例是10000:0.00000001IRON,数值填写10000即可"
    docker exec -it node bash -c "ironfish wallet:mint"

}

burnAsset(){
    echo "正在燃烧资产...."
    docker exec -it node bash -c "ironfish wallet:burn"
}

transferAsset(){
    echo "正在转账资产到官方地址...."
    docker exec -it node bash -c "ironfish wallet:send --to dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca"
}

echo && echo -e " ${Red_font_prefix}IronFish 一键脚本${Font_color_suffix} by \033[1;35mLattice\033[0m
此脚本完全免费开源，由推特用户 ${Green_font_prefix}@L4ttIc3${Font_color_suffix} 二次开发并升级，
升级增加 ${Red_font_prefix}IronFish第三阶段测试网完整功能${Font_color_suffix} 功能
欢迎关注，如有收费请勿上当受骗。
 ———————————————————————
 ${Green_font_prefix} 1.安装 docker ${Font_color_suffix}
 ${Green_font_prefix} 2.安装并运行 Ironfish ${Font_color_suffix}
  -----节点功能------
 ${Green_font_prefix} 3.运行 Ironfish 节点 ${Font_color_suffix}
 ${Green_font_prefix} 4.停止 Ironfish 节点 ${Font_color_suffix}
  -----挖矿功能------
 ${Red_font_prefix}(功能5必须在节点运行下使用)${Font_color_suffix}
 ${Green_font_prefix} 5.开始 Ironfish 挖矿 ${Font_color_suffix}
  -----转账功能------
 ${Red_font_prefix}(功能6必须同步完节点后使用)${Font_color_suffix}
 ${Green_font_prefix} 6.发送 Ironfish 转账 ${Font_color_suffix}
  -----钱包功能------
 ${Green_font_prefix} 7.创建 Ironfish 钱包 ${Font_color_suffix}
 ${Green_font_prefix} 8.设置 Ironfish 钱包 ${Font_color_suffix}
 ${Green_font_prefix} 9.导出 Ironfish 钱包 ${Font_color_suffix}
 ${Green_font_prefix} 10.导入 Ironfish 钱包 ${Font_color_suffix}
 ${Green_font_prefix} 11.查询 Ironfish 钱包余额 ${Font_color_suffix}
  -----其他功能------                    
 ${Green_font_prefix} 12.检查 Ironfish 状态 ${Font_color_suffix}
 ${Green_font_prefix} 13.升级 Ironfish 版本 ${Font_color_suffix}
 ${Green_font_prefix} 14.请求 Ironfish 领水 ${Font_color_suffix}
  -----第三阶段测试网功能------ 
 ${Red_font_prefix}(以下必须在同步完节点和领水后使用)${Font_color_suffix}
 ${Green_font_prefix} 15.Mint An Asset 铸造资产${Font_color_suffix}
 ${Green_font_prefix} 16.Burn An Asset 燃烧资产${Font_color_suffix}
 ${Green_font_prefix} 17.Send An Asset 转账资产到官方地址${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1-17]:" num
case "$num" in
1)
    install_docker
    ;;
2)
    install_ironfish
    ;;
3)
    run_ironfish
    ;;
4)
    stop_ironfish
    ;;
5)
    mine_ironfish
    ;;
6)
    send_ironfish
    ;;
7)
    creat_ironfish
    ;;
8)
    set_ironfish
    ;;
9)
    export_ironfish
    ;;
10)
    import_ironfish
    ;;
11)
    balance_ironfish
    ;;
12)
    read_ironfish
    ;;
13)
    update_ironfish
    ;;
14)
    faucet_ironfish
    ;;
15)
    mintAsset
    ;;
16)
    burnAsset
    ;;
17)
    transferAsset
    ;;

*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
