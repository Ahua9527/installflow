#!/bin/bash

# ==============================================================================
# 叮当装 InstallFlow - Mac 批量安装工具
# 一键批量安装 Mac 应用，让装机像叮当一样简单
# 
# 使用方法：
# 1. 推荐方式（交互式）：
#    bash <(curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh)
# 2. 传统方式（直接指定路径）：
#    bash <(curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh) "/Users/your-name/Downloads/installers"

# ==============================================================================

# Removed set -e and set -o pipefail to prevent script interruption
# when hdiutil returns non-zero exit codes despite successful mounting

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $1${NC}"
}


# 全局变量
LOCAL_INSTALLERS_DIR=""  # 用户提供的本地安装包目录

# 安装结果追踪数组
declare -a successful_installs=()    # 成功安装的应用
declare -a bypassed_installs=()      # 跳过的安装（已存在、加密绕过等）
declare -a failed_installs=()        # 失败的安装
declare -a updated_installs=()       # 版本更新的应用


# 解析命令行参数
parse_arguments() {
    if [ $# -eq 0 ]; then
        # 新的交互式模式：提示用户拖拽文件夹
        prompt_for_folder
        return
    fi
    
    local installers_path="$1"
    
    # 展开 ~ 路径
    installers_path="${installers_path/#\~/$HOME}"
    
    # 检查路径是否存在
    if [ ! -d "$installers_path" ]; then
        error "指定的目录不存在: $installers_path"
        exit 1
    fi
    
    # 检查目录中是否有安装包
    local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
    
    if [ "$package_count" -eq 0 ]; then
        error "指定目录中没有找到安装包文件 (.dmg, .iso, .pkg, .zip)"
        exit 1
    else
        LOCAL_INSTALLERS_DIR="$installers_path"
        log "发现 $package_count 个本地安装包"
    fi
}

# 提示用户拖拽文件夹
prompt_for_folder() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║                   叮当装 InstallFlow                         ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║         一键批量安装 Mac 应用，让装机像叮当一样简单          ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}请提供安装包所在的文件夹路径：${NC}"
    echo ""
    echo -e "${GREEN}操作提示：${NC}"
    echo "   1. 在 Finder 中找到包含安装包的文件夹"
    echo "   2. 将文件夹直接拖拽到这个终端窗口"
    echo "   3. 按回车键确认"
    echo ""
    echo -e "${BLUE}支持的文件类型：${NC} .dmg、.iso、.pkg、.zip、.app"
    echo ""
    
    while true; do
        echo -n "请输入或拖拽文件夹路径: "
        read -r installers_path
        
        # 如果用户输入为空，继续提示
        if [ -z "$installers_path" ]; then
            echo -e "${YELLOW}WARN:  请输入文件夹路径或将文件夹拖拽到终端窗口${NC}"
            continue
        fi
        
        # 清理路径（移除可能的引号和空格）
        installers_path=$(echo "$installers_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
        
        # 展开 ~ 路径
        installers_path="${installers_path/#\~/$HOME}"
        
        # 检查路径是否存在
        if [ ! -d "$installers_path" ]; then
            error "指定的目录不存在: $installers_path"
            echo -e "${YELLOW}请重新输入正确的文件夹路径${NC}"
            echo ""
            continue
        fi
        
        # 检查目录中是否有安装包
        local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
        
        if [ "$package_count" -eq 0 ]; then
            error "指定目录中没有找到安装包文件 (.dmg, .iso, .pkg, .zip, .app)"
            echo -e "${YELLOW}请选择包含安装包的文件夹${NC}"
            echo ""
            continue
        else
            LOCAL_INSTALLERS_DIR="$installers_path"
            log "发现 $package_count 个安装包文件"
            echo ""
            break
        fi
    done
}

# 显示欢迎信息
show_welcome() {
    # 如果是交互式模式，不显示欢迎信息（已经在 prompt_for_folder 中显示了）
    if [ -n "$LOCAL_INSTALLERS_DIR" ]; then
        echo ""
        echo -e "${GREEN}本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
        echo ""
    fi
}



# 检查Rosetta状态并安装
check_rosetta_status() {
    # 检查是否为Apple Silicon Mac
    local arch=$(uname -m)
    if [[ "$arch" != "arm64" ]]; then
        log "检测到Intel Mac，无需Rosetta"
        return 0
    fi
    
    log "检测到Apple Silicon Mac，正在检查Rosetta状态..."
    
    # 检查Rosetta是否已安装
    if arch -x86_64 /usr/bin/true 2>/dev/null; then
        log "Rosetta已安装"
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}Rosetta检测${NC}"
    echo "================================"
    echo -e "${YELLOW}WARN:  Rosetta未安装${NC}"
    echo ""
    echo -e "${BLUE}说明：${NC}"
    echo "   • 检测到Apple Silicon Mac，但未安装Rosetta"
    echo "   • 某些应用可能需要Rosetta才能运行"
    echo "   • 建议现在安装Rosetta以确保兼容性"
    echo ""
    
    # 询问用户是否要安装Rosetta
    while true; do
        local rosetta_choice
        read -p "是否要安装Rosetta？[默认: y] (y/n): " -r rosetta_choice
        case $rosetta_choice in
            [Nn]*)
                echo ""
                echo -e "${YELLOW}跳过Rosetta安装${NC}"
                echo -e "${YELLOW}WARN:  注意：某些Intel应用可能无法运行${NC}"
                echo ""
                break
                ;;
            [Yy]*|"")
                echo ""
                echo -e "${BLUE}正在安装Rosetta...${NC}"
                echo -e "${YELLOW}提示：安装过程可能需要几分钟时间${NC}"
                echo ""
                
                if sudo softwareupdate --install-rosetta --agree-to-license; then
                    echo ""
                    echo -e "${GREEN}Rosetta安装成功${NC}"
                    log "Rosetta安装完成"
                else
                    echo ""
                    echo -e "${RED}Rosetta安装失败${NC}"
                    warn "继续安装可能导致某些应用无法运行"
                fi
                echo ""
                break
                ;;
            *)
                echo "请输入 y (是) 或 n (否)"
                ;;
        esac
    done
    echo "================================"
    echo ""
}

# 检查系统要求
check_requirements() {
    log "检查系统要求..."
    
    # 检查是否为 macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "此脚本仅支持 macOS 系统"
        exit 1
    fi
    
    log "系统检查通过"
    
    # 检查Rosetta状态
    check_rosetta_status
}

# 交互式选择界面
interactive_package_selector() {
    # 检查是否为交互式终端
    if ! tty -s; then
        warn "检测到非交互式环境，将自动选择所有软件包进行安装"
        selected_local_files=("${package_files_list[@]}")
        return
    fi
    local packages=("${packages_list[@]}")
    local package_files=("${package_files_list[@]}")
    local total=${#packages[@]}
    
    if [ $total -eq 0 ]; then
        warn "没有找到可用的安装包"
        exit 1
    fi
    
    # 初始化选择状态（默认全部选中）
    local selected=()
    for i in $(seq 0 $((total-1))); do
        selected[i]=1
    done
    
    local cursor=0
    local page_size=30
    local page_start=0
    
    # 隐藏光标并启用原始模式
    printf '\e[?25l'  # 隐藏光标
    stty -echo        # 禁用回显
    
    # 清理函数
    cleanup_selector() {
        printf '\e[?25h'  # 显示光标
        stty echo         # 启用回显
    }
    
    # 设置清理陷阱
    trap cleanup_selector EXIT
    
    while true; do
        # 清屏并移动到顶部
        clear
        
        # 显示标题
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                    选择要安装的软件包                        ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}使用方向键 ↑↓ 移动光标，空格键 ␣ 切换选择，回车键 ⏎ 确认${NC}"
        echo -e "${YELLOW}   Ctrl+A 全选，Ctrl+N 全不选，ESC 或 q 退出${NC}"
        echo ""
        
        # 计算分页
        local page_end=$((page_start + page_size - 1))
        if [ $page_end -ge $total ]; then
            page_end=$((total - 1))
        fi
        
        # 显示当前页的软件包
        for i in $(seq $page_start $page_end); do
            local prefix=""
            local suffix=""
            local status_icon=""
            
            # 选择状态图标
            if [ "${selected[i]}" -eq 1 ]; then
                status_icon="${GREEN}[x]${NC}"
            else
                status_icon="${RED}[ ]${NC}"
            fi
            
            # 光标位置高亮
            if [ $i -eq $cursor ]; then
                prefix="${BLUE}> ${NC}"
                suffix="${BLUE} <${NC}"
            else
                prefix="  "
                suffix=""
            fi
            
            echo -e "${prefix}[${status_icon}] ${packages[i]}${suffix}"
        done
        
        # 显示分页信息
        if [ $total -gt $page_size ]; then
            echo ""
            echo -e "${YELLOW}第 $((page_start/page_size + 1)) 页，共 $(((total-1)/page_size + 1)) 页${NC}"
        fi
        
        # 显示统计信息
        local selected_count=0
        for i in $(seq 0 $((total-1))); do
            if [ "${selected[i]}" -eq 1 ]; then
                ((selected_count++))
            fi
        done
        
        echo ""
        echo -e "${GREEN}已选择: $selected_count / $total${NC}"
        
        # 使用更精确的按键检测方法
        old_stty_cfg=$(stty -g)
        stty raw -echo
        
        # 读取一个字符，使用十六进制分析
        key=$(dd bs=1 count=1 2>/dev/null)
        key_hex=$(printf '%s' "$key" | hexdump -ve '1/1 "%02x"')
        
        stty $old_stty_cfg
        
        # 处理转义序列（方向键）
        if [ "$key" = $'\x1b' ]; then
            stty raw -echo
            seq1=$(dd bs=1 count=1 2>/dev/null)
            seq2=$(dd bs=1 count=1 2>/dev/null)
            stty $old_stty_cfg
            
            if [ "$seq1" = "[" ]; then
                case "$seq2" in
                    'A')  key="UP" ;;
                    'B')  key="DOWN" ;;
                    'C')  key="RIGHT" ;;
                    'D')  key="LEFT" ;;
                esac
            else
                key="ESC"
            fi
        fi
        
        # 根据十六进制值精确判断按键
        case "$key_hex" in
            "20")     # 空格键的十六进制值 (ASCII 32)
                if [ "${selected[cursor]}" -eq 1 ]; then
                    selected[cursor]=0
                else
                    selected[cursor]=1
                fi
                ;;
            "0a"|"0d"|"")  # 回车键的十六进制值 (ASCII 10, 13) 或空字符串
                # 对于空字符串，我们需要进一步区分
                if [ -z "$key" ] && [ "$key_hex" = "" ]; then
                    # 这是真正的回车键（产生空字符串）
                    break
                elif [ "$key_hex" = "0a" ] || [ "$key_hex" = "0d" ]; then
                    # 这是换行符形式的回车键
                    break
                fi
                ;;
        esac
        
        # 处理其他按键
        case "$key" in
            'UP'|'k')  # 上箭头或 k
                if [ $cursor -gt 0 ]; then
                    ((cursor--))
                    if [ $cursor -lt $page_start ]; then
                        page_start=$((cursor / page_size * page_size))
                    fi
                fi
                ;;
            'DOWN'|'j')  # 下箭头或 j
                if [ $cursor -lt $((total-1)) ]; then
                    ((cursor++))
                    if [ $cursor -gt $page_end ]; then
                        page_start=$(((cursor / page_size) * page_size))
                    fi
                fi
                ;;
            $'\x01')  # Ctrl+A 全选
                for i in $(seq 0 $((total-1))); do
                    selected[i]=1
                done
                ;;
            $'\x0e')  # Ctrl+N 全不选
                for i in $(seq 0 $((total-1))); do
                    selected[i]=0
                done
                ;;
            'ESC'|'q')  # ESC 或 q 退出
                cleanup_selector
                log "用户取消安装"
                exit 0
                ;;
        esac
    done
    
    # 清理
    cleanup_selector
    
    # 收集选中的文件
    selected_local_files=()
    for i in $(seq 0 $((total-1))); do
        if [ "${selected[i]}" -eq 1 ]; then
            selected_local_files+=("${package_files[i]}")
        fi
    done
    
    if [ ${#selected_local_files[@]} -eq 0 ]; then
        warn "没有选择任何安装包"
        exit 0
    fi
    
    # 显示最终选择
    clear
    echo ""
    log "将安装以下软件包："
    for file in "${selected_local_files[@]}"; do
        echo -e "  • ${GREEN}$(basename "$file")${NC}"
    done
    echo ""
    
    read -p "确认安装？[默认: y] (y/n): " -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log "用户取消安装"
        exit 0
    fi
}

# 分析本地安装包
analyze_local_packages() {
    
    log "分析本地安装包..."
    
    packages_list=()
    package_files_list=()
    
    # 遍历本地安装包目录（兼容bash 3.x，包括子目录和.app文件）
    local temp_file="/tmp/packages_list_$$"
    find "$LOCAL_INSTALLERS_DIR" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" > "$temp_file"
    
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local filename=$(basename "$file")
            local name_without_ext="${filename%.*}"
            # 清理文件名（移除版本号、特殊字符等）
            local clean_name=$(echo "$name_without_ext" | sed 's/[0-9\.-]*$//' | sed 's/[-_]/ /g' | sed 's/ *$//')
            
            packages_list+=("$clean_name")
            package_files_list+=("$file")
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    # 启动交互式选择器
    interactive_package_selector
}

# 显示软件包选择菜单
show_package_menu() {
    analyze_local_packages
}

# ==============================================================================
# 通用辅助函数
# ==============================================================================

# 递归的嵌套DMG挂载和处理函数，支持多层嵌套
mount_and_process_nested_dmg() {
    local dmg_path="$1"
    local parent_type="$2"  # "DMG", "ISO", "ZIP"
    local parent_filename="$3"
    local depth="${4:-1}"  # 嵌套深度，默认为1
    local max_depth=5  # 最大嵌套深度限制
    
    local dmg_name=$(basename "$dmg_path")
    
    # 检查嵌套深度限制
    if [ $depth -gt $max_depth ]; then
        echo "  [FAIL] 嵌套深度超过限制($max_depth)，跳过: $dmg_name"
        failed_installs+=("$parent_filename (嵌套DMG深度超过限制)")
        return 1
    fi
    
    echo "  [PKG] 在${parent_type}中找到DMG: $dmg_name (深度: $depth)"
    
    # 使用增强的挂载函数
    local NESTED_MOUNT_POINT=$(mount_dmg_with_retry "$dmg_path" "$dmg_name")
    if [ $? -ne 0 ] || [ -z "$NESTED_MOUNT_POINT" ]; then
        failed_installs+=("$parent_filename (嵌套DMG挂载失败: $dmg_name)")
        return 1
    fi
    
    if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
        echo "  [OK] 嵌套DMG挂载成功"
        echo "  已挂载到: $NESTED_MOUNT_POINT"
        
        # 首先检查是否有更深层的DMG文件（递归处理）
        local DEEPER_DMG=$(find "$NESTED_MOUNT_POINT" -name "*.dmg" -maxdepth 2 -print -quit 2>/dev/null)
        
        if [ -n "$DEEPER_DMG" ]; then
            echo "  [PKG] 发现更深层DMG文件，递归处理..."
            # 递归调用处理更深层的DMG
            mount_and_process_nested_dmg "$DEEPER_DMG" "${parent_type}" "$parent_filename" $((depth + 1))
        else
            # 在嵌套DMG中查找.app文件
            local NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
            
            if [ -n "$NESTED_APP_PATH" ]; then
                local APP_NAME=$(basename "$NESTED_APP_PATH")
                echo "  [FIND] 在嵌套DMG中找到应用: $APP_NAME"
                
                # 使用智能APP覆盖检测
                if check_app_installation "$NESTED_APP_PATH" "$parent_filename"; then
                    local TARGET_APP_PATH="/Applications/$APP_NAME"
                    echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                    if cp -R "$NESTED_APP_PATH" "/Applications/"; then
                        echo "  拷贝完成。"
                        
                        # 移除应用的隔离属性
                        echo "  正在移除应用的隔离属性..."
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        echo "  隔离属性移除完成。"
                        
                        successful_installs+=("$APP_NAME (${parent_type}嵌套DMG-深度$depth)")
                    else
                        echo "  ERROR: 拷贝失败"
                        failed_installs+=("$parent_filename (${parent_type}嵌套DMG应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                echo "  [FAIL] 在嵌套DMG中未找到 .app 文件，尝试搜索嵌套目录..."
                # 调用嵌套目录搜索
                search_nested_install_directory "$NESTED_MOUNT_POINT" "DMG" "$parent_filename"
            fi
        fi
        
        # 推出嵌套DMG
        echo "  正在推出嵌套DMG: $dmg_name..."
        sleep 1
        if hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
            echo "  [OK] 嵌套DMG推出完成。"
        else
            sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
            echo "  [OK] 嵌套DMG强制推出完成。"
        fi
    fi
}

# 通用的嵌套目录搜索函数
search_nested_install_directory() {
    local mount_point="$1"
    local file_type="$2"  # "DMG" 或 "ISO"
    local filename="$3"
    
    # 扩展的目录搜索模式：查找常见的安装目录模式
    local install_dirs=$(find "$mount_point" \( \
        -name "*[Mm]anual*install*" -o \
        -name "*[Ii]nstall*" -o \
        -name "*[Cc]ontents*" -o \
        -name "*[Aa]pplications*" -o \
        -name "*[Aa]pp*" -o \
        -name "*[Ss]oftware*" -o \
        -name "*[Pp]rogram*" -o \
        -name "*[Rr]esources*" \
        \) -type d -maxdepth 3 2>/dev/null)
    
    if [ -n "$install_dirs" ]; then
        # 处理找到的第一个安装目录
        local INSTALL_DIR=$(echo "$install_dirs" | head -1)
        echo "  [DIR] 发现嵌套安装结构，找到安装目录: $(basename "$INSTALL_DIR")"
        
        # 在安装目录中查找DMG文件
        local NESTED_DMG=$(find "$INSTALL_DIR" -name "*.dmg" 2>/dev/null | head -1)
        
        if [ -n "$NESTED_DMG" ]; then
            # 调用通用的嵌套DMG处理函数
            mount_and_process_nested_dmg "$NESTED_DMG" "$file_type" "$filename"
        else
            # 直接在安装目录中查找.app文件
            echo "  [FIND] 安装目录中未找到DMG文件，直接查找.app文件..."
            local INSTALL_APP_PATH=$(find "$INSTALL_DIR" -name "*.app" -maxdepth 3 -print -quit)
            
            if [ -n "$INSTALL_APP_PATH" ]; then
                local APP_NAME=$(basename "$INSTALL_APP_PATH")
                echo "  [FIND] 在安装目录中找到应用: $APP_NAME"
                
                # 使用智能APP覆盖检测
                if check_app_installation "$INSTALL_APP_PATH" "$filename"; then
                    local TARGET_APP_PATH="/Applications/$APP_NAME"
                    echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                    if cp -R "$INSTALL_APP_PATH" "/Applications/"; then
                        echo "  拷贝完成。"
                        
                        # 移除应用的隔离属性
                        echo "  正在移除应用的隔离属性..."
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        echo "  隔离属性移除完成。"
                        
                        successful_installs+=("$APP_NAME (${file_type}嵌套目录)")
                    else
                        echo "  ERROR: 拷贝失败"
                        failed_installs+=("$filename (${file_type}嵌套目录应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                echo "  [FAIL] 在安装目录中也未找到.app文件"
                echo "  [DEBUG] 安装目录内容:"
                if [ -d "$INSTALL_DIR" ]; then
                    ls -la "$INSTALL_DIR" 2>/dev/null | head -10 | sed 's/^/    /'
                else
                    echo "    安装目录不存在: $INSTALL_DIR"
                fi
                echo "  [DEBUG] 递归搜索.app文件:"
                if [ -d "$INSTALL_DIR" ]; then
                    find "$INSTALL_DIR" -name "*.app" -type d 2>/dev/null | head -5 | sed 's/^/    /' || echo "    未找到.app文件"
                fi
                failed_installs+=("$filename (${file_type}安装目录中未找到.app文件)")
            fi
        fi
    else
        echo "  [DEBUG] 未找到嵌套安装结构，显示${file_type}内容:"
        echo "  [DEBUG] 根目录内容:"
        if [ -d "$mount_point" ]; then
            ls -la "$mount_point" 2>/dev/null | head -10 | sed 's/^/    /'
        else
            echo "    挂载点不存在: $mount_point"
        fi
        echo "  [DEBUG] 搜索所有.app文件:"
        if [ -d "$mount_point" ]; then
            find "$mount_point" -name "*.app" -type d 2>/dev/null | head -5 | sed 's/^/    /' || echo "    未找到.app文件"
        fi
        echo "  [DEBUG] 搜索所有子目录:"
        if [ -d "$mount_point" ]; then
            find "$mount_point" -type d -maxdepth 2 2>/dev/null | head -10 | sed 's/^/    /' || echo "    未找到子目录"
        fi
        failed_installs+=("$filename (${file_type}中未找到.app文件)")
    fi
}

# ==============================================================================
# 创建安装脚本
# ==============================================================================

# 获取APP文件的版本号
get_app_version() {
    local app_path="$1"
    local version=""
    
    if [ -d "$app_path" ]; then
        # 尝试从Info.plist中获取CFBundleShortVersionString
        local info_plist="$app_path/Contents/Info.plist"
        if [ -f "$info_plist" ]; then
            version=$(defaults read "$info_plist" CFBundleShortVersionString 2>/dev/null || echo "")
            if [ -z "$version" ]; then
                # 如果没有CFBundleShortVersionString，尝试CFBundleVersion
                version=$(defaults read "$info_plist" CFBundleVersion 2>/dev/null || echo "")
            fi
        fi
    fi
    
    echo "$version"
}

# 比较版本号 (返回0表示相等，1表示第一个版本更新，-1表示第二个版本更新)
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 如果任一版本为空，无法比较
    if [ -z "$version1" ] || [ -z "$version2" ]; then
        echo "0"
        return
    fi
    
    # 使用sort的版本比较功能
    local result=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)
    
    if [ "$result" = "$version1" ]; then
        if [ "$version1" = "$version2" ]; then
            echo "0"  # 相等
        else
            echo "-1"  # version1 < version2
        fi
    else
        echo "1"  # version1 > version2
    fi
}

# 智能APP覆盖检测（带版本号比较）
check_app_installation() {
    local new_app_path="$1"
    local filename="$2"
    
    local app_name=$(basename "$new_app_path")
    local target_app_path="/Applications/$app_name"
    
    # 检查应用是否已存在
    if [ -d "$target_app_path" ]; then
        echo "  检测到应用 '$app_name' 已存在"
        
        # 获取现有应用和新应用的版本号
        local existing_version=$(get_app_version "$target_app_path")
        local new_version=$(get_app_version "$new_app_path")
        
        echo "  现有版本: ${existing_version:-未知}"
        echo "  新版本:   ${new_version:-未知}"
        
        # 如果能获取到版本号，进行比较
        if [ -n "$existing_version" ] && [ -n "$new_version" ]; then
            local comparison=$(compare_versions "$new_version" "$existing_version")
            
            case $comparison in
                "1")
                    echo "  检测到新版本，自动更新: $existing_version → $new_version"
                    # 记录版本更新信息
                    updated_installs+=("$app_name: $existing_version → $new_version")
                    return 0  # 继续安装
                    ;;
                "0")
                    echo "  版本相同，跳过安装"
                    bypassed_installs+=("$filename (相同版本已存在: $existing_version)")
                    return 1
                    ;;
                "-1")
                    echo "  现有版本更高，跳过安装"
                    bypassed_installs+=("$filename (更高版本已存在: $existing_version)")
                    return 1
                    ;;
            esac
        else
            echo "  无法获取版本信息，跳过安装"
            bypassed_installs+=("$filename (应用已存在，版本未知)")
            return 1
        fi
    else
        return 0  # 应用不存在，可以安装
    fi
}

# 通用DMG挂载函数，支持重试和动态超时
mount_dmg_with_retry() {
    local installer_path="$1"
    local filename="$2"
    local max_attempts="${3:-3}"  # 默认3次尝试
    
    # 根据文件大小动态调整超时时间
    local file_size=$(stat -f%z "$installer_path" 2>/dev/null || echo "0")
    local timeout=30  # 基础超时30秒
    if [ "$file_size" -gt 500000000 ]; then  # 大于500MB
        timeout=60
    elif [ "$file_size" -gt 100000000 ]; then  # 大于100MB
        timeout=45
    fi
    
    for attempt in $(seq 1 $max_attempts); do
        echo "  [类型: DMG] - 挂载尝试 $attempt/$max_attempts (超时: ${timeout}秒)..." >&2
        
        # 获取挂载前的挂载点列表
        local mount_before=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
        
        # 使用 yes 命令自动回答许可协议，并重定向输出，添加超时保护
        (yes | hdiutil attach "$installer_path" -nobrowse -noverify > /dev/null 2>&1) &
        local hdiutil_pid=$!
        
        # 等待挂载完成
        local count=0
        while [ $count -lt $timeout ]; do
            if ! kill -0 $hdiutil_pid 2>/dev/null; then
                # 进程已结束
                break
            fi
            sleep 1
            ((count++))
            if [ $count -eq 10 ]; then
                echo "  等待许可协议处理..." >&2
            elif [ $count -eq 20 ]; then
                echo "  仍在挂载中，请稍候..." >&2
            fi
        done
        
        # 如果进程还在运行，就终止它
        if kill -0 $hdiutil_pid 2>/dev/null; then
            echo "  挂载超时，终止进程..." >&2
            kill $hdiutil_pid 2>/dev/null
            sleep 2
            kill -9 $hdiutil_pid 2>/dev/null
        fi
        
        # 等待一下让挂载完成
        sleep 2
        
        # 获取挂载后的挂载点列表
        local mount_after=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
        
        # 找出新增的挂载点
        local new_mount_point=""
        while IFS= read -r mount_path; do
            local found=0
            while IFS= read -r existing_mount; do
                if [ "$existing_mount" = "$mount_path" ]; then
                    found=1
                    break
                fi
            done <<< "$mount_before"
            if [ $found -eq 0 ]; then
                new_mount_point="$mount_path"
                break
            fi
        done <<< "$mount_after"
        
        # 检查挂载是否成功
        if [ -n "$new_mount_point" ] && [ -d "$new_mount_point" ]; then
            echo "  [OK] DMG挂载成功" >&2
            echo "  已挂载到: $new_mount_point" >&2
            echo "$new_mount_point"  # 只有挂载点返回到stdout
            return 0
        else
            echo "  [FAIL] 挂载尝试 $attempt 失败" >&2
            if [ $attempt -lt $max_attempts ]; then
                echo "  等待3秒后重试..." >&2
                sleep 3
            fi
        fi
    done
    
    echo "  [FAIL] DMG挂载失败: $filename (所有尝试均失败)" >&2
    return 1
}

# 安装DMG文件
install_dmg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    # 使用新的挂载函数
    MOUNT_POINT=$(mount_dmg_with_retry "$installer_path" "$filename")
    if [ $? -ne 0 ] || [ -z "$MOUNT_POINT" ]; then
        failed_installs+=("$filename (DMG挂载失败)")
        return 1
    fi
    
    # 查找PKG文件
    PKG_PATH=""
    shopt -s nullglob  # 启用nullglob，让glob在没有匹配时返回空
    pkg_files=("$MOUNT_POINT"/*.pkg)
    if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
        PKG_PATH="${pkg_files[0]}"
    fi
    shopt -u nullglob  # 恢复默认设置
    
    # 安装PKG（如果存在）
    if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
        PKG_NAME=$(basename "$PKG_PATH")
        echo "  发现PKG安装包: $PKG_NAME"
        echo "  正在安装PKG..."
        
        if sudo installer -pkg "$PKG_PATH" -target /; then
            echo "  PKG安装成功"
            local pkg_name=$(basename "$PKG_PATH" .pkg)
            successful_installs+=("$pkg_name (从DMG中的PKG)")
        else
            echo "  ERROR: PKG安装失败"
            failed_installs+=("$filename (DMG中的PKG安装失败)")
        fi
    fi
    
    # 查找并安装.app文件（只有在没有PKG时）
    if [ -z "$PKG_PATH" ]; then
        # 首先检查是否有嵌套DMG文件（如ServerCat案例）
        local NESTED_DMG=$(find "$MOUNT_POINT" -name "*.dmg" -maxdepth 2 -print -quit 2>/dev/null)
        
        if [ -n "$NESTED_DMG" ]; then
            echo "  [PKG] 在DMG中发现嵌套DMG文件: $(basename "$NESTED_DMG")"
            mount_and_process_nested_dmg "$NESTED_DMG" "DMG" "$filename" 1
        else
            echo "  查找 .app 文件..."
            
            APP_PATH=""
            shopt -s nullglob  # 启用nullglob
            app_files=("$MOUNT_POINT"/*.app)
            if [ ${#app_files[@]} -gt 0 ] && [ -d "${app_files[0]}" ]; then
                APP_PATH="${app_files[0]}"
            fi
            shopt -u nullglob  # 恢复默认设置
            
            if [ -n "$APP_PATH" ]; then
                # 常规DMG包含.app文件
                APP_NAME=$(basename "$APP_PATH")
                echo "  找到应用: $APP_NAME"
                
                # 使用智能APP覆盖检测（带版本号比较）
                if check_app_installation "$APP_PATH" "$filename"; then
                    TARGET_APP_PATH="/Applications/$APP_NAME"
                    echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                    if cp -R "$APP_PATH" "/Applications/"; then
                        echo "  拷贝完成。"
                        
                        # 移除应用的隔离属性
                        echo "  正在移除应用的隔离属性..."
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        echo "  隔离属性移除完成。"
                        
                        successful_installs+=("$APP_NAME (从DMG)")
                    else
                        echo "  ERROR: 拷贝失败"
                        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                echo "  未找到 .app 文件，检查嵌套安装结构..."
                # 调用通用的嵌套目录搜索函数
                search_nested_install_directory "$MOUNT_POINT" "DMG" "$filename"
            fi
        fi
    fi
    
    # 推出DMG
    echo "  正在推出DMG: $filename..."
    sleep 1
    
    if hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        echo "  [OK] DMG推出完成。"
    else
        # 尝试强制推出
        if sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null; then
            echo "  [OK] DMG强制推出完成。"
        else
            warn "DMG推出失败，但这不影响正常使用"
        fi
    fi
}

# 安装ISO文件
install_iso_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    # 使用增强的挂载函数
    MOUNT_POINT=$(mount_dmg_with_retry "$installer_path" "$filename")
    if [ $? -ne 0 ] || [ -z "$MOUNT_POINT" ]; then
        failed_installs+=("$filename (ISO挂载失败)")
        return 1
    fi
    
    # 首先检查是否有DMG文件（如Prompt案例）
    local DMG_PATH=""
    shopt -s nullglob  # 启用nullglob
    dmg_files=("$MOUNT_POINT"/*.dmg)
    if [ ${#dmg_files[@]} -gt 0 ] && [ -f "${dmg_files[0]}" ]; then
        DMG_PATH="${dmg_files[0]}"
    fi
    shopt -u nullglob  # 恢复默认设置
    
    # 如果找到DMG文件，使用嵌套DMG处理逻辑
    if [ -n "$DMG_PATH" ]; then
        echo "  [PKG] 在ISO中发现DMG文件: $(basename "$DMG_PATH")"
        mount_and_process_nested_dmg "$DMG_PATH" "ISO" "$filename" 1
    else
        # 查找PKG文件
        PKG_PATH=""
        shopt -s nullglob  # 启用nullglob，让glob在没有匹配时返回空
        pkg_files=("$MOUNT_POINT"/*.pkg)
        if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
            PKG_PATH="${pkg_files[0]}"
        fi
        shopt -u nullglob  # 恢复默认设置
        
        # 安装PKG（如果存在）
        if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
            PKG_NAME=$(basename "$PKG_PATH")
            echo "  发现PKG安装包: $PKG_NAME"
            echo "  正在安装PKG..."
            
            if sudo installer -pkg "$PKG_PATH" -target /; then
                echo "  PKG安装成功"
                local pkg_name=$(basename "$PKG_PATH" .pkg)
                successful_installs+=("$pkg_name (从ISO中的PKG)")
            else
                echo "  ERROR: PKG安装失败"
                failed_installs+=("$filename (ISO中的PKG安装失败)")
            fi
        fi
        
        # 查找并安装.app文件（只有在没有PKG时）
        if [ -z "$PKG_PATH" ]; then
            echo "  查找 .app 文件..."
            
            APP_PATH=""
            shopt -s nullglob  # 启用nullglob
            app_files=("$MOUNT_POINT"/*.app)
            if [ ${#app_files[@]} -gt 0 ] && [ -d "${app_files[0]}" ]; then
                APP_PATH="${app_files[0]}"
            fi
            shopt -u nullglob  # 恢复默认设置
            
            if [ -n "$APP_PATH" ]; then
                # 常规ISO包含.app文件
                APP_NAME=$(basename "$APP_PATH")
                echo "  找到应用: $APP_NAME"
                
                # 使用智能APP覆盖检测（带版本号比较）
                if check_app_installation "$APP_PATH" "$filename"; then
                    TARGET_APP_PATH="/Applications/$APP_NAME"
                    echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                    if cp -R "$APP_PATH" "/Applications/"; then
                        echo "  拷贝完成。"
                        
                        # 移除应用的隔离属性
                        echo "  正在移除应用的隔离属性..."
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        echo "  隔离属性移除完成。"
                        
                        successful_installs+=("$APP_NAME (从ISO)")
                    else
                        echo "  ERROR: 拷贝失败"
                        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                echo "  未找到 .app 文件，检查嵌套安装结构..."
                # 调用通用的嵌套目录搜索函数
                search_nested_install_directory "$MOUNT_POINT" "ISO" "$filename"
            fi
        fi
    fi
    
    # 推出ISO
    echo "  正在推出ISO: $filename..."
    sleep 1
    
    if hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        echo "  [OK] ISO推出完成。"
    else
        # 尝试强制推出
        if sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null; then
            echo "  [OK] ISO强制推出完成。"
        else
            warn "ISO推出失败，但这不影响正常使用"
        fi
    fi
}

# 安装PKG文件
install_pkg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: PKG] - 正在安装PKG包..."
    
    if sudo installer -pkg "$installer_path" -target /; then
        echo "  [OK] PKG安装成功"
        local pkg_name=$(basename "$installer_path" .pkg)
        successful_installs+=("$pkg_name")
    else
        echo "  [FAIL] PKG安装失败"
        failed_installs+=("$filename (PKG安装失败)")
    fi
}

# 安装ZIP文件
install_zip_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: ZIP] - 正在处理..."
    
    # 创建临时解压目录
    local temp_dir="/tmp/install_zip_$$"
    mkdir -p "$temp_dir"
    
    echo "  正在解压ZIP文件..."
    if unzip -q "$installer_path" -d "$temp_dir"; then
        echo "  解压成功"
        
        # 1. 首先查找DMG文件
        local dmg_path=$(find "$temp_dir" -name "*.dmg" -type f -print -quit 2>/dev/null)
        if [ -n "$dmg_path" ]; then
            echo "  找到DMG文件: $(basename "$dmg_path")"
            # 调用通用的嵌套DMG处理函数
            mount_and_process_nested_dmg "$dmg_path" "ZIP" "$filename"
        else
            # 2. 如果没有DMG，查找PKG文件
            local pkg_path=$(find "$temp_dir" -name "*.pkg" -type f -print -quit 2>/dev/null)
            if [ -n "$pkg_path" ]; then
                echo "  找到PKG文件: $(basename "$pkg_path")"
                echo "  正在安装PKG..."
                if sudo installer -pkg "$pkg_path" -target /; then
                    echo "  PKG安装成功"
                    local pkg_name=$(basename "$pkg_path" .pkg)
                    successful_installs+=("$pkg_name (从ZIP中的PKG)")
                else
                    echo "  ERROR: PKG安装失败"
                    failed_installs+=("$filename (ZIP中的PKG安装失败)")
                fi
            else
                # 3. 如果都没有，查找.app文件
                local app_path=$(find "$temp_dir" -name "*.app" -type d -print -quit 2>/dev/null)
                if [ -n "$app_path" ]; then
                    local app_name=$(basename "$app_path")
                    echo "  找到应用: $app_name"
                    
                    # 使用智能APP覆盖检测
                    if check_app_installation "$app_path" "$filename"; then
                        local target_app_path="/Applications/$app_name"
                        echo "  正在将 '$app_name' 拷贝到 /Applications ..."
                        if cp -R "$app_path" "/Applications/"; then
                            echo "  拷贝完成。"
                            
                            # 移除应用的隔离属性
                            echo "  正在移除应用的隔离属性..."
                            xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
                            echo "  隔离属性移除完成。"
                            
                            successful_installs+=("$app_name (从ZIP)")
                        else
                            echo "  ERROR: 拷贝失败"
                            failed_installs+=("$filename (ZIP应用拷贝失败: $app_name)")
                        fi
                    fi
                else
                    echo "  [FAIL] ZIP文件中未找到可安装文件"
                    failed_installs+=("$filename (ZIP中未找到DMG/PKG/APP文件)")
                fi
            fi
        fi
    else
        echo "  [FAIL] ZIP解压失败"
        failed_installs+=("$filename (ZIP解压失败)")
    fi
    
    # 清理临时目录
    rm -rf "$temp_dir"
}

# 直接安装.app文件
install_app_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    local app_name=$(basename "$installer_path")
    
    echo "  [类型: APP] - 正在处理..."
    
    # 使用智能APP覆盖检测
    if check_app_installation "$installer_path" "$filename"; then
        local target_app_path="/Applications/$app_name"
        echo "  正在将 '$app_name' 拷贝到 /Applications ..."
        if cp -R "$installer_path" "/Applications/"; then
            echo "  拷贝完成。"
            
            # 移除应用的隔离属性
            echo "  正在移除应用的隔离属性..."
            xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
            echo "  隔离属性移除完成。"
            
            successful_installs+=("$app_name (直接拷贝)")
        else
            echo "  ERROR: 拷贝失败"
            failed_installs+=("$filename (APP拷贝失败)")
        fi
    fi
}

# 安装本地安装包
install_local_packages() {
    local total=${#selected_local_files[@]}
    local current=1
    
    log "开始安装本地安装包..."
    
    for file in "${selected_local_files[@]}"; do
        local filename=$(basename "$file")
        echo ""
        echo "[$current/$total] 正在处理: $filename"
        
        # 根据文件扩展名选择不同的安装方法
        case "${file##*.}" in
            dmg)
                install_dmg_file "$file"
                ;;
            iso)
                install_iso_file "$file"
                ;;
            pkg)
                install_pkg_file "$file"
                ;;
            zip)
                install_zip_file "$file"
                ;;
            app)
                install_app_file "$file"
                ;;
            *)
                warn "不支持的文件类型: $filename"
                failed_installs+=("$filename (不支持的文件类型)")
                ;;
        esac
        
        ((current++))
    done
}

# 显示安装结果
show_install_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}                        安装结果摘要${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # 成功安装的应用
    if [ ${#successful_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}[OK] 成功安装 (${#successful_installs[@]}个):${NC}"
        for app in "${successful_installs[@]}"; do
            echo -e "   • ${GREEN}$app${NC}"
        done
        echo ""
    fi
    
    # 版本更新的应用
    if [ ${#updated_installs[@]} -gt 0 ]; then
        echo -e "${BLUE}[UPDATE] 版本更新 (${#updated_installs[@]}个):${NC}"
        for update in "${updated_installs[@]}"; do
            echo -e "   • ${BLUE}$update${NC}"
        done
        echo ""
    fi
    
    # 跳过的安装
    if [ ${#bypassed_installs[@]} -gt 0 ]; then
        echo -e "${YELLOW}[SKIP] 跳过安装 (${#bypassed_installs[@]}个):${NC}"
        for bypass in "${bypassed_installs[@]}"; do
            echo -e "   • ${YELLOW}$bypass${NC}"
        done
        echo ""
    fi
    
    # 失败的安装
    if [ ${#failed_installs[@]} -gt 0 ]; then
        echo -e "${RED}[FAIL] 安装失败 (${#failed_installs[@]}个):${NC}"
        for failure in "${failed_installs[@]}"; do
            echo -e "   • ${RED}$failure${NC}"
        done
        echo ""
    fi
    
    # 统计信息
    local total_processed=$((${#successful_installs[@]} + ${#bypassed_installs[@]} + ${#failed_installs[@]}))
    local success_rate=0
    if [ $total_processed -gt 0 ]; then
        success_rate=$(( (${#successful_installs[@]} + ${#bypassed_installs[@]}) * 100 / total_processed ))
    fi
    
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}统计信息:${NC}"
    echo -e "   处理总数: $total_processed"
    echo -e "   成功率:   $success_rate%"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ ${#successful_installs[@]} -gt 0 ] || [ ${#updated_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}[DONE] 安装完成！所有应用已成功安装到 /Applications 目录。${NC}"
        echo ""
        echo -e "${BLUE}注意事项：${NC}"
        echo "   • 首次打开应用时，macOS 可能会显示安全提示"
        echo "   • 如果应用无法打开，请右键点击应用选择「打开」"
        echo "   • 或在「系统偏好设置 → 安全性与隐私」中允许应用运行"
    else
        echo -e "${YELLOW}没有成功安装任何新应用。${NC}"
    fi
    
    echo ""
}

# 主函数
main() {
    # 检查系统要求
    check_requirements
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 显示欢迎信息
    show_welcome
    
    # 显示包选择菜单
    show_package_menu
    
    # 安装选中的本地包
    install_local_packages
    
    # 显示安装结果
    show_install_summary
}

# 运行主函数
main "$@"