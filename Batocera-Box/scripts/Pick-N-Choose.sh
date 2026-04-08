#!/bin/bash
# ============================================================
# Batocera Box — Pick & Choose
# Select individual games per console via a checklist.
# Files are downloaded from the same archive.org collection.
# ============================================================
export NCURSES_NO_UTF8_ACS=1
export TERM="${TERM:-xterm}"

BACKTITLE="Batocera Box | Pick & Choose"
PC_HOST="https://archive.org/download/the-devils-box-alt"
ROMS="/userdata/roms"

# ================================================================
#  DOWNLOAD A SINGLE FILE
#  $1 = batocera system folder
#  $2 = filename on archive.org (URL-encoded spaces → %20 if needed)
#  $3 = archive.org sub-path (defaults to $1)
# ================================================================
function dl_game() {
    local sys="$1"
    local file="$2"
    local src="${3:-$1}"
    local dest="$ROMS/$sys"

    mkdir -p "$dest"
    dialog --title "Downloading" --infobox "\nDownloading:\n  $file\nTo:\n  $dest\n" 8 60

    wget -q --show-progress \
        -O "$dest/$file" \
        "${PC_HOST}/${src}/${file}" 2>/dev/null \
        || wget -q -O "$dest/$file" "${PC_HOST}/${src}/${file}"

    if [ $? -eq 0 ] && [ -s "$dest/$file" ]; then
        dialog --title "Done" --msgbox "Downloaded:\n  $file\nTo: $dest" 7 55
    else
        dialog --title "Error" --msgbox \
            "Download failed for:\n  $file\n\nThe file may not exist in this archive.\nCheck https://archive.org/download/the-devils-box-alt/${src}/ for available files." \
            10 62
        rm -f "$dest/$file"
    fi
}

# ================================================================
#  PROCESS CHECKLIST SELECTIONS
#  $1 = batocera system
#  $2 = archive sub-path (if different from system)
#  $3+ = space-separated "index:filename" pairs
# ================================================================
function process_selections() {
    local sys="$1"; shift
    local src="$1"; shift
    # remaining args: "1:filename.zip" "2:other.zip" ...
    declare -A map
    for pair; do
        local idx="${pair%%:*}"
        local fname="${pair#*:}"
        map["$idx"]="$fname"
    done

    # re-read selections from the file we saved before calling this
    local sel_file="/tmp/bb_sel_$$"
    if [ ! -f "$sel_file" ]; then return; fi
    local selections
    selections=$(cat "$sel_file")
    rm -f "$sel_file"

    local count=0
    for sel in $selections; do
        sel="${sel//\"/}"
        if [ -n "${map[$sel]}" ]; then
            dl_game "$sys" "${map[$sel]}" "$src"
            count=$((count+1))
        fi
    done

    if [ "$count" -eq 0 ]; then
        dialog --title "No Selection" --msgbox "No games were selected." 5 35
    fi
}

# ================================================================
#  HELPER: run a checklist and save selections to /tmp
# ================================================================
function run_checklist() {
    local title="$1"; shift
    local prompt="$1"; shift
    # remaining: dialog checklist items (tag item status ...)
    local result_file="/tmp/bb_sel_$$"

    dialog \
        --backtitle "$BACKTITLE" \
        --title "$title" \
        --ok-label "Download Selected" \
        --cancel-label "Back" \
        --checklist "$prompt" 28 65 20 \
        "$@" \
        2>"$result_file" >/dev/tty

    local rc=$?
    if [ $rc -ne 0 ]; then
        rm -f "$result_file"
        return 1
    fi
    return 0
}

# ================================================================
#  PER-CONSOLE PICKERS
# ================================================================

function pick_arcade() {
    run_checklist "Pick & Choose — Arcade (MAME)" "Select games to download:" \
        "1"  "Arkanoid"             off \
        "2"  "Bubble Bobble"        off \
        "3"  "BurgerTime"           off \
        "4"  "Centipede"            off \
        "5"  "Donkey Kong"          off \
        "6"  "Double Dragon"        off \
        "7"  "Frogger"              off \
        "8"  "Galaga"               off \
        "9"  "Golden Axe"           off \
        "10" "Gyruss"               off \
        "11" "Joust"                off \
        "12" "King of Fighters 95"  off \
        "13" "King of Fighters 96"  off \
        "14" "King of Fighters 2000" off \
        "15" "King of Fighters 2003" off \
        "16" "Pac-Man"              off \
        "17" "Space Invaders"       off \
        "18" "Street Fighter II"    off \
        || return

    process_selections "mame" "arcade" \
        "1:arkanoid.zip" \
        "2:bublbobl.zip" \
        "3:btime.zip" \
        "4:centiped.zip" \
        "5:dkong.zip" \
        "6:ddragon.zip" \
        "7:frogger.zip" \
        "8:galaga.zip" \
        "9:goldnaxe.zip" \
        "10:gyruss.zip" \
        "11:joust.zip" \
        "12:kof95.zip" \
        "13:kof96.zip" \
        "14:kof2000.zip" \
        "15:kof2003.zip" \
        "16:puckman.zip" \
        "17:invaders.zip" \
        "18:sf2.zip"
}

function pick_dreamcast() {
    run_checklist "Pick & Choose — Dreamcast" "Select games to download:" \
        "1"  "Crazy Taxi"           off \
        "2"  "Jet Grind Radio"      off \
        "3"  "Marvel vs Capcom 2"   off \
        "4"  "Power Stone"          off \
        "5"  "Resident Evil 3"      off \
        "6"  "Shenmue"              off \
        "7"  "Sonic Adventure"      off \
        "8"  "Soul Calibur"         off \
        "9"  "Street Fighter III"   off \
        "10" "Tech Romancer"        off \
        || return

    process_selections "dreamcast" "dreamcast" \
        "1:CrazyTaxi.zip" \
        "2:JetGrindRadio.zip" \
        "3:MarvelVsCapcom2.zip" \
        "4:PowerStone.zip" \
        "5:ResidentEvil3.zip" \
        "6:Shenmue.zip" \
        "7:SonicAdventure.zip" \
        "8:SoulCalibur.zip" \
        "9:StreetFighterIII.zip" \
        "10:TechRomancer.zip"
}

function pick_gba() {
    run_checklist "Pick & Choose — Game Boy Advance" "Select games to download:" \
        "1"  "Castlevania: AoS"         off \
        "2"  "Fire Emblem"              off \
        "3"  "Golden Sun"               off \
        "4"  "Kirby: Nightmare in Dream Land" off \
        "5"  "Mega Man Zero"            off \
        "6"  "Metroid Fusion"           off \
        "7"  "Mother 3"                 off \
        "8"  "Pokemon FireRed"          off \
        "9"  "Super Mario Advance 4"    off \
        "10" "Zelda: Minish Cap"        off \
        || return

    process_selections "gba" "gba" \
        "1:Castlevania-AriaOfSorrow.zip" \
        "2:FireEmblem.zip" \
        "3:GoldenSun.zip" \
        "4:KirbyNightmare.zip" \
        "5:MegaManZero.zip" \
        "6:MetroidFusion.zip" \
        "7:Mother3.zip" \
        "8:PokemonFireRed.zip" \
        "9:SuperMarioAdvance4.zip" \
        "10:ZeldaMinishCap.zip"
}

function pick_megadrive() {
    run_checklist "Pick & Choose — Mega Drive / Genesis" "Select games to download:" \
        "1"  "Aladdin"               off \
        "2"  "Altered Beast"         off \
        "3"  "Comix Zone"            off \
        "4"  "Contra Hard Corps"     off \
        "5"  "Ecco the Dolphin"      off \
        "6"  "Golden Axe II"         off \
        "7"  "Mortal Kombat II"      off \
        "8"  "Rocket Knight Adventures" off \
        "9"  "Sonic the Hedgehog"    off \
        "10" "Sonic the Hedgehog 2"  off \
        "11" "Sonic 3 & Knuckles"    off \
        "12" "Streets of Rage 2"     off \
        "13" "Street Fighter II"     off \
        || return

    process_selections "megadrive" "megadrive" \
        "1:Aladdin.zip" \
        "2:AlteredBeast.zip" \
        "3:ComixZone.zip" \
        "4:ContraHardCorps.zip" \
        "5:EccoTheDolphin.zip" \
        "6:GoldenAxeII.zip" \
        "7:MortalKombatII.zip" \
        "8:RocketKnightAdventures.zip" \
        "9:Sonic1.zip" \
        "10:Sonic2.zip" \
        "11:Sonic3Knuckles.zip" \
        "12:StreetsOfRage2.zip" \
        "13:StreetFighterII.zip"
}

function pick_n64() {
    run_checklist "Pick & Choose — Nintendo 64" "Select games to download:" \
        "1"  "Banjo-Kazooie"            off \
        "2"  "Diddy Kong Racing"        off \
        "3"  "Donkey Kong 64"           off \
        "4"  "GoldenEye 007"            off \
        "5"  "Mario Kart 64"            off \
        "6"  "Ocarina of Time"          off \
        "7"  "Paper Mario"              off \
        "8"  "Perfect Dark"             off \
        "9"  "Star Fox 64"              off \
        "10" "Super Mario 64"           off \
        "11" "Super Smash Bros"         off \
        "12" "Wave Race 64"             off \
        || return

    process_selections "n64" "n64" \
        "1:BanjoKazooie.zip" \
        "2:DiddyKongRacing.zip" \
        "3:DonkeyKong64.zip" \
        "4:GoldenEye007.zip" \
        "5:MarioKart64.zip" \
        "6:ZeldaOcarinaOfTime.zip" \
        "7:PaperMario.zip" \
        "8:PerfectDark.zip" \
        "9:StarFox64.zip" \
        "10:SuperMario64.zip" \
        "11:SuperSmashBros.zip" \
        "12:WaveRace64.zip"
}

function pick_nes() {
    run_checklist "Pick & Choose — NES" "Select games to download:" \
        "1"  "Castlevania"              off \
        "2"  "Contra"                  off \
        "3"  "Double Dragon"           off \
        "4"  "Duck Hunt"               off \
        "5"  "Excitebike"              off \
        "6"  "Final Fantasy"           off \
        "7"  "Kirby's Adventure"       off \
        "8"  "Mega Man 2"              off \
        "9"  "Metroid"                 off \
        "10" "Super Mario Bros"        off \
        "11" "Super Mario Bros 3"      off \
        "12" "Tecmo Bowl"              off \
        "13" "TMNT"                    off \
        "14" "Zelda"                   off \
        || return

    process_selections "nes" "nes" \
        "1:Castlevania.zip" \
        "2:Contra.zip" \
        "3:DoubleDragon.zip" \
        "4:DuckHunt.zip" \
        "5:Excitebike.zip" \
        "6:FinalFantasy.zip" \
        "7:KirbysAdventure.zip" \
        "8:MegaMan2.zip" \
        "9:Metroid.zip" \
        "10:SuperMarioBros.zip" \
        "11:SuperMarioBros3.zip" \
        "12:TecmoBowl.zip" \
        "13:TMNT.zip" \
        "14:Zelda.zip"
}

function pick_psx() {
    run_checklist "Pick & Choose — PlayStation 1" "Select games to download:" \
        "1"  "Castlevania: SotN"        off \
        "2"  "Crash Bandicoot"          off \
        "3"  "Final Fantasy VII"        off \
        "4"  "Final Fantasy VIII"       off \
        "5"  "Gran Turismo 2"           off \
        "6"  "Metal Gear Solid"         off \
        "7"  "Resident Evil 2"          off \
        "8"  "Silent Hill"              off \
        "9"  "Spyro"                    off \
        "10" "Tekken 3"                 off \
        "11" "Tomb Raider"              off \
        "12" "Tony Hawk's Pro Skater"   off \
        || return

    process_selections "psx" "psx" \
        "1:CastlevaniaSotN.zip" \
        "2:CrashBandicoot.zip" \
        "3:FinalFantasyVII.zip" \
        "4:FinalFantasyVIII.zip" \
        "5:GranTurismo2.zip" \
        "6:MetalGearSolid.zip" \
        "7:ResidentEvil2.zip" \
        "8:SilentHill.zip" \
        "9:Spyro.zip" \
        "10:Tekken3.zip" \
        "11:TombRaider.zip" \
        "12:TonyHawkProSkater.zip"
}

function pick_snes() {
    run_checklist "Pick & Choose — SNES" "Select games to download:" \
        "1"  "Castlevania IV"           off \
        "2"  "Chrono Trigger"           off \
        "3"  "Contra III"               off \
        "4"  "DKC"                      off \
        "5"  "EarthBound"               off \
        "6"  "Final Fantasy VI"         off \
        "7"  "Kirby Super Star"         off \
        "8"  "Mega Man X"               off \
        "9"  "Mortal Kombat II"         off \
        "10" "Secret of Mana"           off \
        "11" "Star Fox"                 off \
        "12" "Street Fighter II Turbo"  off \
        "13" "Super Mario World"        off \
        "14" "Super Mario RPG"          off \
        "15" "Super Metroid"            off \
        "16" "Zelda: A Link to the Past" off \
        || return

    process_selections "snes" "snes" \
        "1:CastlevaniaIV.zip" \
        "2:ChronoTrigger.zip" \
        "3:ContraIII.zip" \
        "4:DonkeyKongCountry.zip" \
        "5:EarthBound.zip" \
        "6:FinalFantasyVI.zip" \
        "7:KirbySuperStar.zip" \
        "8:MegaManX.zip" \
        "9:MortalKombatII.zip" \
        "10:SecretOfMana.zip" \
        "11:StarFox.zip" \
        "12:StreetFighterIITurbo.zip" \
        "13:SuperMarioWorld.zip" \
        "14:SuperMarioRPG.zip" \
        "15:SuperMetroid.zip" \
        "16:ZeldaLinkToThePast.zip"
}

function pick_saturn() {
    run_checklist "Pick & Choose — Sega Saturn" "Select games to download:" \
        "1"  "Castlevania: SotN"        off \
        "2"  "Daytona USA"              off \
        "3"  "Guardian Heroes"          off \
        "4"  "House of the Dead"        off \
        "5"  "Nights Into Dreams"       off \
        "6"  "Panzer Dragoon Saga"      off \
        "7"  "Radiant Silvergun"        off \
        "8"  "Street Fighter Alpha 3"   off \
        "9"  "Virtua Fighter 2"         off \
        "10" "Virtua Cop"               off \
        || return

    process_selections "saturn" "saturn" \
        "1:CastlevaniaSotN.zip" \
        "2:DaytonaUSA.zip" \
        "3:GuardianHeroes.zip" \
        "4:HouseOfTheDead.zip" \
        "5:NightsIntoDreams.zip" \
        "6:PanzerDragoonSaga.zip" \
        "7:RadiantSilvergun.zip" \
        "8:StreetFighterAlpha3.zip" \
        "9:VirtuaFighter2.zip" \
        "10:VirtuaCop.zip"
}

# ================================================================
#  MAIN PICK & CHOOSE MENU
# ================================================================

function pick_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --backtitle "$BACKTITLE" \
            --title " PICK & CHOOSE " \
            --ok-label "Select" --cancel-label "Back" \
            --menu "Choose a console" 20 52 12 \
            1  "Arcade (MAME)" \
            2  "Dreamcast" \
            3  "Game Boy Advance" \
            4  "Mega Drive / Genesis" \
            5  "Nintendo 64" \
            6  "NES" \
            7  "PlayStation 1" \
            8  "Saturn" \
            9  "SNES" \
            2>&1 >/dev/tty)

        case "$choice" in
            1) pick_arcade     ;;
            2) pick_dreamcast  ;;
            3) pick_gba        ;;
            4) pick_megadrive  ;;
            5) pick_n64        ;;
            6) pick_nes        ;;
            7) pick_psx        ;;
            8) pick_saturn     ;;
            9) pick_snes       ;;
            *) break ;;
        esac
    done
}

# ---- Entry point ----
pick_menu
