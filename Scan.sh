#!/system/bin/sh
clear
echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
cat << "EOF"
   ██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗     ██████╗  ██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ 
   ██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██║████╗  ██║██╔════╝    ██╔══██╗██╔═══██╗████╗ ████║██║████╗  ██║██╔══██╗
   ███████║██║   ██║██║   ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗   ██║  ██║██║   ██║██╔████╔██║██║██╔██╗ ██║███████║
   ██╔══██║██║   ██║██║   ██║██╔═██╗ ██║██║╚██╗██║██║   ██║   ██║  ██║██║   ██║██║╚██╔╝██║██║██║╚██╗██║██╔══██║
   ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗██║██║ ╚████║╚██████╔╝   ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║██║ ╚████║██║  ██║
   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
echo "                           https://discord.gg/hooking"
echo "                  Versão 2.2 - Rápida e Compatível com Android"
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""

PKG_NORMAL="com.dts.freefireth"
PKG_MAX="com.dts.freefiremax"
BASE_STORAGE="/storage/emulated/0"
SCAN_DIR="$BASE_STORAGE/Download/HookScan"
MAIN_DIR="$BASE_STORAGE/Hooking Scan"
WO_FILE="$SCAN_DIR/wo_reasons.txt"

mkdir -p "$SCAN_DIR" "$MAIN_DIR" 2>/dev/null
: > "$WO_FILE"

add_wo() {
    echo "$1" >> "$WO_FILE"
}

print_header() {
    echo ""
    echo "                   $1"
    echo "══════════════════════════════════════════════════════════════════════════════"
}

get_pkg_version() {
    dumpsys package "$1" 2>/dev/null | grep -m1 "versionName=" | cut -d= -f2 | tr -d ' '
}

get_installer() {
    pm list packages -i "$1" 2>/dev/null | sed -n 's/.*installer=\(.*\)/\1/p' | head -1
}

is_package_installed() {
    pm list packages 2>/dev/null | grep -q "^package:$1$"
}

check_file_info() {
    path="$1"
    name="$2"
    if [ -e "$path" ]; then
        echo "   📄 $name:"
        stat "$path" 2>/dev/null | grep -E 'Access|Modify|Change|Size|Birth' | sed 's/^/      /'
        echo "      Tamanho: $(du -h "$path" 2>/dev/null | awk '{print $1}')"
        return 0
    else
        echo "   📄 $name: ❌ Não encontrado"
        return 1
    fi
}

check_obb() {
    pkg="$1"
    game="$2"
    obb_dir="$BASE_STORAGE/Android/obb/$pkg"

    echo "   📦 OBB ($game):"

    if [ ! -d "$obb_dir" ]; then
        echo "      ❌ Pasta OBB não encontrada"
        return
    fi

    obb_file=$(find "$obb_dir" -maxdepth 1 -type f -name "*.obb" 2>/dev/null | head -1)

    if [ -z "$obb_file" ]; then
        echo "      ❌ Nenhum arquivo .obb encontrado"
        return
    fi

    size_mb=$(du -m "$obb_file" 2>/dev/null | awk '{print $1}')
    size_h=$(du -h "$obb_file" 2>/dev/null | awk '{print $1}')

    echo "      Arquivo: $(basename "$obb_file")"
    echo "      Tamanho: $size_h ($size_mb MB)"

    if [ "$size_mb" -ge 800 ]; then
        echo "      Status: ✅ INTEGRIDADE OK (tamanho normal)"
    elif [ "$size_mb" -ge 300 ]; then
        echo "      Status: ⚠️  SUSPEITO (tamanho intermediário)"
        add_wo "OBB $game com tamanho suspeito (${size_mb}MB)"
    else
        echo "      Status: ❌ POSSIVELMENTE CORROMPIDO / MODIFICADO"
        add_wo "OBB $game possivelmente corrompido (${size_mb}MB)"
    fi
}

detect_shell_in_file() {
    file="$1"
    tipo="$2"
    if [ -f "$file" ]; then
        if strings "$file" 2>/dev/null | grep -qiE "shell|frida|xposed|lsposed|magisk|zygisk|inject"; then
            echo "      ⚠️  Strings suspeitas encontradas no $tipo"
            add_wo "Strings suspeitas em $tipo"
        else
            echo "      ✅ Nenhuma string suspeita óbvia no $tipo"
        fi
    fi
}

check_proxy() {
    pkg="$1"
    nome="$2"
    if pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
        installer=$(get_installer "$pkg")
        echo "⚠️  $nome: INSTALADO!"
        echo "   Instalador: ${installer:-Desconhecido}"
        echo "   ❌ ALERTA: PROXY / APP FALSO DETECTADO"
        add_wo "Proxy detectado: $nome"
    else
        echo "✅ $nome: Não instalado"
    fi
}

check_proxy_version() {
    pkg="$1"
    nome="$2"
    version_proxy="$3"
    if pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
        current=$(get_pkg_version "$pkg")
        if [ "$current" = "$version_proxy" ]; then
            echo "⚠️  $nome: INSTALADO (versão proxy: $current)"
            echo "   ❌ ALERTA: PROXY DETECTADO POR VERSÃO"
            add_wo "Proxy por versão: $nome ($current)"
        else
            echo "✅ $nome: Original (versão: $current)"
        fi
    else
        echo "✅ $nome: Não instalado"
    fi
}

print_header "📱 INFORMAÇÕES DO DISPOSITIVO"
echo "Modelo     : $(getprop ro.product.model 2>/dev/null || echo 'Desconhecido')"
echo "Android    : $(getprop ro.build.version.release 2>/dev/null || echo 'Desconhecido')"
echo "SDK        : $(getprop ro.build.version.sdk 2>/dev/null || echo 'Desconhecido')"

if command -v su >/dev/null 2>&1; then
    echo "Root       : ✅ SIM (su encontrado)"
    add_wo "Root detectado (su)"
else
    echo "Root       : ❌ Não"
fi

print_header "🔒 VERIFIED BOOT"
vb=$(getprop ro.boot.verifiedbootstate 2>/dev/null)
echo "Verified Boot : ${vb:-Desconhecido}"
if [ "$vb" = "orange" ] || [ "$vb" = "yellow" ]; then
    echo "⚠️  Bootloader desbloqueado / estado não verde"
    add_wo "Verified Boot não verde ($vb)"
fi

print_header "🔍 DETECÇÃO ADB / REDE"
adb_port=$(getprop service.adb.tcp.port 2>/dev/null)
if [ -n "$adb_port" ] && [ "$adb_port" != "-1" ] && [ "$adb_port" != "0" ]; then
    echo "❌ ADB TCP/IP: ATIVADO → Porta: $adb_port"
    add_wo "ADB TCP/IP ativado (porta $adb_port)"
else
    echo "✅ ADB TCP/IP: Desativado"
fi

if command -v ss >/dev/null 2>&1; then
    PORT_CHECK=$(ss -tuln 2>/dev/null | grep -E ":5555[[:space:]]")
elif command -v netstat >/dev/null 2>&1; then
    PORT_CHECK=$(netstat -tuln 2>/dev/null | grep -E ":5555[[:space:]]")
else
    PORT_CHECK=""
fi

if [ -n "$PORT_CHECK" ]; then
    echo "❌ Porta 5555: ABERTA"
    add_wo "Porta 5555 aberta"
else
    echo "✅ Porta 5555: Fechada"
fi

adb_wifi=$(settings get global adb_wifi_enabled 2>/dev/null)
if [ "$adb_wifi" = "1" ]; then
    echo "❌ ADB Wi-Fi: Habilitado"
    add_wo "ADB Wi-Fi habilitado"
else
    echo "✅ ADB Wi-Fi: Desativado"
fi

if ps -A 2>/dev/null | grep -qiE "magisk|zygisk|kernelsu|superuser"; then
    echo "⚠️  Processos Root: Detectados"
    add_wo "Processos root (magisk/zygisk/kernelsu) em execução"
else
    echo "✅ Processos Root: Nenhum óbvio"
fi

print_header "🎮 FREE FIRE NORMAL"
if is_package_installed "$PKG_NORMAL"; then
    check_obb "$PKG_NORMAL" "Normal"

    echo "   🎨 SHADERS"
    latest_shader=$(find "$BASE_STORAGE/Android/data/$PKG_NORMAL/files/contentcache/Optional/android/gameassetbundles" -maxdepth 2 -name "shaders*" -type f 2>/dev/null | head -1)
    if [ -n "$latest_shader" ]; then
        check_file_info "$latest_shader" "SHADER NORMAL"
        detect_shell_in_file "$latest_shader" "SHADER NORMAL"
    else
        echo "   📄 SHADER: Não encontrado"
    fi

    echo "   🎥 REPLAYS"
    latest_bin=$(find "$BASE_STORAGE/Android/data/$PKG_NORMAL/files/MReplays" -maxdepth 1 -name "*.bin" -type f 2>/dev/null | head -1)
    if [ -n "$latest_bin" ]; then
        check_file_info "$latest_bin" "Replay .BIN"
        detect_shell_in_file "$latest_bin" "REPLAY BIN"
    fi

    latest_json=$(find "$BASE_STORAGE/Android/data/$PKG_NORMAL/files/MReplays" -maxdepth 1 -name "*.json" -type f 2>/dev/null | head -1)
    if [ -n "$latest_json" ]; then
        check_file_info "$latest_json" "Replay .JSON"
        detect_shell_in_file "$latest_json" "REPLAY JSON"
    fi

    echo "📌 Versão       : $(get_pkg_version $PKG_NORMAL || echo 'Não foi possível obter')"
    echo "📌 Instalado Via: $(get_installer $PKG_NORMAL || echo 'Desconhecido')"
else
    echo "   ❌ Free Fire Normal NÃO está instalado neste dispositivo"
fi

print_header "🎮 FREE FIRE MAX"
if is_package_installed "$PKG_MAX"; then
    check_obb "$PKG_MAX" "MAX"

    echo "   🎨 SHADERS"
    latest_shader_max=$(find "$BASE_STORAGE/Android/data/$PKG_MAX/files/contentcache/Optional/android/gameassetbundles" -maxdepth 2 -name "shaders*" -type f 2>/dev/null | head -1)
    if [ -n "$latest_shader_max" ]; then
        check_file_info "$latest_shader_max" "SHADER MAX"
        detect_shell_in_file "$latest_shader_max" "SHADER MAX"
    else
        echo "   📄 SHADER: Não encontrado"
    fi

    echo "   🎥 REPLAYS"
    latest_bin_max=$(find "$BASE_STORAGE/Android/data/$PKG_MAX/files/MReplays" -maxdepth 1 -name "*.bin" -type f 2>/dev/null | head -1)
    if [ -n "$latest_bin_max" ]; then
        check_file_info "$latest_bin_max" "Replay .BIN"
        detect_shell_in_file "$latest_bin_max" "REPLAY BIN"
    fi

    latest_json_max=$(find "$BASE_STORAGE/Android/data/$PKG_MAX/files/MReplays" -maxdepth 1 -name "*.json" -type f 2>/dev/null | head -1)
    if [ -n "$latest_json_max" ]; then
        check_file_info "$latest_json_max" "Replay .JSON"
        detect_shell_in_file "$latest_json_max" "REPLAY JSON"
    fi

    echo "📌 Versão       : $(get_pkg_version $PKG_MAX || echo 'Não foi possível obter')"
    echo "📌 Instalado Via: $(get_installer $PKG_MAX || echo 'Desconhecido')"
else
    echo "   ❌ Free Fire MAX NÃO está instalado neste dispositivo"
fi

print_header "🔍 DETECÇÃO DE RASTRO"
echo "Verificando termos suspeitos (versão rápida)..."

RASTRO_FILE="$SCAN_DIR/Rastros_Suspeitos.txt"
: > "$RASTRO_FILE"

find "$BASE_STORAGE/Download" "$BASE_STORAGE/Documents" "$BASE_STORAGE/DCIM" \
    -maxdepth 4 \
    -type f \( \
        -iname "*hack*" -o -iname "*cheat*" -o -iname "*modmenu*" -o -iname "*aimbot*" \
        -o -iname "*painel*" -o -iname "*holograma*" -o -iname "*passador*" -o -iname "*bypass*" \
        -o -iname "*wallhack*" -o -iname "*esp*" -o -iname "*inject*" -o -iname "*frida*" \
    \) 2>/dev/null | \
    grep -vE "(ui_tabicon|icon_avatar|icon_callsign|optionalab_|vendor\.samsung|hookingscan|rastros|ff_ui_character|animation|page\.hooks|BottomBar|\.cnt$|cache|thumbnail|\.tmp)" \
    > "$RASTRO_FILE"

if [ -s "$RASTRO_FILE" ]; then
    echo "   ⚠️  RASTROS ENCONTRADOS:"
    while IFS= read -r file; do
        filename=$(basename "$file")
        case "$filename" in
            *.apk|*.xapk|*.apks)
                echo "   ❌ $filename  →  🔥 ALTO RISCO (APK suspeito)"
                add_wo "APK suspeito encontrado: $filename"
                ;;
            *)
                echo "   ⚠️  $filename  →  Possível rastro"
                ;;
        esac
    done < "$RASTRO_FILE"
    echo "   Total: $(wc -l < "$RASTRO_FILE") arquivo(s)"
else
    echo "   ✅ Nenhum rastro óbvio encontrado nas pastas permitidas"
fi

print_header "🔎 PROXY / APPS FALSOS"
echo "--- Verificando aplicativos conhecidos de proxy ---"

check_proxy "com.nu.roxinho" "(Nubank Falso)"
check_proxy "com.netflix.mediaclientxx" "(Proxy NETFLIX)"
check_proxy "com.proxy.free" "(Proxy Free)"
check_proxy "com.dripclient.proxy" "(Drip Proxy)"
check_proxy "com.spotify.musicx" "(SPOTIFY PROXY)"
check_proxy "android.settings.com" "(PROXY BREVENT)"
check_proxy "com.mycompany.myapp" "(PROXY SHOPEE)"
check_proxy "com.android.sellestw" "(PROXY GOOGLE)"
check_proxy "io.gringoxp.proxy.garena.freefire" "(PROXY GRINGO XP)"
check_proxy "com.nvt.cc" "(PROXY MINHA CLARO)"
check_proxy "com.pornhub" "(PROXY MTH TEAM V3)"
check_proxy "com.proxyall" "(PROXY HG CHEATS)"
check_proxy "com.android.system.service.optimizer" "(PROXY TEMAS)"
check_proxy "com.mcdo.mcdonaldss" "(PROXY DO MCDONALDS)"
check_proxy "com.s" "(PROXY AUXÍLIO)"
check_proxy "client.by" "(PROXY EXTERNAL)"
check_proxy "com.lucasqueiroz.fitcal" "(PROXY MTH TEAM)"
check_proxy "com.snoopy.proxy" "(PROXY SNOOPY)"
check_proxy "com.snakeio" "(PROXY JOGO DA COBRINHA)"
check_proxy "com.bard" "(PROXY GEMINI)"
check_proxy_version "com.facebook.lite" "(PROXY FACEBOOK LITE)" "2.1"

print_header "🔍 APPS DE RISCO (Shizuku / MT Manager / KernelSU)"
if pm list packages 2>/dev/null | grep -q "moe.shizuku"; then
    echo "⚠️  Shizuku: Detectado"
    add_wo "Shizuku instalado"
else
    echo "✅ Shizuku: Não"
fi

if pm list packages 2>/dev/null | grep -q "bin.mt.plus"; then
    echo "⚠️  MT Manager: Detectado"
    add_wo "MT Manager instalado"
else
    echo "✅ MT Manager: Não"
fi

if pm list packages 2>/dev/null | grep -qiE "kernelsu|com.topjohnwu.magisk|me.weishu.kernelsu"; then
    echo "⚠️  KernelSU / Magisk Manager: Detectado"
    add_wo "KernelSU ou Magisk Manager instalado"
else
    echo "✅ KernelSU / Magisk Manager: Não"
fi

print_header "📋 GERANDO LOGS"
echo "   • net_watch.txt"
{
    logcat -v brief -b system -b events -d 2>/dev/null | grep -iE "wifi|dns|vpn|proxy|localhost|remote|tcp|udp"
    ss -tuna 2>/dev/null | grep -iE "LISTEN|ESTAB|127.0.0.1|0.0.0.0"
    ip addr 2>/dev/null
    ip route 2>/dev/null
    getprop 2>/dev/null | grep -iE "dns|wifi|vpn|proxy"
    dumpsys wifi 2>/dev/null | grep -iE "ip|dns|gateway|proxy|vpn"
} > "$BASE_STORAGE/Download/net_watch.txt" 2>/dev/null
echo "   ✅ net_watch.txt"

echo "   • logcat.txt (buffer completo)"
logcat -d -b all > "$BASE_STORAGE/Download/logcat.txt" 2>/dev/null
echo "   ✅ logcat.txt ($(du -h "$BASE_STORAGE/Download/logcat.txt" 2>/dev/null | awk '{print $1}'))"

echo "   • light_logs.txt"
{
    logcat -v brief -b system -b events -d 2>/dev/null | grep -iE "usb|mtp|adb|file|transfer"
    dumpsys usb 2>/dev/null
    dumpsys connectivity 2>/dev/null | grep -iE "usb|tether|rndis"
    getprop 2>/dev/null | grep -iE "usb|adb"
} > "$BASE_STORAGE/Download/light_logs.txt" 2>/dev/null
echo "   ✅ light_logs.txt"

echo "   • Hooking Dump..."
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
{
    dumpsys usb
    dumpsys battery
    dumpsys power
    uname -a
    dumpsys window
    dumpsys package
    dumpsys connectivity
    dumpsys diskstats
    dumpsys input
    dumpsys display
    dumpsys location
    dumpsys netstats
    dumpsys activity
    dumpsys batterystats
    dumpsys usagestats
    dumpsys cpuinfo
} > "$SCAN_DIR/full_dump_$TIMESTAMP.txt" 2>/dev/null
echo "   ✅ full_dump_$TIMESTAMP.txt gerado"

echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
if [ ! -s "$WO_FILE" ]; then
    echo "                   ✅ STATUS FINAL: LIMPO"
    echo "         Nenhuma irregularidade grave detectada."
else
    echo "                   ❌ STATUS FINAL: W.O / SUSPEITO"
    echo "              Motivos detectados:"
    while IFS= read -r reason; do
        echo "   • $reason"
    done < "$WO_FILE"
fi
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Logs salvos em:"
echo "  → $SCAN_DIR/"
echo "  → $BASE_STORAGE/Download/"
echo ""
echo "DEVELOPED BY GGF TEAM - FUCK CHEATERS"
echo "══════════════════════════════════════════════════════════════════════════════"
