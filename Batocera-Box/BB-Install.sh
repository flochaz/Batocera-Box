#!/bin/bash
# ============================================================
# Batocera Box — Installer / Updater
# Run this on your Batocera Pi via SSH:
#   bash BB-Install.sh
# ============================================================

BB_DIR="/userdata/system/batocera-box"
PORTS_DIR="/userdata/roms/ports"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "============================================"
echo "  Batocera Box — Installer"
echo "============================================"
echo ""

# ---- 1. Copy scripts to persistent userdata location ----
if [ "$SCRIPT_DIR" != "$BB_DIR" ]; then
    echo "[*] Installing scripts to $BB_DIR ..."
    mkdir -p "$BB_DIR/scripts" "$BB_DIR/files/images"
    cp -rf "$SCRIPT_DIR/"* "$BB_DIR/" 2>/dev/null || true
else
    echo "[*] Already running from $BB_DIR, skipping copy."
fi

chmod -R 755 "$BB_DIR"

# ---- 2. Create settings file if missing ----
if [ ! -f "$BB_DIR/.bb_settings.ini" ]; then
    cat > "$BB_DIR/.bb_settings.ini" << 'SETTINGS'
# Batocera Box Settings
version=1.0
SETTINGS
fi

# ---- 3. Create the Ports launcher ----
mkdir -p "$PORTS_DIR"

cat > "$PORTS_DIR/Batocera-Box.sh" << 'PORTSCRIPT'
#!/bin/bash
export TERM="${TERM:-xterm}"
export NCURSES_NO_UTF8_ACS=1
bash /userdata/system/batocera-box/Batocera-Box.sh
PORTSCRIPT
chmod 755 "$PORTS_DIR/Batocera-Box.sh"
echo "[*] Port launcher created at $PORTS_DIR/Batocera-Box.sh"

# ---- 4. Add gamelist.xml entry for EmulationStation ----
GAMELIST="$PORTS_DIR/gamelist.xml"

if [ ! -f "$GAMELIST" ]; then
    cat > "$GAMELIST" << 'XML'
<?xml version="1.0"?>
<gameList>
</gameList>
XML
fi

if ! grep -q "Batocera-Box.sh" "$GAMELIST" 2>/dev/null; then
    ENTRY="\t<game>\n\t\t<path>./Batocera-Box.sh</path>\n\t\t<name>Batocera Box</name>\n\t\t<desc>The Batocera ToolBox — Download ROMs and BIOS files to the right locations, manage your system.</desc>\n\t\t<developer>Based on Devils-Box by Retro Devils</developer>\n\t\t<genre>Utility</genre>\n\t</game>"
    sed -i "s|</gameList>|${ENTRY}\n</gameList>|" "$GAMELIST"
    echo "[*] Added Batocera Box entry to $GAMELIST"
fi

# ---- 5. Done ----
echo ""
echo "============================================"
echo "  Install complete!"
echo ""
echo "  Tool :  $BB_DIR/Batocera-Box.sh"
echo "  Port :  $PORTS_DIR/Batocera-Box.sh"
echo ""
echo "  Launch via SSH:"
echo "    bash /userdata/system/batocera-box/Batocera-Box.sh"
echo ""
echo "  Launch via EmulationStation:"
echo "    Ports → Batocera Box"
echo "    (restart ES first if Ports doesn't show it)"
echo "============================================"
echo ""
