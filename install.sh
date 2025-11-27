#!/bin/bash
#
# UFW Blocklist Enhanced Edition - One-Click Installer
# Supports threat intelligence and geographic IP blocking
# Supports Ubuntu and Debian systems

set -e

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Version information
VERSION="2.0.0"
INSTALL_DATE=$(date +'%Y-%m-%d')

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/etc/default/ufw-blocklist"
UFW_DIR="/etc/ufw"
CRON_DIR="/etc/cron.daily"
MODULE_DIR="/etc/ufw/modules"

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to print step header
print_step() {
    local step_num="$1"
    local step_desc="$2"
    print_status "$PURPLE" "
┌─ Step $step_num: $step_desc"
}

# Function to print step completion
print_complete() {
    print_status "$GREEN" "✓ Complete"
}

# Function to print step warning
print_warning() {
    print_status "$YELLOW" "⚠ Warning: $1"
}

# Function to print step error
print_error() {
    print_status "$RED" "✗ Error: $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status "$RED" "Error: This installer must be run as root"
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_step "1" "检查系统要求"

    # Check OS version (Ubuntu/Debian)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            print_error "此安装程序需要 Ubuntu 或 Debian 操作系统"
            exit 1
        fi
        print_status "$BLUE" "  操作系统: $PRETTY_NAME"

        # Set OS-specific information
        case "$ID" in
            ubuntu)
                OS_FAMILY="ubuntu"
                ;;
            debian)
                OS_FAMILY="debian"
                ;;
        esac
    else
        print_error "无法确定操作系统版本"
        exit 1
    fi

    # Check UFW
    if ! command -v ufw >/dev/null 2>&1; then
        print_error "UFW 未安装。请使用: apt install ufw 安装"
        exit 1
    fi
    print_status "$BLUE" "  UFW: $(ufw --version | head -1)"

    # Check ipset
    if ! command -v ipset >/dev/null 2>&1; then
        print_error "ipset 未安装。请使用: apt install ipset 安装"
        exit 1
    fi
    print_status "$BLUE" "  ipset: $(ipset --version | head -1)"

    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl 未安装。请使用: apt install curl 安装"
        exit 1
    fi
    print_status "$BLUE" "  curl: $(curl --version | head -1)"

    print_complete
    echo
}

# Function to backup existing configuration
backup_existing() {
    print_step "2" "Backing Up Existing Configuration"

    local backup_dir="/etc/ufw-backup-$(date +'%Y%m%d-%H%M%S')"
    mkdir -p "$backup_dir"

    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$backup_dir/ufw-blocklist.conf.backup"
        print_status "$BLUE" "  Backed up: $CONFIG_FILE"
    fi

    if [ -f "$UFW_DIR/after.init" ]; then
        cp "$UFW_DIR/after.init" "$backup_dir/after.init.backup"
        print_status "$BLUE" "  Backed up: $UFW_DIR/after.init"
    fi

    if [ -f "$CRON_DIR/ufw-blocklist" ]; then
        cp "$CRON_DIR/ufw-blocklist" "$backup_dir/ufw-blocklist.backup"
        print_status "$BLUE" "  Backed up: $CRON_DIR/ufw-blocklist"
    fi

    print_status "$GREEN" "  Backup location: $backup_dir"
    print_complete
    echo
}

# Function to install configuration
install_configuration() {
    print_step "3" "配置安装选项"

    # Show installation menu to get user preferences
    show_installation_menu

    # Save configuration
    save_config
    print_status "$GREEN" "  ✓ 配置已保存到 $CONFIG_FILE"

    print_complete
    echo
}

# Function to install scripts
install_scripts() {
    print_step "4" "安装脚本文件"

    # Install after.init script
    print_status "$BLUE" "  安装 UFW 集成脚本..."
    cp "$SCRIPT_DIR/after.init" "$UFW_DIR/after.init"
    chmod 750 "$UFW_DIR/after.init"
    print_status "$GREEN" "    ✓ after.init → $UFW_DIR/after.init"

    # Install cron script
    print_status "$BLUE" "  安装更新脚本..."
    cp "$SCRIPT_DIR/ufw-blocklist-ipsum" "$CRON_DIR/ufw-blocklist-ipsum"
    chmod 750 "$CRON_DIR/ufw-blocklist-ipsum"
    print_status "$GREEN" "    ✓ ufw-blocklist-ipsum → $CRON_DIR/ufw-blocklist-ipsum"

    # Create module directory
    if [ ! -d "$MODULE_DIR" ]; then
        mkdir -p "$MODULE_DIR"
        print_status "$GREEN" "    ✓ 已创建模块目录: $MODULE_DIR"
    fi

    print_complete
    echo
}

# Function to download initial data
download_initial_data() {
    print_step "5" "下载初始 IP 列表数据"

    . "$CONFIG_FILE"

    # Download threat intelligence
    if [ "$ENABLE_THREAT_BLOCKING" = "yes" ]; then
        print_status "$BLUE" "  下载威胁情报列表..."
        if curl -sS -f --compressed "$THREAT_URL" -o "/etc/ipsum.3.txt"; then
            local threat_count=$(wc -l < /etc/ipsum.3.txt)
            print_status "$GREEN" "    ✓ 已下载 $threat_count 个威胁 IP"
        else
            print_error "从 $THREAT_URL 下载威胁情报失败"
            exit 1
        fi
        chmod 640 "/etc/ipsum.3.txt"
    else
        print_status "$YELLOW" "  ○ 威胁情报下载已禁用"
    fi

    # Download geographic data
    if [ "$ENABLE_GEO_BLOCKING" = "yes" ]; then
        print_status "$BLUE" "  下载地理位置 IP 列表..."
        if curl -sS -f "$GEO_URL" -o "/etc/cn.zone"; then
            local geo_count=$(wc -l < /etc/cn.zone)
            print_status "$GREEN" "    ✓ 已下载 $geo_count 个地理位置 IP 段"
        else
            print_error "从 $GEO_URL 下载地理位置数据失败"
            exit 1
        fi
        chmod 640 "/etc/cn.zone"
    else
        print_status "$YELLOW" "  ○ 地理位置 IP 下载已禁用"
    fi

    print_complete
    echo
}

# Function to configure UFW
configure_uw() {
    print_step "6" "Configuring UFW"

    # Check if UFW is active
    if ufw status | grep -q "Status: active"; then
        print_warning "UFW is currently active"
        print_status "$YELLOW" "  This may cause temporary service interruption"

        print_status "$BLUE" "  Continue? (y/N): "
        local proceed
        read -r proceed
        if [[ ! "$proceed" =~ ^[Yy] ]]; then
            print_status "$YELLOW" "Installation cancelled by user"
            exit 0
        fi

        # Create a simple timestamped backup directory
        local backup_dir="/etc/ufw-backup-$(date +'%Y%m%d-%H%M%S')"
        mkdir -p "$backup_dir"

        # Backup current UFW rules and user.rules
        if [ -f "/etc/ufw/user.rules" ]; then
            cp "/etc/ufw/user.rules" "$backup_dir/"
            print_status "$GREEN" "    ✓ Current UFW user rules backed up to $backup_dir"
        fi

        if [ -f "/etc/ufw/after.init" ]; then
            cp "/etc/ufw/after.init" "$backup_dir/"
            print_status "$GREEN" "    ✓ Current after.init backed up to $backup_dir"
        fi

        print_status "$BLUE" "  Note: To restore original rules, run:"
        print_status "$BLUE" "    sudo cp $backup_dir/* /etc/ufw/ && sudo ufw reload"
    else
        print_status "$BLUE" "  UFW is not active - safe to proceed"
    fi

    print_status "$BLUE" "  Applying UFW integration..."
    print_status "$GREEN" "    ✓ UFW integration script installed"

    print_complete
    echo
}

# Function to show configuration menu
show_config_menu() {
    while true; do
        clear
        echo ""
        echo "==================== UFW 防火墙阻止列表配置 ===================="
        echo ""
        echo "当前配置："
        echo "  1. 威胁情报阻止: $ENABLE_THREAT_BLOCKING"
        echo "  2. 地理位置阻止: $ENABLE_GEO_BLOCKING"
        echo ""
        echo "操作选项："
        echo "  1) 切换威胁情报阻止状态"
        echo "  2) 切换地理位置阻止状态"
        echo "  s) 保存配置并返回"
        echo "  q) 不保存直接返回"
        echo ""
        read -p "请选择操作 [1-2/s/q]: " choice

        case "$choice" in
            1)
                if [ "$ENABLE_THREAT_BLOCKING" = "yes" ]; then
                    ENABLE_THREAT_BLOCKING="no"
                    echo "已禁用威胁情报阻止"
                else
                    ENABLE_THREAT_BLOCKING="yes"
                    echo "已启用威胁情报阻止"
                fi
                sleep 1
                ;;
            2)
                if [ "$ENABLE_GEO_BLOCKING" = "yes" ]; then
                    ENABLE_GEO_BLOCKING="no"
                    echo "已禁用地理位置阻止"
                else
                    ENABLE_GEO_BLOCKING="yes"
                    echo "已启用地理位置阻止"
                fi
                sleep 1
                ;;
            s|S)
                save_config
                echo "配置已保存到 $CONFIG_FILE"
                sleep 2
                break
                ;;
            q|Q)
                echo "退出配置菜单（未保存更改）"
                sleep 1
                break
                ;;
            *)
                echo "无效选择，请重试"
                sleep 1
                ;;
        esac
    done
}

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# UFW Blocklist Configuration
# Generated on $(date)
# Compatible with Ubuntu and Debian systems

# IP Set Names
THREAT_IPSET="ufw-blocklist-threat"
GEO_IPSET="ufw-blocklist-cn"

# Enable/Disable Features
ENABLE_THREAT_BLOCKING="$ENABLE_THREAT_BLOCKING"
ENABLE_GEO_BLOCKING="$ENABLE_GEO_BLOCKING"

# Data Sources
THREAT_SEEDLIST="/etc/ipsum.3.txt"
GEO_SEEDLIST="/etc/cn.zone"
THREAT_URL="$THREAT_URL"
GEO_URL="$GEO_URL"

# Logging
LOG_LEVEL="3"
LOG_PREFIX="[UFW BLOCKLIST]"
EOF
    chmod 640 "$CONFIG_FILE"
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        # Default values
        ENABLE_THREAT_BLOCKING="yes"
        ENABLE_GEO_BLOCKING="no"
        THREAT_URL="https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt"
        GEO_URL="http://www.ipdeny.com/ipblocks/data/countries/cn.zone"
    fi
}

# Function to show installation menu
show_installation_menu() {
    echo ""
    echo "==================== 安装配置向导 ===================="
    echo ""

    # Ask about threat blocking
    while true; do
        read -p "是否启用威胁情报IP阻止？[Y/n]: " choice
        case "$choice" in
            ""|y|Y)
                ENABLE_THREAT_BLOCKING="yes"
                echo "✓ 将启用威胁情报阻止"
                break
                ;;
            n|N)
                ENABLE_THREAT_BLOCKING="no"
                echo "○ 将禁用威胁情报阻止"
                break
                ;;
            *)
                echo "请输入 Y 或 N"
                ;;
        esac
    done

    # Ask about geo blocking
    while true; do
        read -p "是否启用地理位置IP阻止（中国）？[y/N]: " choice
        case "$choice" in
            ""|n|N)
                ENABLE_GEO_BLOCKING="no"
                echo "○ 将禁用地理位置阻止"
                break
                ;;
            y|Y)
                ENABLE_GEO_BLOCKING="yes"
                echo "✓ 将启用地理位置阻止"
                break
                ;;
            *)
                echo "请输入 Y 或 N"
                ;;
        esac
    done

    # Set default URLs
    THREAT_URL="https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt"
    GEO_URL="http://www.ipdeny.com/ipblocks/data/countries/cn.zone"

    echo ""
    echo "配置完成！"
    echo ""
}

# Function to show final summary
show_summary() {
    . "$CONFIG_FILE"

    print_status "$PURPLE" "
╔════════════════════════════════════════════════════════════════╗
║                    安装完成！                                    ║
║                                                                ║
║  UFW Blocklist v$VERSION 已成功安装。                            ║
║                                                                ║
║  配置摘要：                                                      ║"
    print_status "$BLUE" "║  威胁情报阻止: $([ "$ENABLE_THREAT_BLOCKING" = "yes" ] && echo "已启用" || echo "已禁用")"
    print_status "$BLUE" "║  地理位置阻止: $([ "$ENABLE_GEO_BLOCKING" = "yes" ] && echo "已启用" || echo "已禁用")"
    print_status "$BLUE" "║                                                                ║
║  下一步操作：                                                    ║
║  1. 启用防火墙: sudo ufw enable                                  ║
║  2. 检查状态: sudo ufw status                                    ║
║  3. 重新配置: sudo $0 --config                                   ║
╚════════════════════════════════════════════════════════════════╝"

    print_status "$GREEN" "
🎉 安装成功！您的防火墙现已配备高级 IP 阻止功能。"
}

# Function to show main menu
show_main_menu() {
    while true; do
        clear
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║              UFW Blocklist 管理程序 v$VERSION                    ║"
        echo "║              兼容 Ubuntu 和 Debian 系统                        ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "请选择操作："
        echo ""
        echo "  1) 安装"
        echo "  2) 配置管理"
        echo "  3) 退出"
        echo ""
        read -p "请输入选项 [1-3]: " choice

        case "$choice" in
            1)
                clear
                print_status "$GREEN" "
╔══════════════════════════════════════════════════════════════╗
║              UFW Blocklist 安装程序 v$VERSION                    ║
║                      开始安装...                               ║
╚════════════════════════════════════════════════════════════╝"
                echo ""
                check_requirements
                backup_existing
                install_configuration
                install_scripts
                download_initial_data
                configure_uw
                show_summary
                echo ""
                read -p "按回车键返回主菜单..."
                ;;
            2)
                clear
                load_config
                show_config_menu
                ;;
            3)
                clear
                echo ""
                echo "再见！"
                exit 0
                ;;
            *)
                print_error "无效选项，请输入 1-3"
                sleep 1
                ;;
        esac
    done
}

# Main execution
check_root
show_main_menu