#!/bin/bash
###############################################################
# Install-FretsOnFire.sh
# Installs Frets on Fire (FOSSAIDev Python 3 port) on Batocera
# Downloads source, patches asyncore for Python 3.12, creates
# a Ports launcher and gamelist.xml entry.
###############################################################

INSTALL_DIR="/userdata/system/frets-on-fire"
SRC_DIR="$INSTALL_DIR/Frets-on-Fire-master"
PORTS_DIR="/userdata/roms/ports"
LAUNCHER="$PORTS_DIR/FretsOnFire.sh"
GAMELIST="$PORTS_DIR/gamelist.xml"

echo "=== Frets on Fire Installer ==="

# --- Download ---
echo "[1/4] Downloading Frets on Fire..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
if [ -d "$SRC_DIR" ]; then
  echo "  Already downloaded, skipping."
else
  /usr/bin/curl -L https://github.com/FOSSAIDev/Frets-on-Fire/archive/refs/heads/master.tar.gz \
    -o fof-master.tar.gz 2>&1 | tail -1
  tar xzf fof-master.tar.gz
  rm -f fof-master.tar.gz
fi

# --- Install PyOpenGL (needed by the game) ---
echo "[2/4] Ensuring PyOpenGL is installed..."
python3 -c "import OpenGL" 2>/dev/null || \
  python3 -m pip install --quiet PyOpenGL 2>/dev/null

# --- asyncore stub for Python 3.12+ ---
echo "[3/4] Patching asyncore compatibility..."
python3 - << 'PYEOF'
content = """# asyncore compatibility stub for Python 3.12+
import socket
socket_map = {}

class dispatcher:
    connected = False
    def __init__(self, sock=None): pass
    def create_socket(self, family, t): pass
    def set_reuse_addr(self): pass
    def bind(self, addr): pass
    def listen(self, backlog): pass
    def connect(self, address): pass
    def send(self, data): return 0
    def recv(self, size): return b""
    def close(self): pass
    def handle_close(self): pass

def poll(timeout=0.0, map=None): pass
def close_all(map=None, ignore_all=False): pass
"""
path = "/userdata/system/frets-on-fire/Frets-on-Fire-master/src/asyncore.py"
with open(path, "w") as f:
    f.write(content)
print("  asyncore stub written.")
PYEOF

# --- Launcher ---
echo "[4/4] Creating Ports launcher..."
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/bin/bash
# Frets on Fire - Batocera Ports launcher
export SDL_VIDEODRIVER=x11
export DISPLAY=:0.0
export PYTHONPATH=/userdata/system/frets-on-fire/Frets-on-Fire-master/src
cd /userdata/system/frets-on-fire/Frets-on-Fire-master
/usr/bin/python3 src/FretsOnFire.py
LAUNCHER_EOF
chmod +x "$LAUNCHER"

# --- Gamelist entry ---
if ! grep -q "FretsOnFire.sh" "$GAMELIST" 2>/dev/null; then
  python3 - << 'PYEOF'
import os
gamelist = "/userdata/roms/ports/gamelist.xml"
entry = """        <game>
                <path>./FretsOnFire.sh</path>
                <name>Frets on Fire</name>
                <desc>Frets on Fire - a game of musical skill and fast fingers. Play guitar along to songs using your keyboard or controller. Supports custom songs in OGG format.</desc>
                <developer>Sami Kyostila / FOSSAIDev (Python 3 port)</developer>
                <genre>Music</genre>
        </game>
"""
if os.path.exists(gamelist):
    content = open(gamelist).read()
    content = content.replace("</gameList>", entry + "</gameList>")
else:
    content = '<?xml version="1.0"?>\n<gameList>\n' + entry + '</gameList>\n'
with open(gamelist, "w") as f:
    f.write(content)
print("  Gamelist updated.")
PYEOF
else
  echo "  Gamelist entry already present."
fi

echo ""
echo "=== Frets on Fire installed! ==="
echo "Restart EmulationStation and find it under Ports > Frets on Fire."
echo "Songs go in: $SRC_DIR/data/songs/"
