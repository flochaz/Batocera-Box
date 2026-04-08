# Batocera Box

A Batocera-native port of the Devils-Box toolbox for RetroPie.  
Download ROMs and BIOS files from archive.org directly onto your Pi 4 running Batocera.

---

## Install

SSH into your Batocera machine (default password: `linux`):

```bash
ssh root@batocera.local
cd /userdata/system
git clone https://github.com/YOUR_USERNAME/Batocera-Box batocera-box
bash /userdata/system/batocera-box/BB-Install.sh
```

Or copy from a USB stick / network share:
```bash
cp -r /media/YOUR_USB/Batocera-Box /userdata/system/batocera-box
bash /userdata/system/batocera-box/BB-Install.sh
```

After install, the tool appears under **Ports → Batocera Box** in EmulationStation,  
or you can run it at any time via SSH:

```bash
bash /userdata/system/batocera-box/Batocera-Box.sh
```

---

## What it does

| Feature | Description |
|---|---|
| **Game Packs** | Download full console ROM collections to the right `/userdata/roms/<system>/` folder |
| **Pick & Choose** | Select individual games per console via a checklist |
| **BIOS Files** | Download BIOS files to `/userdata/bios/` |
| **System Tools** | Restart EmulationStation, show disk / system info, reboot |

---

## Differences from Devils-Box (RetroPie)

| | Devils-Box (RetroPie) | Batocera Box |
|---|---|---|
| ROM path | `~/RetroPie/roms/<sys>/` | `/userdata/roms/<sys>/` |
| BIOS path | `~/RetroPie/BIOS/` | `/userdata/bios/` |
| Emulator install | `retropie_packages.sh` | Not needed — all emulators pre-installed |
| Restart frontend | `emulationstation` | `batocera-es-swissknife --restart` |
| Home | `/home/pi` | `/userdata/system` |

### System name changes (RetroPie → Batocera)

| RetroPie | Batocera |
|---|---|
| amiga | amiga500 |
| coleco | colecovision |
| atarilynx | lynx |
| segacd | megacd |
| snesmsu1 | snes-msu1 |
| sg-1000 | sg1000 |
| videopac | odyssey2 |
| svmu | vemulator |
| wonderswancolor | wswanc |
| ngpc | ngpc |
| oric | oricatmos |
| msx | msx1 |

---

## After downloading ROMs

Batocera auto-hides systems with no ROMs.  
After a download, run **Update Gamelists** from System Tools,  
or go to **START → Game Settings → Update Gamelists** inside EmulationStation.

---

## Legal notice

ROMs and BIOS files are downloaded from archive.org public collections (same sources as the original Devils-Box).  
Only use games you legally own. This tool is for personal backup purposes only.

---

## Credits

Based on **Devils-Box** by The Retro Devils.  
Adapted for Batocera.linux on Raspberry Pi 4.
