#!/bin/bash

# 定義顏色輸出
red() { echo -e "\033[31m\033[01m[WARNING] $1\033[0m"; }
green() { echo -e "\033[32m\033[01m[INFO] $1\033[0m"; }
greenline() { echo -e "\033[32m\033[01m $1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m[NOTICE] $1\033[0m"; }
blue() { echo -e "\033[34m\033[01m[MESSAGE] $1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m[NOTICE] $1\033[0m"; }
highlight() { echo -e "\033[32m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }

# 檢查是否使用root執行
if [ "$(id -u)" -ne 0 ]; then
    echo "此腳本需要以 root 用戶權限運行，請輸入當前用戶的密碼："
    green "注意！輸入密碼過程不顯示*號屬於正常現象"
    sudo bash "$(realpath "$0")" "$@"
    exit $?
fi

## 加速GitHub資源下載的代理服務
proxy=""
# if [ $# -gt 0 ]; then
#     proxy="https://mirror.ghproxy.com/"
# fi

declare -a menu_options
declare -A commands
menu_options=(
    "更新系统软件包"
    "更新脚本"
    "安装 Docker"
    "安装 Docker Compose"
    "安装常用套件"
    "安装 SSH"
    "安装 Miniconda"
    "安装 NVIDIA 驅動 545"
    "安装 CUDA 12.3.2"
    "安装1panel面板管理工具"
    "查看1panel用户信息"
)

commands=(
    ["更新系统软件包"]="update_system_packages"
    ["更新脚本"]="update_scripts"
    ["安装 Docker"]="install_docker"
    ["安装 Docker Compose"]="install_docker_compose"
    ["安装常用套件"]="install_common_packages"
    ["安装 SSH"]="install_ssh"
    ["安装 Miniconda"]="install_miniconda"
    ["安装 NVIDIA 驅動 545"]="install_nvidia_driver"
    ["安装 CUDA 12.3.2"]="install_cuda"
    ["安装1panel面板管理工具"]="install_1panel_on_linux"
    ["查看1panel用户信息"]="read_user_info"
)

# 更新系統軟件包
update_system_packages() {
    green "Setting timezone Asia/Taipei..."
    sudo timedatectl set-timezone Asia/Taipei
    # 更新系統軟件包
    green "Updating system packages..."
    sudo apt update
    # 執行過程中不會提示用戶進行任何輸入
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
}

# 更新自己
update_scripts(){
    wget -O setting.sh ${proxy}https://raw.githubusercontent.com/YungRui0402/Shell/main/setting.sh && chmod +x setting.sh
	echo "腳本已更新並保存在當前目錄 setting.sh,現在將執行新腳本。"
	./setting.sh ${proxy}
	exit 0
}

# 安裝 Docker
install_docker() {
    green "安裝 Docker..."
    
    # 如果 ~/Downloads 不存在，則創建該目錄
    if [ ! -d ~/Downloads ]; then
        mkdir ~/Downloads
    fi
    cd ~/Downloads/
    
    # 安裝 Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER

    green "Docker 安裝完成,記得reboot"
}

# 安裝 Docker Compose
install_docker_compose() {
    green "安裝 Docker Compose..."
    
    # 安裝 Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo usermod -aG docker $USER
    sudo chgrp docker /usr/local/bin/docker-compose
    sudo chmod 750 /usr/local/bin/docker-compose

    green "Docker Compose 安裝完成,記得reboot"
}

# 安裝常用套件
install_common_packages() {
    green "安裝常用套件..."
    
    sudo apt install -y net-tools
    sudo apt install -y htop
    sudo apt install -y curl

    green "常用套件安裝完成"
}

# 安裝 SSH
install_ssh() {
    green "安裝 SSH..."
    
    sudo apt-get install -y openssh-server
    sudo nano /etc/ssh/sshd_config
    sudo /etc/init.d/ssh restart
    systemctl status ssh

    green "SSH 安裝完成"
}

# 安装 Miniconda
install_miniconda() {
    green "安装 Miniconda..."
    
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh"
    elif [ "$ARCH" == "aarch64" ]; then
        CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-aarch64.sh"
    else
        red "不支持的系统架构: $ARCH"
        exit 1
    fi

    
    USER_HOME=$(eval echo ~${SUDO_USER})

    if [ ! -d "$USER_HOME/Downloads" ]; then
        sudo -u $SUDO_USER mkdir "$USER_HOME/Downloads"
    fi
    cd "$USER_HOME/Downloads"
    
    sudo -u $SUDO_USER wget $CONDA_URL -O miniconda.sh
    sudo -u $SUDO_USER bash miniconda.sh -b -p "$USER_HOME/miniconda"
    sudo -u $SUDO_USER bash -c "echo 'export PATH=\"$USER_HOME/miniconda/bin:\$PATH\"' >> \"$USER_HOME/.bashrc\""

    green "Miniconda 安装完成"
}

# 安装 NVIDIA 驅動 545
install_nvidia_driver() {
    green "安装 NVIDIA 驅動 545..."
    
    sudo lshw -numeric -C display
    sudo apt-get purge -y nvidia*
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt-get update
    sudo apt-get upgrade -y
    ubuntu-drivers list
    sudo apt-get install -y nvidia-driver-545
    sudo reboot

    green "NVIDIA 驅動 545 安装完成"
}

# 安装 CUDA 12.3.2
install_cuda() {
    green "安装 CUDA 12.3.2..."
    
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/12.3.2/local_installers/cuda-repo-ubuntu2204-12-3-local_12.3.2-545.23.08-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2204-12-3-local_12.3.2-545.23.08-1_amd64.deb
    sudo cp /var/cuda-repo-ubuntu2204-12-3-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-3

    # 添加环境变量到 .bashrc
    sudo -u $SUDO_USER bash -c "echo 'export PATH=/usr/local/cuda/bin:\$PATH' >> $HOME/.bashrc"
    sudo -u $SUDO_USER bash -c "echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH' >> $HOME/.bashrc"
    source "$HOME/.bashrc"

    green "CUDA 12.3.2 安装完成"
}

install_1panel_on_linux() {
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
    intro="https://1panel.cn/docs/installation/cli/"
    if command -v 1pctl &>/dev/null; then
        green "如何卸载1panel 请参考：$intro"
    else
        red "未安装1panel"
    fi

}

# 查看1panel用户信息
read_user_info() {
    sudo 1pctl user-info
}

#安装alist
install_alist() {
    local host_ip
    host_ip=$(hostname -I | awk '{print $1}')
    green "正在安装alist 请稍后"
    docker run -d --restart=unless-stopped -v /etc/alist:/opt/alist/data -p 5244:5244 -e PUID=0 -e PGID=0 -e UMASK=022 --name="alist" xhofe/alist:latest
    sleep 3
    docker exec -it alist ./alist admin set admin
    echo '
    AList已安装,已帮你设置好用户名和密码,若修改请在web面板修改即可。
    用户: admin 
    密码: admin
    '
    green 浏览器访问:http://${host_ip}:5244
}


show_menu() {
    clear
    greenline "————————————————————————————————————————————————————"
    echo '
    ***********  DIY docker輕服務器  ***************
    環境:Ubuntu/debian (pi4 b+)
    腳本作用:快速部署環境 --- Made by Yong-Rui'
    echo -e "    https://github.com/YungRui0402"
    greenline "————————————————————————————————————————————————————"
    echo "請選擇操作："

    # 特殊處理的項數組
    special_items=("")
    for i in "${!menu_options[@]}"; do
        if [[ " ${special_items[*]} " =~ " ${menu_options[i]} " ]]; then
            # 如果當前項在特殊處理項數組中，使用特殊顏色
            highlight "$((i + 1)). ${menu_options[i]}"
        else
            # 否則，使用普通格式
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}

handle_choice() {
    local choice=$1
    # 檢查輸入是否為空
    if [[ -z $choice ]]; then
        echo -e "${RED}輸入不能為空，請重新選擇。${NC}"
        return
    fi

    # 檢查輸入是否為數字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}請輸入有效數字!${NC}"
        return
    fi

    # 檢查數字是否在有效範圍內
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}選項超出範圍!${NC}"
        echo -e "${YELLOW}請輸入 1 到 ${#menu_options[@]} 之間的數字。${NC}"
        return
    fi

    # 執行命令
    if [ -z "${commands[${menu_options[$choice - 1]}]}" ]; then
        echo -e "${RED}無效選項，請重新選擇。${NC}"
        return
    fi

    "${commands[${menu_options[$choice - 1]}]}"
}


while true; do
    show_menu
    read -p "請輸入選項的序號(輸入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意鍵繼續..."
    read -n 1 # 等待用戶按鍵
done
