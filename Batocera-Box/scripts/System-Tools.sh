#!/bin/bash
# ============================================================
# Batocera Box — System Tools
# ============================================================
export NCURSES_NO_UTF8_ACS=1
export TERM="${TERM:-xterm}"

BACKTITLE="Batocera Box | System Tools"

# ================================================================
#  HELPERS
# ================================================================

function get_sysinfo() {
    local arch version ip uptime disk_roms disk_bios temp

    arch=$(batocera-es-swissknife --arch 2>/dev/null || echo "unknown")
    version=$(batocera-es-swissknife --version 2>/dev/null || echo "unknown")
    ip=$(ip -4 addr show | grep -o 'inet [0-9.]*' | awk '{print $2}' | grep -v '^127' | head -1)
    [ -z "$ip" ] && ip="(not connected)"

    # Uptime
    local up_sec
    up_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
    uptime=$(printf "%dd %02dh %02dm" $((up_sec/86400)) $(( (up_sec%86400)/3600 )) $(( (up_sec%3600)/60 )) )

    # Disk
    disk_roms=$(df -h /userdata 2>/dev/null | awk 'NR==2 {print $4 " free / " $2 " total (" $5 " used)"}')
    disk_bios=$(du -sh /userdata/bios 2>/dev/null | cut -f1)
    [ -z "$disk_bios" ] && disk_bios="0"

    # CPU temp (RPi)
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp="${temp_raw:0:-3}.${temp_raw: -3:1}°C"
    else
        temp="N/A"
    fi

    echo "Architecture  : $arch"
    echo "Batocera ver  : $version"
    echo "Uptime        : $uptime"
    echo "IP address    : $ip"
    echo ""
    echo "Disk (/userdata): $disk_roms"
    echo "BIOS size       : $disk_bios"
    echo "CPU temp        : $temp"
}

function show_rom_sizes() {
    local info
    info=$(du -sh /userdata/roms/*/ 2>/dev/null | sort -rh | head -30 \
        || echo "No ROM folders found.")
    dialog --title "ROM Folder Sizes" \
        --msgbox "$info" 30 55
}

function restart_es() {
    dialog --title "Restart EmulationStation" \
        --yesno "Restart EmulationStation now?\n\nThis will re-scan all ROM folders and update gamelists." \
        8 55 || return

    dialog --title "Restarting..." --infobox "\nRestarting EmulationStation...\nThis window will close.\n" 6 40
    sleep 1
    batocera-es-swissknife --restart
}

function reboot_system() {
    dialog --title "Reboot" \
        --yesno "Reboot Batocera now?" 6 35 || return

    dialog --title "Rebooting..." --infobox "\nRebooting system...\n" 5 30
    sleep 1
    batocera-es-swissknife --reboot
}

function shutdown_system() {
    dialog --title "Shutdown" \
        --yesno "Shut down Batocera now?" 6 35 || return

    dialog --title "Shutting down..." --infobox "\nShutting down...\n" 5 30
    sleep 1
    batocera-es-swissknife --shutdown
}

function update_gamelists() {
    dialog --title "Update Gamelists" \
        --yesno "Restart EmulationStation to apply any new ROMs?\n\n(This is the same as: START → Game Settings → Update Gamelists)" \
        9 60 || return

    batocera-es-swissknife --restart
}

function network_info() {
    local info
    info=$(ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Network info unavailable.")
    dialog --title "Network Info" --msgbox "$info" 22 68
}

# ================================================================
#  MAIN SYSTEM TOOLS MENU
# ================================================================

function system_tools_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --backtitle "$BACKTITLE" \
            --title " SYSTEM TOOLS " \
            --ok-label "Select" --cancel-label "Back" \
            --menu "Select a tool" 20 58 9 \
            1 "System Info" \
            2 "ROM Folder Sizes" \
            3 "Network Info" \
            4 "Update Gamelists (restart ES)" \
            5 "Restart EmulationStation" \
            6 "Reboot" \
            7 "Shutdown" \
            2>&1 >/dev/tty)

        case "$choice" in
            1)
                local info
                info=$(get_sysinfo)
                dialog --title "System Information" --msgbox "$info" 16 58
                ;;
            2) show_rom_sizes    ;;
            3) network_info      ;;
            4) update_gamelists  ;;
            5) restart_es        ;;
            6) reboot_system     ;;
            7) shutdown_system   ;;
            *) break ;;
        esac
    done
}

# ---- Entry point ----
system_tools_menu
