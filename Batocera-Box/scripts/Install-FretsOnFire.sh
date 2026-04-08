#!/bin/bash
###############################################################
# Install-FretsOnFire.sh
# Installs Frets on Fire (FOSSAIDev Python 3 port) on Batocera
# Downloads source, patches asyncore for Python 3.12, fixes
# PyOpenGL EGL/GLX context detection, patches Audio.py for
# dummy-driver fallback, creates Ports launcher + gamelist entry.
###############################################################

INSTALL_DIR="/userdata/system/frets-on-fire"
SRC_DIR="$INSTALL_DIR/Frets-on-Fire-master"
PORTS_DIR="/userdata/roms/ports"
LAUNCHER="$PORTS_DIR/FretsOnFire.sh"
GAMELIST="$PORTS_DIR/gamelist.xml"

echo "=== Frets on Fire Installer ==="

# --- Download ---
echo "[1/5] Downloading Frets on Fire..."
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
echo "[2/5] Ensuring PyOpenGL is installed..."
python3 -c "import OpenGL" 2>/dev/null || \
  python3 -m pip install --quiet PyOpenGL 2>/dev/null

# --- asyncore for Python 3.12+ ---
# asyncore was removed from stdlib in Python 3.12. The game uses it for the
# local server/client session (needed even for single-player). We copy the
# real asyncore.py from a known location or download it.
echo "[3/5] Patching asyncore compatibility..."
ASYNCORE_DST="$SRC_DIR/src/asyncore.py"
# Try to copy from Python 3.9 Xcode on macOS (when running installer from host)
ASYNCORE_SRC="/Applications/Xcode.app/Contents/Developer/Library/Frameworks/Python3.framework/Versions/3.9/lib/python3.9/asyncore.py"
if [ -f "$ASYNCORE_SRC" ]; then
  cp "$ASYNCORE_SRC" "$ASYNCORE_DST"
  echo "  Copied asyncore from host Python 3.9."
else
  # Minimal working asyncore — sufficient for loopback TCP server/client
  python3 - << 'PYEOF'
# Download CPython 3.11 asyncore (last version before removal)
import urllib.request, os
url = "https://raw.githubusercontent.com/python/cpython/3.11/Lib/asyncore.py"
dst = "/userdata/system/frets-on-fire/Frets-on-Fire-master/src/asyncore.py"
try:
    urllib.request.urlretrieve(url, dst)
    print("  asyncore downloaded from CPython 3.11.")
except Exception as e:
    print("  Could not download asyncore:", e)
    print("  Writing minimal stub (single-player only)...")
    content = """import select, socket, os, time
socket_map = {}
class dispatcher:
    connected = False; _fileno = None; socket = None; server = None
    def __init__(self, sock=None):
        if sock:
            self.socket = sock; self.socket.setblocking(0)
            self._fileno = sock.fileno(); socket_map[self._fileno] = self
            self.connected = True
    def create_socket(self, family=socket.AF_INET, t=socket.SOCK_STREAM):
        self.socket = socket.socket(family, t); self.socket.setblocking(0)
        self._fileno = self.socket.fileno(); socket_map[self._fileno] = self
    def set_reuse_addr(self):
        if self.socket: self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    def bind(self, addr): self.socket.bind(addr)
    def listen(self, backlog=5): self.socket.listen(backlog)
    def accept(self):
        try: conn, addr = self.socket.accept(); return conn, addr
        except: return None, None
    def connect(self, address):
        err = self.socket.connect_ex(address)
        n=0
        while err and n<200:
            time.sleep(0.05); n+=1
            try: self.socket.connect(address)
            except OSError as e:
                if e.errno in (106, 114, 115): break
                if e.errno == 111: continue
        self.connected = True
    def send(self, data): return self.socket.send(data) if self.socket else 0
    def recv(self, size): return self.socket.recv(size) if self.socket else b""
    def close(self):
        if self._fileno in socket_map: del socket_map[self._fileno]
        if self.socket: self.socket.close(); self.socket = None
    def handle_close(self): self.close()
    def writable(self): return False
    def handle_read(self): pass
    def handle_write(self): pass
    def handle_connect(self): pass
    def handle_error(self): pass
def poll(timeout=0.0, map=None):
    if map is None: map = socket_map
    if not map: return
    r=[]; w=[]; e=[]
    for fd,obj in list(map.items()):
        if obj.socket:
            r.append(obj.socket)
            if obj.writable(): w.append(obj.socket)
    try: r,w,e = select.select(r,w,e,timeout)
    except: return
    for sock in r:
        for obj in list(map.values()):
            if obj.socket == sock:
                try: obj.handle_read()
                except: pass
    for sock in w:
        for obj in list(map.values()):
            if obj.socket == sock:
                try: obj.handle_write()
                except: pass
def close_all(map=None, ignore_all=False): pass
"""
    with open(dst, "w") as f: f.write(content)
PYEOF
fi

# --- Fix Audio.py: dummy driver fallback ---
echo "[4/5] Patching Audio.py for dummy audio fallback..."
python3 - << 'PYEOF'
path = "/userdata/system/frets-on-fire/Frets-on-Fire-master/src/Audio.py"
with open(path, "r", encoding="iso-8859-1") as f:
    content = f.read()
old = ('      try:\n'
       '        pygame.mixer.init(frequency, -bits, stereo and 2 or 1, bufferSize)\n'
       '      except:\n'
       '        Log.warn("Audio setup failed. Trying with default configuration.")\n'
       '        pygame.mixer.init()')
new = ('      try:\n'
       '        pygame.mixer.init(frequency, -bits, stereo and 2 or 1, bufferSize)\n'
       '      except:\n'
       '        Log.warn("Audio setup failed. Trying with default configuration.")\n'
       '        try:\n'
       '          pygame.mixer.init()\n'
       '        except:\n'
       '          import os\n'
       '          Log.warn("Default audio setup failed. Falling back to dummy driver.")\n'
       '          os.environ["SDL_AUDIODRIVER"] = "dummy"\n'
       '          pygame.mixer.init()')
if old in content:
    content = content.replace(old, new)
    with open(path, "w", encoding="iso-8859-1") as f:
        f.write(content)
    print("  Audio.py patched.")
else:
    print("  Audio.py already patched or pattern not found.")
PYEOF

# --- Fix Svg.py: pass numpy array to glMultMatrixf instead of list ---
echo "[4b/5] Patching Svg.py for OpenGL numpy array fix..."
python3 - << 'PYEOF'
path = "/userdata/system/frets-on-fire/Frets-on-Fire-master/src/Svg.py"
with open(path, "r", encoding="iso-8859-1") as f:
    content = f.read()
old = 'from numpy import reshape, dot, transpose, identity, zeros, float32'
new = 'from numpy import reshape, dot, transpose, identity, zeros, float32, array as nparray'
if old in content:
    content = content.replace(old, new)
old2 = ('    m = [m[0, 0], m[1, 0], 0.0, 0.0,\n'
        '         m[0, 1], m[1, 1], 0.0, 0.0,\n'
        '             0.0,     0.0, 1.0, 0.0,\n'
        '         m[0, 2], m[1, 2], 0.0, 1.0]\n'
        '    glMultMatrixf(m)')
new2 = ('    m = nparray([m[0, 0], m[1, 0], 0.0, 0.0,\n'
        '         m[0, 1], m[1, 1], 0.0, 0.0,\n'
        '             0.0,     0.0, 1.0, 0.0,\n'
        '         m[0, 2], m[1, 2], 0.0, 1.0], dtype=float32)\n'
        '    glMultMatrixf(m)')
if old2 in content:
    content = content.replace(old2, new2)
    with open(path, "w", encoding="iso-8859-1") as f:
        f.write(content)
    print("  Svg.py patched.")
else:
    print("  Svg.py already patched or pattern not found.")
PYEOF

# --- Fix PyOpenGL contextdata: EGL/GLX context detection ---
echo "[4c/5] Patching PyOpenGL for EGL/Xwayland context detection..."
python3 - << 'PYEOF'
import subprocess, sys
# Find PyOpenGL contextdata.py
try:
    import OpenGL.contextdata as cd
    import inspect, os
    path = inspect.getfile(cd)
    with open(path, "r") as f:
        content = f.read()
    old = ('        if not context:\n'
           '            from OpenGL import error\n'
           '            raise error.Error(\n'
           '                """Attempt to retrieve context when no valid context"""\n'
           '            )')
    new = ('        if not context:\n'
           '            # Under SDL2+EGL (Xwayland/Wayland), glXGetCurrentContext()\n'
           '            # returns NULL even when a valid EGL context is current.\n'
           '            # Use a sentinel so pointer storage works for single-context apps.\n'
           '            context = -1')
    if old in content:
        content = content.replace(old, new)
        with open(path, "w") as f:
            f.write(content)
        # Clear pyc cache
        pyc = path.replace(".py", ".cpython-312.pyc").replace("OpenGL/", "OpenGL/__pycache__/")
        try: os.remove(pyc)
        except: pass
        print("  PyOpenGL contextdata.py patched.")
    else:
        print("  PyOpenGL contextdata.py already patched or pattern not found.")
except Exception as e:
    print("  Could not patch PyOpenGL contextdata:", e)
PYEOF

# --- Launcher ---
echo "[5/5] Creating Ports launcher..."
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/bin/bash
# Frets on Fire - Batocera Ports launcher
export SDL_VIDEODRIVER=x11
export DISPLAY=:0.0
export PYTHONPATH=/userdata/system/frets-on-fire/Frets-on-Fire-master/src
cd /userdata/system/frets-on-fire/Frets-on-Fire-master
/usr/bin/python3 src/FretsOnFire.py 2>/userdata/system/frets-on-fire/fof.log
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
