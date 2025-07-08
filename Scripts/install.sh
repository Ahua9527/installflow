#!/bin/bash

# ==============================================================================
# Mac Setup Bootstrap Script
# 一键下载并执行 Mac 自动化配置脚本
# 
# 使用方法：
# curl -fsSL https://raw.githubusercontent.com/yourname/mac-setup/main/bootstrap.sh | bash
# 或者：
# bash <(curl -fsSL https://your-domain.com/bootstrap.sh)
# ==============================================================================

set -e
set -o pipefail

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
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] ℹ️  $1${NC}"
}

# 配置
TEMP_DIR="/tmp/mac_setup_$(date +%s)"

# 全局变量
LOCAL_INSTALLERS_DIR=""  # 用户提供的本地安装包目录


# 解析命令行参数
parse_arguments() {
    if [ $# -eq 0 ]; then
        error "请提供安装包目录路径"
        echo ""
        show_help
        exit 1
    fi
    
    local installers_path="$1"
    
    # 检查路径是否存在
    if [ ! -d "$installers_path" ]; then
        error "指定的目录不存在: $installers_path"
        exit 1
    fi
    
    # 检查目录中是否有安装包
    local package_count=$(find "$installers_path" -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" | wc -l)
    
    if [ "$package_count" -eq 0 ]; then
        error "指定目录中没有找到安装包文件 (.dmg, .pkg, .zip)"
        exit 1
    else
        LOCAL_INSTALLERS_DIR="$installers_path"
        log "发现 $package_count 个本地安装包"
    fi
}

# 显示欢迎信息
show_welcome() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║                   🚀 Mac Setup Bootstrap                     ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║            使用本地安装包进行自动化配置                        ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}📁 本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
    echo ""
}

# 检查Gatekeeper状态
check_gatekeeper_status() {
    log "检查Gatekeeper状态..."
    
    local gatekeeper_status=$(spctl --status 2>/dev/null)
    
    echo ""
    echo -e "${BLUE}📋 Gatekeeper状态检查${NC}"
    echo "================================"
    
    if [ "$gatekeeper_status" = "assessments enabled" ]; then
        echo -e "${YELLOW}⚠️  Gatekeeper状态：已启用${NC}"
        echo ""
        echo -e "${YELLOW}💡 说明：${NC}"
        echo "   • Gatekeeper已启用，系统会验证应用签名"
        echo "   • 安装的应用可能需要额外确认才能运行"
        echo "   • 第三方应用可能显示\"无法打开\"的提示"
        echo ""
        echo -e "${BLUE}🔧 建议操作：${NC}"
        echo "   为了顺利安装和运行第三方应用，建议临时关闭Gatekeeper"
        echo ""
        echo -e "${GREEN}✅ 好处：${NC}"
        echo "   • 安装的应用可以直接运行，无需额外确认"
        echo "   • 避免\"无法打开应用\"的问题"
        echo "   • 简化安装流程"
        echo ""
        echo -e "${RED}⚠️  注意：${NC}"
        echo "   • 关闭Gatekeeper会降低系统安全性"
        echo "   • 建议安装完成后重新启用"
        echo "   • 重新启用命令：sudo spctl --master-enable"
        echo ""
        
        # 询问用户是否要关闭Gatekeeper
        while true; do
            read -p "是否要临时关闭Gatekeeper以便顺利安装应用？[默认: y] (y/n): " -r gatekeeper_choice
            case $gatekeeper_choice in
                [Nn]*)
                    echo ""
                    echo -e "${YELLOW}保持Gatekeeper启用状态${NC}"
                    echo ""
                    echo -e "${BLUE}💡 如遇到应用无法打开的问题：${NC}"
                    echo -e "     ${BLUE}1.${NC} 右键点击应用 → 选择\"打开\""
                    echo -e "     ${BLUE}2.${NC} 或在\"系统偏好设置 → 安全性与隐私\"中允许"
                    echo ""
                    break
                    ;;
                [Yy]*|"")
                    echo ""
                    echo -e "${BLUE}正在关闭Gatekeeper...${NC}"
                    if sudo spctl --master-disable 2>/dev/null; then
                        echo -e "${GREEN}✅ Gatekeeper已关闭${NC}"
                        echo ""
                        echo -e "${YELLOW}📝 重要提醒：${NC}"
                        echo "   安装完成后，建议重新启用Gatekeeper："
                        echo -e "   ${BLUE}sudo spctl --master-enable${NC}"
                        echo ""
                    else
                        echo -e  "${YELLOW} 下一步：${NC}"
                        echo -e  "${YELLOW}1. 打开 系统偏好设置${NC}"
                        echo -e  "${YELLOW}2. 进入 安全性与隐私${NC}"
                        echo -e  "${YELLOW}3. 确认 允许任何来源 已勾选${NC}"
                    fi
                    break
                    ;;
                *)
                    echo "请输入 y (是) 或 n (否)"
                    ;;
            esac
        done
    elif [ "$gatekeeper_status" = "assessments disabled" ]; then
        echo -e "${GREEN}✅ Gatekeeper状态：已关闭 - 有利于第三方应用安装${NC}"
    else
        echo -e "${YELLOW}❓ Gatekeeper状态：未知${NC}"
        echo "   • 无法确定当前状态"
    fi
    
    echo "================================"
    echo ""
    
    # 只有在需要用户交互时才显示确认提示
    if [ "$gatekeeper_status" = "assessments enabled" ]; then
        # 如果Gatekeeper启用，可能需要用户决定，所以显示确认
        echo -e "${YELLOW}请确认您已了解上述信息。${NC}"
        read -p "按回车键继续，或按 Ctrl+C 退出... " -r
        echo ""
    elif [ "$gatekeeper_status" = "assessments disabled" ]; then
        # 如果Gatekeeper已关闭，直接继续，不需要额外确认
        echo ""
    else
        # 状态未知时显示确认
        echo -e "${YELLOW}请确认您已了解上述信息。${NC}"
        read -p "按回车键继续，或按 Ctrl+C 退出... " -r
        echo ""
    fi
}

# 安装完成后的Gatekeeper检查
final_gatekeeper_check() {
    local final_status=$(spctl --status 2>/dev/null)
    
    if [ "$final_status" = "assessments disabled" ]; then
        echo ""
        echo -e "${BLUE}🔒 安全提醒${NC}"
        echo "================================"
        echo -e "${YELLOW}⚠️  Gatekeeper当前处于关闭状态${NC}"
        echo ""
        echo -e "${BLUE}💡 建议：${NC}"
        echo "   为了系统安全，建议重新启用Gatekeeper"
        echo ""
        echo -e "${GREEN}🔧 重新启用命令：${NC}"
        echo -e "   ${BLUE}sudo spctl --master-enable${NC}"
        echo ""
        echo -e "${YELLOW}📝 说明：${NC}"
        echo "   • 重新启用后，系统会重新验证应用签名"
        echo "   • 已安装的应用不受影响，仍可正常运行"
        echo "   • 新安装的未签名应用需要手动确认"
        echo ""
        
        # 询问是否立即重新启用
        while true; do
            read -p "是否现在重新启用Gatekeeper？[默认: y] (y/n): " -r reenable_choice
            case $reenable_choice in
                [Nn]*)
                    echo ""
                    echo -e "${YELLOW}📝 记住稍后手动启用：${NC}"
                    echo -e "   ${BLUE}sudo spctl --master-enable${NC}"
                    echo ""
                    break
                    ;;
                [Yy]*|"")
                    echo ""
                    echo -e "${BLUE}正在重新启用Gatekeeper...${NC}"
                    if sudo spctl --master-enable 2>/dev/null; then
                        echo -e "${GREEN}✅ Gatekeeper已重新启用${NC}"
                        echo -e "${GREEN}🔒 系统安全性已恢复${NC}"
                    else
                        echo -e "${RED}❌ 重新启用失败，可能需要管理员权限${NC}"
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
    fi
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
    
    # 检查Gatekeeper状态
    check_gatekeeper_status
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
    local page_size=10
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
        echo -e "${BLUE}║                    📦 选择要安装的软件包                     ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}💡 使用方向键 ↑↓ 移动光标，空格键 ␣ 切换选择，回车键 ⏎ 确认${NC}"
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
                status_icon="${GREEN}✓${NC}"
            else
                status_icon="${RED}✗${NC}"
            fi
            
            # 光标位置高亮
            if [ $i -eq $cursor ]; then
                prefix="${BLUE}► ${NC}"
                suffix="${BLUE} ◄${NC}"
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
    find "$LOCAL_INSTALLERS_DIR" -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" > "$temp_file"
    
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

# 创建临时目录
setup_temp_dir() {
    log "创建临时目录..."
    mkdir -p "$TEMP_DIR/installers"
    cd "$TEMP_DIR"
}

# 创建安装脚本
create_install_script() {
    log "创建安装脚本..."
    
    # 直接使用内置脚本（不再尝试网络下载）
    create_embedded_install_script
    chmod +x install.sh
}

# 创建内置的安装脚本
create_embedded_install_script() {
    cat > install.sh << 'EOF'
#!/bin/bash

# 内置的安装脚本
set -e
set -o pipefail

cd "$(dirname "$0")"
INSTALLERS_DIR="./installers"
APPLICATIONS_DIR="/Applications"

echo "🚀 开始自动化配置新的 Mac..."
echo "========================================"

if [ ! -d "$INSTALLERS_DIR" ]; then
  echo "❌ 错误：未找到 'installers' 目录。"
  exit 1
fi

# sudo权限已在bootstrap.sh中验证

for installer_path in "$INSTALLERS_DIR"/*; do
  [ -e "$installer_path" ] || continue
  
  filename=$(basename "$installer_path")
  extension="${filename##*.}"
  
  echo ""
  echo "----------------------------------------"
  echo "⚙️  正在处理: $filename"
  echo "----------------------------------------"
  
  case "$extension" in
    "dmg")
      echo "  [类型: DMG] - 移除隔离属性..."
      sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
      echo "  [类型: DMG] - 正在挂载..."
      HDIUTIL_OUTPUT=$(sudo hdiutil attach "$installer_path" -nobrowse -owners on 2>&1)
      HDIUTIL_EXIT_CODE=$?
      
      if [ $HDIUTIL_EXIT_CODE -ne 0 ]; then
        echo "  ❌ 挂载失败: $filename"
        continue
      fi
      
      MOUNT_POINT=$(echo "$HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
      
      if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
        echo "  ❌ 无法确定挂载点: $filename"
        continue
      fi
      
      echo "  ✅ 已挂载到: $MOUNT_POINT"
      
      # 显示DMG内容以便调试
      echo "  📁 DMG内容："
      ls -la "$MOUNT_POINT" 2>/dev/null | head -10
      echo ""
      
      # 首先检查是否有PKG文件（优先处理安装器）
      echo "  🔍 查找 PKG 安装包..."
      echo "  [调试] 挂载点: $MOUNT_POINT"
      
      # 使用更可靠的方法查找PKG文件
      PKG_PATH=""
      # 方法1: 直接ls查找
      if [ -z "$PKG_PATH" ]; then
        PKG_PATH=$(ls "$MOUNT_POINT"/*.pkg 2>/dev/null | head -1)
        echo "  [调试] 方法1(ls): $PKG_PATH"
      fi
      # 方法2: 简化的find命令作为备用
      if [ -z "$PKG_PATH" ]; then
        PKG_PATH=$(find "$MOUNT_POINT" -name "*.pkg" 2>/dev/null | head -1)
        echo "  [调试] 方法2(find): $PKG_PATH"
      fi
      echo "  [调试] 最终PKG_PATH: $PKG_PATH"
      
      if [ -n "$PKG_PATH" ]; then
        # DMG包含PKG安装包
        PKG_NAME=$(basename "$PKG_PATH")
        echo "  📦 发现PKG安装包: $PKG_NAME"
        echo "  📦 正在安装PKG..."
        echo "  [调试] 执行命令: sudo installer -pkg \"$PKG_PATH\" -target /"
        
        if sudo installer -pkg "$PKG_PATH" -target /; then
          echo "  ✅ PKG安装成功。"
        else
          echo "  ❌ PKG安装失败。"
        fi
        echo "  [调试] PKG安装命令执行完成"
      else
        # 没有PKG文件，查找.app文件
        echo "  🔍 查找 .app 文件..."
        APP_PATH=$(find "$MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
        
        if [ -n "$APP_PATH" ]; then
          # 常规DMG包含.app文件
          APP_NAME=$(basename "$APP_PATH")
          TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
          echo "  ✅ 找到应用: $APP_NAME"
          
          if [ -d "$TARGET_APP_PATH" ]; then
            echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
          else
            echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
            sudo cp -R "$APP_PATH" "$APPLICATIONS_DIR/"
            echo "  ✅ 拷贝完成。"
            
            # 移除应用的隔离属性
            echo "  正在移除应用的隔离属性..."
            sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
            echo "  ✅ 隔离属性移除完成。"
          fi
        else
          echo "  ❌ 未找到 .app 文件"
          # 检查是否是TNT团队的特殊结构
          echo "  🔍 检查TNT特殊结构..."
          
          # 首先查找Manual install目录
          MANUAL_INSTALL_DIR=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*" -type d 2>/dev/null | head -1)
          
          if [ -n "$MANUAL_INSTALL_DIR" ]; then
            echo "  🎯 发现TNT结构，找到Manual install目录: $(basename "$MANUAL_INSTALL_DIR")"
            
            # 在Manual install目录中查找DMG文件
            MANUAL_INSTALL_DMG=$(find "$MANUAL_INSTALL_DIR" -name "*.dmg" 2>/dev/null | head -1)
            
            if [ -n "$MANUAL_INSTALL_DMG" ]; then
              echo "  📦 在Manual install目录中找到DMG: $(basename "$MANUAL_INSTALL_DMG")"
              echo "  📦 正在挂载嵌套DMG..."
              
              # 挂载嵌套的DMG
              NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -owners on 2>&1)
              NESTED_HDIUTIL_EXIT_CODE=$?
              
              if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
                echo "  ❌ 嵌套DMG挂载失败"
              else
                NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
                
                if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                  echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
                  
                  # 在嵌套DMG中查找.app文件
                  NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                  
                  if [ -n "$NESTED_APP_PATH" ]; then
                    APP_NAME=$(basename "$NESTED_APP_PATH")
                    TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                    echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                    
                    if [ -d "$TARGET_APP_PATH" ]; then
                      echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                    else
                      echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                      sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                      echo "  ✅ 拷贝完成。"
                    fi
                  else
                    echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                fi
                
                # 推出嵌套DMG
                echo "  正在推出嵌套DMG: $(basename "$MANUAL_INSTALL_DMG")..."
                sleep 1
                if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                  echo "  ✅ 嵌套DMG推出完成。"
                else
                  sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                  echo "  ✅ 嵌套DMG强制推出完成。"
                fi
              else
                echo "  ❌ 无法确定嵌套DMG挂载点"
              fi
            fi
            else
              echo "  🔍 Manual install目录中未找到DMG文件，直接查找.app文件..."
              # 直接在Manual install目录中查找.app文件
              MANUAL_APP_PATH=$(find "$MANUAL_INSTALL_DIR" -name "*.app" -maxdepth 3 -print -quit)
              
              if [ -n "$MANUAL_APP_PATH" ]; then
                APP_NAME=$(basename "$MANUAL_APP_PATH")
                TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                echo "  🔍 在Manual install目录中找到应用: $APP_NAME"
                
                if [ -d "$TARGET_APP_PATH" ]; then
                  echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                else
                  echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                  sudo cp -R "$MANUAL_APP_PATH" "$APPLICATIONS_DIR/"
                  echo "  ✅ 拷贝完成。"
                fi
              else
                echo "  ❌ 在Manual install目录中也未找到 .app 文件。"
              fi
            fi
          else
            # 查找直接的嵌套DMG文件（作为备用方案）
            MANUAL_INSTALL_DMG=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*.dmg" -o -name "*[Mm]anual*.dmg" -o -name "*install*.dmg" 2>/dev/null | head -1)
          
            if [ -n "$MANUAL_INSTALL_DMG" ]; then
              echo "  🎯 发现嵌套DMG文件: $(basename "$MANUAL_INSTALL_DMG")"
              echo "  📦 正在挂载嵌套DMG..."
              
              # 挂载嵌套的DMG
              NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -owners on 2>&1)
              NESTED_HDIUTIL_EXIT_CODE=$?
              
              if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
                echo "  ❌ 嵌套DMG挂载失败"
              else
                NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
                
                if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                  echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
                  
                  # 在嵌套DMG中查找.app文件
                  NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                  
                  if [ -n "$NESTED_APP_PATH" ]; then
                    APP_NAME=$(basename "$NESTED_APP_PATH")
                    TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                    echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                    
                    if [ -d "$TARGET_APP_PATH" ]; then
                      echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                    else
                      echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                      sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                      echo "  ✅ 拷贝完成。"
                  fi
                else
                  echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                fi
                
                  # 推出嵌套DMG
                  echo "  正在推出嵌套DMG: $(basename "$MANUAL_INSTALL_DMG")..."
                  sleep 1
                  if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                    echo "  ✅ 嵌套DMG推出完成。"
                  else
                    sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                    echo "  ✅ 嵌套DMG强制推出完成。"
                  fi
                else
                  echo "  ❌ 无法确定嵌套DMG挂载点"
                fi
              fi
            else
              echo "  ❌ 在DMG中未找到 .app 文件、Manual install目录或嵌套DMG文件。"
              echo "  📁 DMG内容列表："
              ls -la "$MOUNT_POINT" | head -10
            fi
          fi
        fi
      fi
      
      echo "  正在推出DMG: $filename..."
      sleep 1
      if sudo hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        echo "  ✅ DMG推出完成。"
      else
        sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null || true
        echo "  ✅ DMG强制推出完成。"
      fi
      ;;
      
    "pkg")
      echo "  [类型: PKG] - 准备安装..."
      sudo installer -pkg "$installer_path" -target /
      echo "  ✅ PKG 安装成功。"
      ;;
      
    "zip")
      echo "  [类型: ZIP] - 移除隔离属性..."
      sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
      echo "  [类型: ZIP] - 正在解压..."
      unzip -q "$installer_path" -d temp_extract
      
      # 在解压后的内容中移除隔离属性
      sudo xattr -r -d com.apple.quarantine temp_extract 2>/dev/null || true
      
      # 查找 .app 文件（支持更深层次搜索）
      APP_PATH=$(find temp_extract -name "*.app" -maxdepth 5 -print -quit)
      
      if [ -n "$APP_PATH" ]; then
        APP_NAME=$(basename "$APP_PATH")
        TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
        echo "  🔍 找到应用: $APP_NAME"
        
        if [ -d "$TARGET_APP_PATH" ]; then
          echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
        else
          echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
          sudo cp -R "$APP_PATH" "$APPLICATIONS_DIR/"
          echo "  ✅ 拷贝完成。"
          
          # 移除应用的隔离属性
          echo "  正在移除应用的隔离属性..."
          sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
          echo "  ✅ 隔离属性移除完成。"
        fi
      else
        # 检查是否有嵌套的ZIP或DMG文件
        echo "  🔍 未找到 .app 文件，检查嵌套结构..."
        
        NESTED_ZIP=$(find temp_extract -name "*.zip" | head -1)
        NESTED_DMG=$(find temp_extract -name "*.dmg" | head -1)
        NESTED_PKG=$(find temp_extract -name "*.pkg" | head -1)
        
        if [ -n "$NESTED_ZIP" ]; then
          echo "  📦 发现嵌套ZIP: $(basename "$NESTED_ZIP")"
          echo "  📦 正在解压嵌套ZIP..."
          unzip -q "$NESTED_ZIP" -d temp_extract/nested
          
          NESTED_APP_PATH=$(find temp_extract/nested -name "*.app" -maxdepth 3 -print -quit)
          if [ -n "$NESTED_APP_PATH" ]; then
            APP_NAME=$(basename "$NESTED_APP_PATH")
            TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
            echo "  🔍 在嵌套ZIP中找到应用: $APP_NAME"
            
            if [ -d "$TARGET_APP_PATH" ]; then
              echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
            else
              echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
              sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
              echo "  ✅ 拷贝完成。"
            fi
          else
            echo "  ❌ 在嵌套ZIP中也未找到 .app 文件。"
          fi
        elif [ -n "$NESTED_DMG" ]; then
          echo "  📦 发现嵌套DMG: $(basename "$NESTED_DMG")"
          echo "  📦 正在挂载嵌套DMG..."
          
          # 移除嵌套DMG的隔离属性
          sudo xattr -r -d com.apple.quarantine "$NESTED_DMG" 2>/dev/null || true
          
          NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$NESTED_DMG" -nobrowse -owners on 2>&1)
          NESTED_HDIUTIL_EXIT_CODE=$?
          
          if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
            echo "  ❌ 嵌套DMG挂载失败"
          else
            NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
            
            if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
              echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
              
              NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit)
              
              if [ -n "$NESTED_APP_PATH" ]; then
                APP_NAME=$(basename "$NESTED_APP_PATH")
                TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                
                if [ -d "$TARGET_APP_PATH" ]; then
                  echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                else
                  echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                  sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                  echo "  ✅ 拷贝完成。"
                fi
              else
                echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
              fi
              
              # 推出嵌套DMG
              echo "  正在推出嵌套DMG: $(basename "$NESTED_DMG")..."
              sleep 1
              if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                echo "  ✅ 嵌套DMG推出完成。"
              else
                sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                echo "  ✅ 嵌套DMG强制推出完成。"
              fi
            else
              echo "  ❌ 无法确定嵌套DMG挂载点"
            fi
          fi
        elif [ -n "$NESTED_PKG" ]; then
          echo "  📦 发现PKG: $(basename "$NESTED_PKG")"
          echo "  📦 正在安装PKG..."
          sudo installer -pkg "$NESTED_PKG" -target /
          echo "  ✅ PKG安装成功。"
        else
          echo "  ❌ 在ZIP中未找到 .app 文件或嵌套文件。"
          echo "  📁 ZIP内容列表："
          find temp_extract -type f | head -10
        fi
      fi
      
      rm -rf temp_extract
      ;;
      
    "app")
      echo "  [类型: APP] - 直接安装应用..."
      APP_NAME=$(basename "$installer_path")
      TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
      
      if [ -d "$TARGET_APP_PATH" ]; then
        echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
      else
        echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
        sudo cp -R "$installer_path" "$APPLICATIONS_DIR/"
        echo "  ✅ 拷贝完成。"
        
        # 移除应用的隔离属性
        echo "  正在移除应用的隔离属性..."
        sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
        echo "  ✅ 隔离属性移除完成。"
      fi
      ;;
      
    *)
      echo "  🟡 [类型: $extension] - 跳过，不支持的文件类型。"
      ;;
  esac
done

echo ""
echo "========================================"
echo "✅ 所有软件安装任务已执行完毕！"
echo "========================================"
EOF
}

# 处理本地安装包
handle_local_packages() {
    
    log "复制本地安装包到工作目录..."
    
    for file in "${selected_local_files[@]}"; do
        local filename=$(basename "$file")
        local extension="${filename##*.}"
        info "复制 $filename"
        
        # .app文件是目录，需要递归复制
        if [ "$extension" = "app" ]; then
            if cp -R "$file" "installers/$filename"; then
                log "✅ $filename 复制完成"
            else
                warn "❌ $filename 复制失败"
            fi
        else
            if cp "$file" "installers/$filename"; then
                log "✅ $filename 复制完成"
            else
                warn "❌ $filename 复制失败"
            fi
        fi
    done
}

# 处理选中的软件包
process_packages() {
    handle_local_packages
}

# 执行安装
run_installation() {
    log "开始执行安装..."
    
    # 提前验证sudo权限
    echo ""
    info "此脚本需要管理员权限来安装软件包和推出DMG文件。"
    if ! sudo -v; then
        error "无法获取管理员权限，安装终止"
        exit 1
    fi
    
    # 保持sudo权限有效
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    
    if [[ -f "install.sh" ]]; then
        bash install.sh
    else
        error "安装脚本不存在"
        exit 1
    fi
}

# 清理临时文件
cleanup() {
    log "清理临时文件..."
    cd /
    rm -rf "$TEMP_DIR"
    log "清理完成"
}

# 显示使用帮助
show_help() {
    echo "用法: $0 [选项] <安装包目录>"
    echo ""
    echo "选项："
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "参数："
    echo "  安装包目录     包含 .dmg/.pkg/.zip 文件的目录路径（必需）"
    echo ""
    echo "功能："
    echo "  • 🎯 交互式选择界面，默认全选所有软件包"
    echo "  • ⌨️  方向键 ↑↓ 移动光标，空格键切换选择状态"
    echo "  • 🔄 Ctrl+A 全选，Ctrl+N 全不选"
    echo "  • ✅ 支持 .dmg、.pkg、.zip、.app 格式"
    echo "  • 🔍 智能检测TNT团队软件包（嵌套DMG结构）"
    echo "  • 📁 递归遍历子目录中的安装包"
    echo "  • 🔐 自动移除应用的隔离属性（quarantine）"
    echo "  • 📦 支持ZIP中的PKG安装包"
    echo "  • 🚀 自动安装所有选中的软件包"
    echo ""
    echo "示例："
    echo "  $0 /Users/fiber/dev/install_workflow/installers"
    echo "  $0 ~/Downloads/mac_apps"
    echo "  $0 /path/to/your/software/packages"
    echo ""
}

# 主函数
main() {
    # 解析参数
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    parse_arguments "$@"
    show_welcome
    check_requirements
    setup_temp_dir
    show_package_menu
    create_install_script
    process_packages
    run_installation
    cleanup
    
    echo ""
    log "🎉 Mac 配置完成！享受您的新环境吧！"
    echo ""
    
    # 检查是否需要提醒重新启用Gatekeeper
    final_gatekeeper_check
    echo ""
}

# 错误处理
trap cleanup EXIT

# 运行主函数
main "$@"