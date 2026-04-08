#!/bin/bash
# ============================================================
# Batocera Box — BIOS Downloader
#
# BIOS files are legally required to be provided by the user.
# This script downloads from the same archive.org source as
# the original Devils-Box. Only use BIOS files you are legally
# entitled to possess.
# ============================================================
export NCURSES_NO_UTF8_ACS=1
export TERM="${TERM:-xterm}"

BACKTITLE="Batocera Box | BIOS Files"
HOST_BIOS="https://archive.org/download/devils-bios"
BIOS_DIR="/userdata/bios"

function bios_disclaimer() {
    dialog --title "BIOS Files — Legal Notice" \
        --yesno \
"BIOS files are copyrighted firmware owned by hardware manufacturers.

This tool downloads from a publicly shared archive.org collection.
Only proceed if you legally own the original hardware.

Batocera stores BIOS files in:
  /userdata/bios/

You can check which BIOS files are missing or required via:
  MAIN MENU → System Settings → Missing BIOS

Download BIOS files now?" \
        15 62
}

function download_all_bios() {
    local dest="$BIOS_DIR"
    mkdir -p "$dest"

    dialog --title "Downloading BIOS Files" --infobox \
        "\nDownloading all BIOS files from archive.org...\n\nDestination: $dest\n\nThis may take several minutes." \
        9 60

    wget -q -m -r -np -nH -nd -R "index.html" \
        "${HOST_BIOS}/BIOS/" \
        -P "$dest" \
        -erobots=off 2>/dev/null

    rm -f "$dest/index.html.tmp" "$dest/index.html"

    dialog --title "Done" --msgbox \
        "BIOS download complete!\n\nFiles saved to: $dest\n\nTo verify which BIOS files Batocera still needs:\n  MAIN MENU → System Settings → Missing BIOS" \
        11 58
}

function bios_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --backtitle "$BACKTITLE" \
            --title " BIOS FILES " \
            --ok-label "Select" --cancel-label "Back" \
            --menu "Batocera BIOS location: /userdata/bios/" 16 60 5 \
            1 "Download all BIOS files" \
            2 "Show what is in /userdata/bios/" \
            3 "Check missing BIOS (Batocera tool)" \
            2>&1 >/dev/tty)

        case "$choice" in
            1)
                bios_disclaimer && download_all_bios
                ;;
            2)
                local files
                files=$(ls /userdata/bios/ 2>/dev/null | head -40 \
                    || echo "(folder is empty or does not exist)")
                dialog --title "/userdata/bios/ contents" \
                    --msgbox "$files" 22 62
                ;;
            3)
                dialog --title "Check Missing BIOS" --msgbox \
                    "Open EmulationStation and go to:\n\n  MAIN MENU → System Settings → Missing BIOS\n\nThis will list all BIOS files required by each system,\ntheir expected filenames, and their MD5 checksums." \
                    11 60
                ;;
            *)
                break
                ;;
        esac
    done
}

# ---- Entry point ----
bios_menu
