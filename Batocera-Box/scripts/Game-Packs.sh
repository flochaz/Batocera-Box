#!/bin/bash
# ============================================================
# Batocera Box — Game Packs (full console collections)
# Downloads from archive.org Devils-Box collections.
#
# Mapping note: archive.org folder name may differ from the
# Batocera system folder name. The download_pack function
# takes both: download_pack  <archive-folder>  <batocera-system>
# ============================================================
export NCURSES_NO_UTF8_ACS=1
export TERM="${TERM:-xterm}"

BACKTITLE="Batocera Box | Game Packs"

# ---- Archive.org sources (same as Devils-Box) ----
HOST1="https://archive.org/download/the-devils-box-alt"
HOST2="https://archive.org/download/the-devils-box_202112"
HOST_PSP="https://archive.org/download/PSP_US_Arquivista"

ROMS="/userdata/roms"

# ================================================================
#  CORE DOWNLOAD FUNCTION
#  $1 = archive.org sub-folder name
#  $2 = batocera system folder name  (defaults to $1 if omitted)
# ================================================================
function download_pack() {
    local src="${1}"
    local sys="${2:-$1}"
    local dest="$ROMS/$sys"

    mkdir -p "$dest"

    dialog --title "Downloading: $sys" --infobox \
        "\nFetching $sys pack from archive.org...\n\nDestination: $dest\n\nThis may take a long time depending on your connection.\nDo not interrupt." \
        10 60

    wget -q -m -r -np -nH -nd -R "index.html" \
        "${HOST1}/${src}/" \
        -P "$dest" \
        -erobots=off 2>/dev/null

    # wget sometimes leaves a partial html file
    rm -f "$dest/index.html.tmp" "$dest/index.html"

    dialog --title "Done" --msgbox \
        "Download complete!\n\nSystem : $sys\nFiles  : $dest\n\nGo to:\n  START → Game Settings → Update Gamelists\nto make them appear in EmulationStation." \
        12 58
}

# PSP has its own archive
function download_psp() {
    local dest="$ROMS/psp"
    mkdir -p "$dest"
    dialog --title "Downloading: PSP" --infobox \
        "\nFetching PSP pack from archive.org...\n\nDestination: $dest\n\nThis is a large collection (~600 games). Be patient." \
        9 58
    wget -q -m -r -np -nH -nd -R "index.html" \
        "${HOST_PSP}/" -P "$dest" -erobots=off 2>/dev/null
    rm -f "$dest/index.html.tmp" "$dest/index.html"
    dialog --title "Done" --msgbox "PSP download complete!\n\nFiles: $dest" 7 50
}

# ================================================================
#  MENUS
# ================================================================

function consoles_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --backtitle "$BACKTITLE" \
            --title " CONSOLE GAME PACKS " \
            --ok-label "Download" --cancel-label "Back" \
            --menu "Select a console  (size = approx. archive size)" 38 72 28 \
            + "  <Console Name>                  Size      Games" \
            1  "Amiga 500                         300 MB    ~340" \
            2  "Amiga CD32                        461 MB    ~133" \
            3  "Amstrad CPC                       614 MB   ~3264" \
            4  "Arcade (MAME)                     8.4 GB   ~2361" \
            5  "Arcadia 2001                      200 KB     ~47" \
            6  "Astrocade                         174 KB     ~48" \
            7  "Atari 800                         5.2 MB    ~100" \
            8  "Atari 2600                        2.6 MB    ~615" \
            9  "Atari 5200                        928 KB     ~81" \
            10 "Atari 7800                          2 MB     ~54" \
            11 "Atari Lynx                          10 MB    ~77" \
            12 "Atari ST                            66 MB   ~100" \
            13 "Atomiswave                         2.5 GB    ~24" \
            14 "BBC Micro                            5 MB    ~50" \
            15 "Commodore 64                       9.5 MB   ~144" \
            16 "ColecoVision                       2.7 MB   ~146" \
            17 "Dreamcast                          106 GB   ~271" \
            18 "Famicom (NES)                       19 MB   ~169" \
            19 "Famicom Disk System                  2 MB    ~43" \
            20 "Game & Watch                         48 MB   ~53" \
            21 "Game Boy                             42 MB  ~565" \
            22 "Game Boy Advance                    3.4 GB ~1006" \
            23 "Game Boy Color                      232 MB  ~538" \
            24 "Game Gear                            42 MB  ~249" \
            25 "Intellivision                         1 MB   ~62" \
            26 "Master System                        35 MB  ~280" \
            27 "Mega Drive / Genesis                409 MB  ~561" \
            28 "Mega Drive Japan                    149 MB  ~278" \
            29 "MSX 1                                30 MB  ~708" \
            30 "MSX 2                               6.2 MB   ~83" \
            31 "NES                                 100 MB  ~869" \
            32 "Nintendo 64                         5.0 GB  ~338" \
            33 "Nintendo DS                           4 GB  ~171" \
            34 "NAOMI                               1.5 GB   ~15" \
            35 "Neo Geo                             2.3 GB  ~142" \
            36 "Neo Geo Pocket Color                 21 MB   ~40" \
            37 "OpenBOR                             1.8 GB   ~37" \
            38 "Oric Atmos                          5.4 MB  ~136" \
            39 "Pokémon Mini                        5.4 MB   ~44" \
            40 "PlayStation 1                         3 GB   ~29" \
            41 "PSP                                  ??? GB ~600" \
            42 "Saturn                              108 GB  ~303" \
            43 "Saturn Japan                        3.9 GB   ~18" \
            44 "ScummVM                             2.5 GB   ~21" \
            45 "Sega 32X                             63 MB   ~37" \
            46 "Sega CD / Mega CD                    11 GB   ~52" \
            47 "Sega Model 3                         ?? GB   ~15" \
            48 "SG-1000                               1 MB   ~68" \
            49 "SNES                                508 MB  ~603" \
            50 "Super Famicom                       475 MB  ~487" \
            51 "SNES MSU-1                           ?? MB   ~??" \
            52 "SuperGrafx                          2.4 MB    ~5" \
            53 "TurboGrafx-16 / PC Engine            20 MB   ~94" \
            54 "Vectrex                             201 KB   ~20" \
            55 "Virtual Boy                           8 MB   ~24" \
            56 "VMU (Dreamcast)                       3 MB  ~115" \
            57 "WonderSwan Color                    116 MB   ~84" \
            58 "Sharp X1                            7.6 MB   ~69" \
            59 "Sharp X68000                        504 MB  ~418" \
            60 "ZX Spectrum                          38 MB ~1111" \
            2>&1 >/dev/tty)

        case "$choice" in
            1)  download_pack "amiga"       "amiga500"     ;;
            2)  download_pack "amigacd32"   "amigacd32"    ;;
            3)  download_pack "amstradcpc"  "amstradcpc"   ;;
            4)  download_pack "arcade"      "mame"         ;;
            5)  download_pack "arcadia"     "arcadia"      ;;
            6)  download_pack "astrocade"   "astrocade"    ;;
            7)  download_pack "atari800"    "atari800"     ;;
            8)  download_pack "atari2600"   "atari2600"    ;;
            9)  download_pack "atari5200"   "atari5200"    ;;
            10) download_pack "atari7800"   "atari7800"    ;;
            11) download_pack "atarilynx"   "lynx"         ;;
            12) download_pack "atarist"     "atarist"      ;;
            13) download_pack "atomiswave"  "atomiswave"   ;;
            14) download_pack "bbcmicro"    "bbcmicro"     ;;
            15) download_pack "c64"         "c64"          ;;
            16) download_pack "coleco"      "colecovision" ;;
            17) download_pack "dreamcast"   "dreamcast"    ;;
            18) download_pack "famicon"     "nes"          ;;
            19) download_pack "fds"         "fds"          ;;
            20) download_pack "gameandwatch" "gameandwatch" ;;
            21) download_pack "gb"          "gb"           ;;
            22) download_pack "gba"         "gba"          ;;
            23) download_pack "gbc"         "gbc"          ;;
            24) download_pack "gamegear"    "gamegear"     ;;
            25) download_pack "intellivision" "intellivision" ;;
            26) download_pack "mastersystem" "mastersystem" ;;
            27) download_pack "megadrive"   "megadrive"    ;;
            28) download_pack "megadrive-japan" "megadrive" ;;
            29) download_pack "msx"         "msx1"         ;;
            30) download_pack "msx2"        "msx2"         ;;
            31) download_pack "nes"         "nes"          ;;
            32) download_pack "n64"         "n64"          ;;
            33) download_pack "nds"         "nds"          ;;
            34) download_pack "naomi"       "naomi"        ;;
            35) download_pack "neogeo"      "neogeo"       ;;
            36) download_pack "ngpc"        "ngpc"         ;;
            37) download_pack "openbor"     "openbor"      ;;
            38) download_pack "oric"        "oricatmos"    ;;
            39) download_pack "pokemini"    "pokemini"     ;;
            40) download_pack "psx"         "psx"          ;;
            41) download_psp ;;
            42) download_pack "saturn"      "saturn"       ;;
            43) download_pack "saturn-japan" "saturn"      ;;
            44) download_pack "scummvm"     "scummvm"      ;;
            45) download_pack "sega32x"     "sega32x"      ;;
            46) download_pack "segacd"      "megacd"       ;;
            47) download_pack "model3"      "model3"       ;;
            48) download_pack "sg-1000"     "sg1000"       ;;
            49) download_pack "snes"        "snes"         ;;
            50) download_pack "sfc"         "snes"         ;;
            51) download_pack "snesmsu1"    "snes-msu1"    ;;
            52) download_pack "supergrafx"  "supergrafx"   ;;
            53) download_pack "tg16"        "pcengine"     ;;
            54) download_pack "vectrex"     "vectrex"      ;;
            55) download_pack "virtualboy"  "virtualboy"   ;;
            56) download_pack "svmu"        "vemulator"    ;;
            57) download_pack "wonderswancolor" "wswanc"   ;;
            58) download_pack "x1"          "x1"           ;;
            59) download_pack "x68000"      "x68000"       ;;
            60) download_pack "zxspectrum"  "zxspectrum"   ;;
            +)  : ;;  # header row — do nothing
            *)  break ;;
        esac
    done
}

# ---- Entry point ----
consoles_menu
