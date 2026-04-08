#!/bin/bash
# ============================================================
# Batocera Box — Main Menu
# ============================================================
export NCURSES_NO_UTF8_ACS=1
export TERM="${TERM:-xterm}"

BB_DIR="/userdata/system/batocera-box"
BB_SETTINGS="$BB_DIR/.bb_settings.ini"
BACKTITLE="Batocera Box  |  /userdata/roms/  |  ssh root@batocera.local"

# ---- Network check (use full paths — ES runs with a minimal PATH) ----
OFFLINE=1
if /usr/bin/curl -s --head --max-time 5 https://archive.org -o /dev/null 2>/dev/null; then
    OFFLINE=0
elif /usr/bin/wget -q --spider --timeout=5 https://archive.org 2>/dev/null; then
    OFFLINE=0
fi

# ---- Guard: ensure installed ----
if [ ! -d "$BB_DIR" ]; then
    dialog --title "Not Installed" \
        --msgbox "Batocera Box is not installed.\nRun BB-Install.sh first." 7 50
    exit 1
fi

# ================================================================
#  HELPERS
# ================================================================

function offline_warning() {
    dialog --title "No Internet" \
        --msgbox "Cannot reach archive.org.\nConnect to the internet and try again." 7 52
}

function gamelist_hint() {
    dialog --title "Downloads Complete" \
        --msgbox "Done!\n\nTo make new games appear in EmulationStation:\n  START → Game Settings → Update Gamelists\n\nor use System Tools → Restart EmulationStation." \
        10 58
}

# ================================================================
#  MAIN MENU
# ================================================================

function main_menu() {
    local choice

    while true; do
        choice=$(dialog \
            --backtitle "$BACKTITLE" \
            --title " BATOCERA BOX " \
            --ok-label "Select" --cancel-label "Exit" \
            --menu "What would you like to do?" 18 58 7 \
            1 "Game Packs  — full console collections" \
            2 "Pick & Choose  — individual games" \
            3 "BIOS Files  — required files for some emulators" \
            4 "System Tools  — restart ES, disk info, reboot" \
            5 "About" \
            2>&1 >/dev/tty)

        case "$choice" in
            1) if [ "$OFFLINE" -eq 1 ]; then offline_warning; else bash "$BB_DIR/scripts/Game-Packs.sh"; fi ;;
            2) if [ "$OFFLINE" -eq 1 ]; then offline_warning; else bash "$BB_DIR/scripts/Pick-N-Choose.sh"; fi ;;
            3) if [ "$OFFLINE" -eq 1 ]; then offline_warning; else bash "$BB_DIR/scripts/BIOS.sh"; fi ;;
            4) bash "$BB_DIR/scripts/System-Tools.sh" ;;
            5) about ;;
            *) break ;;
        esac
    done
}

function about() {
    local arch version
    arch=$(batocera-es-swissknife --arch 2>/dev/null || echo "unknown")
    version=$(batocera-es-swissknife --version 2>/dev/null || echo "unknown")
    local disk_free
    disk_free=$(df -h /userdata | awk 'NR==2 {print $4 " free of " $2}')

    dialog --title "About Batocera Box" --msgbox \
"Batocera Box — The Batocera Toolbox
Based on Devils-Box by The Retro Devils

Architecture : $arch
Version      : $version
Free space   : $disk_free

ROM folder   : /userdata/roms/
BIOS folder  : /userdata/bios/
Tool folder  : /userdata/system/batocera-box/

Downloads from: archive.org (Devils-Box collections)
For personal backup use only." \
    18 58
}

# ================================================================
#  ENTRY POINT
# ================================================================
main_menu
