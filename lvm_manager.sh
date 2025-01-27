#!/bin/bash

# 配置变量
VG_NAME="ubuntu-vg"
LV_NAME="root"
MOUNT_POINT="/"
FILESYSTEM="ext4"
ISO_FILE=""
ISO_URL=""
PRESEED_FILE="/tmp/preseed.cfg"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 错误处理函数
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 日志函数
log_message() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 绘制菜单函数
draw_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│          LVM 系统管理工具 v1.0          │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} 扩展现有 LVM 存储空间                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} 重新安装系统（使用 LVM）            ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} 显示当前系统信息                    ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}4.${NC} 查看帮助信息                        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}5.${NC} 退出程序                            ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────┘${NC}"
    echo
    echo -e "${YELLOW}系统信息：${NC}"
    echo -e "  主机名: $(hostname)"
    echo -e "  系统版本: $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)"
    echo -e "  内核版本: $(uname -r)"
    echo
}

# 帮助信息函数
show_help() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│               帮助信息                   │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}1. 扩展现有 LVM：${NC}                        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 将新硬盘添加到现有 LVM 系统        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 自动扩展根分区大小                 ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                          ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}2. 重新安装系统：${NC}                        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 支持多个 Linux 发行版              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 自动配置 LVM                        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 生成自动安装 ISO                    ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                          ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}3. 系统信息：${NC}                            ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 显示磁盘使用情况                    ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}   - 显示 LVM 配置信息                   ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────┘${NC}"
    echo
    read -n 1 -s -r -p "按任意键返回主菜单..."
}
# 系统选择函数
select_os_version() {
    echo "请选择要安装的系统版本："
    echo "Ubuntu 系列："
    echo "  1. Ubuntu 22.04.3 LTS Server (推荐)"
    echo "  2. Ubuntu 20.04.6 LTS Server"
    echo "  3. Ubuntu 24.04 LTS Server"
    echo "Debian 系列："
    echo "  4. Debian 12.5"
    echo "  5. Debian 11.8"
    echo "Rocky Linux 系列："
    echo "  6. Rocky Linux 9.3 Minimal"
    echo "  7. Rocky Linux 8.9 Minimal"
    echo
    read -p "请选择版本 [1-7]: " os_choice

    case $os_choice in
        1)
            ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
            ISO_FILE="ubuntu-22.04.3-live-server-amd64.iso"
            OS_TYPE="ubuntu"
            ;;
        2)
            ISO_URL="https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso"
            ISO_FILE="ubuntu-20.04.6-live-server-amd64.iso"
            OS_TYPE="ubuntu"
            ;;
        3)
            ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
            ISO_FILE="ubuntu-24.04-live-server-amd64.iso"
            OS_TYPE="ubuntu"
            ;;
        4)
            ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
            ISO_FILE="debian-12.5.0-amd64-netinst.iso"
            OS_TYPE="debian"
            ;;
        5)
            ISO_URL="https://cdimage.debian.org/cdimage/archive/11.8.0/amd64/iso-cd/debian-11.8.0-amd64-netinst.iso"
            ISO_FILE="debian-11.8.0-amd64-netinst.iso"
            OS_TYPE="debian"
            ;;
        6)
            ISO_URL="https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.3-x86_64-minimal.iso"
            ISO_FILE="Rocky-9.3-x86_64-minimal.iso"
            OS_TYPE="rocky"
            ;;
        7)
            ISO_URL="https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.9-x86_64-minimal.iso"
            ISO_FILE="Rocky-8.9-x86_64-minimal.iso"
            OS_TYPE="rocky"
            ;;
        *)
            error_exit "无效的选择"
            ;;
    esac

    echo "已选择: $ISO_FILE"
    echo "下载地址: $ISO_URL"
}

# 创建 Preseed 配置
create_preseed() {
    log_message "创建 Preseed 配置文件"
    cat > "$PRESEED_FILE" << 'EOF'
# 基本设置
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# 网络设置
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ubuntu-server
d-i netcfg/get_domain string local

# 用户设置（请修改密码）
d-i passwd/user-fullname string Administrator
d-i passwd/username string admin
d-i passwd/user-password password your_password_here
d-i passwd/user-password-again password your_password_here
d-i user-setup/allow-password-weak boolean true

# 时区设置
d-i time/zone string Asia/Shanghai
d-i clock-setup/utc boolean true

# 分区设置 (LVM)
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto-lvm/guided_size string max

# LVM 分区方案
d-i partman-auto/expert_recipe string \
      boot-root ::                    \
              1000 1000 1000 ext4     \
                      $primary{ }      \
                      $bootable{ }     \
                      method{ format } \
                      format{ }        \
                      use_filesystem{ }\
                      filesystem{ ext4 }\
                      mountpoint{ /boot }\
              .                        \
              500 10000 -1 ext4       \
                      $defaultignore{ }\
                      $primary{ }      \
                      method{ lvm }    \
                      vg_name{ ubuntu-vg }\
              .                        \
              LVM::                    \
              4096 4096 4096 linux-swap\
                      $lvmok{ }        \
                      method{ swap }   \
                      format{ }        \
              .                        \
              10000 20000 -1 ext4     \
                      $lvmok{ }        \
                      method{ format } \
                      format{ }        \
                      use_filesystem{ }\
                      filesystem{ ext4 }\
                      mountpoint{ / }  \
              .

# 软件包选择
tasksel tasksel/first multiselect standard, openssh-server
d-i pkgsel/include string vim curl wget lvm2

# 安装 GRUB
d-i grub-installer/bootdev string /dev/sda

# 完成安装
d-i finish-install/reboot_in_progress note
EOF
}
# 创建 Kickstart 配置（用于 Rocky Linux）
create_kickstart() {
    log_message "创建 Kickstart 配置文件"
    cat > "/tmp/ks.cfg" << 'EOF'
# 系统语言
lang en_US.UTF-8

# 键盘类型
keyboard us

# 时区
timezone Asia/Shanghai

# 网络设置
network --bootproto=dhcp

# 认证设置
auth --enableshadow --passalgo=sha512

# 安装方式
install
text
reboot

# 防火墙
firewall --enabled

# SELinux
selinux --enforcing

# 磁盘分区
clearpart --all --initlabel
part /boot --fstype=xfs --size=1024
part pv.01 --size=1 --grow
volgroup vg_root pv.01
logvol / --vgname=vg_root --size=1 --grow --name=lv_root
logvol swap --vgname=vg_root --name=lv_swap --size=4096

# Root 密码（请修改）
rootpw --iscrypted $6$random_salt$random_password

# 创建用户（请修改）
user --name=admin --password=$6$random_salt$random_password --gecos="Administrator"

# 软件包选择
%packages
@^minimal-environment
@core
vim
wget
curl
%end

# 安装后脚本
%post
#!/bin/bash
# 添加需要的其他配置
%end
EOF
}

# 检查系统是否使用 LVM
check_system_lvm() {
    if pvs | grep -q "/dev/sda"; then
        log_message "系统已使用 LVM"
        return 0
    else
        log_message "系统未使用 LVM"
        return 1
    fi
}

# 扩展现有 LVM
extend_existing_lvm() {
    local vg_name=$1
    local lv_path=$2
    
    log_message "开始扩展 LVM"
    
    # 检查新磁盘
    if ! lsblk /dev/sdb >/dev/null 2>&1; then
        error_exit "未找到 /dev/sdb 设备"
    fi
    
    # 检查磁盘是否已被使用
    if pvs | grep -q "/dev/sdb"; then
        error_exit "设备 /dev/sdb 已被用作物理卷"
    fi
    
    # 创建物理卷
    log_message "创建物理卷 /dev/sdb"
    pvcreate /dev/sdb || error_exit "创建物理卷失败"
    
    # 扩展卷组
    log_message "扩展卷组 $vg_name"
    vgextend $vg_name /dev/sdb || error_exit "扩展卷组失败"
    
    # 扩展逻辑卷
    log_message "扩展逻辑卷 $lv_path"
    lvextend -l +100%FREE $lv_path || error_exit "扩展逻辑卷失败"
    
    # 调整文件系统大小
    log_message "调整文件系统大小"
    if file -L $lv_path | grep -q "ext[234]"; then
        resize2fs $lv_path || error_exit "调整文件系统大小失败"
    elif file -L $lv_path | grep -q "XFS"; then
        xfs_growfs $lv_path || error_exit "调整文件系统大小失败"
    else
        error_exit "不支持的文件系统类型"
    fi
}

# 准备自动安装介质
prepare_auto_install() {
    log_message "准备自动安装环境"
    
    # 选择系统版本
    select_os_version
    
    # 安装必要工具
    apt-get update
    apt-get install -y genisoimage wget || error_exit "安装工具失败"

    # 下载 ISO
    if [ ! -f "$ISO_FILE" ]; then
        log_message "下载 ISO..."
        wget "$ISO_URL" || error_exit "ISO 下载失败"
    fi

    # 创建工作目录
    mkdir -p iso_temp iso_new

    # 挂载 ISO
    mount -o loop "$ISO_FILE" iso_temp || error_exit "ISO 挂载失败"

    # 复制 ISO 内容
    cp -rT iso_temp iso_new || error_exit "ISO 复制失败"

    # 创建配置文件并修改引导
    case $OS_TYPE in
        "ubuntu"|"debian")
            create_preseed
            cp "$PRESEED_FILE" iso_new/preseed/
            modify_ubuntu_boot
            ;;
        "rocky")
            create_kickstart
            cp "/tmp/ks.cfg" iso_new/
            modify_rocky_boot
            ;;
    esac

    # 创建新 ISO
    log_message "创建新 ISO"
    genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -o auto-install.iso iso_new || error_exit "ISO 创建失败"

    # 清理
    umount iso_temp
    rm -rf iso_temp iso_new

    log_message "自动安装 ISO 已创建: auto-install.iso"
}
# 修改 Ubuntu/Debian 引导配置
modify_ubuntu_boot() {
    cat > iso_new/isolinux/txt.cfg << EOF
default install
label install
  menu label ^Install
  kernel /install/vmlinuz
  append  file=/cdrom/preseed/preseed.cfg vga=788 initrd=/install/initrd.gz quiet ---
EOF
}

# 修改 Rocky Linux 引导配置
modify_rocky_boot() {
    sed -i 's/^  append.*/  append initrd=initrd.img inst.ks=cdrom:\/ks.cfg/' iso_new/isolinux/isolinux.cfg
}

# 显示系统信息
show_system_info() {
    log_message "系统信息："
    echo "磁盘使用情况："
    df -h
    echo -e "\nLVM 信息："
    echo "物理卷："
    pvs
    echo "卷组："
    vgs
    echo "逻辑卷："
    lvs
}

# 显示菜单
show_menu() {
    while true; do
        draw_menu
        read -p "请选择操作 [1-5]: " choice
        case $choice in
            1)
                if check_system_lvm; then
                    vg_name=$(vgs --noheadings -o vg_name | tr -d ' ' | head -n1)
                    lv_path=$(lvs --noheadings -o lv_path | tr -d ' ' | head -n1)
                    extend_existing_lvm "$vg_name" "$lv_path"
                    read -n 1 -s -r -p "按任意键继续..."
                else
                    echo -e "${RED}错误：系统未使用 LVM${NC}"
                    read -n 1 -s -r -p "按任意键继续..."
                fi
                ;;
            2)
                echo -e "${YELLOW}警告：此操作将删除所有数据！${NC}"
                read -p "是否继续？(y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    prepare_auto_install
                    read -n 1 -s -r -p "按任意键继续..."
                fi
                ;;
            3)
                clear
                show_system_info
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            4)
                show_help
                ;;
            5)
                echo -e "${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重试${NC}"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
        esac
    done
}

# 主函数
main() {
    # 检查 root 权限
    if [ "$EUID" -ne 0 ]; then
        error_exit "请使用 root 用户或 sudo 运行此脚本"
    fi

    # 直接调用 show_menu
    show_menu
}

# 执行主函数
main "$@"
