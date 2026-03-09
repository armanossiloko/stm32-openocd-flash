# STM32 OpenOCD Flash Toolkit

A small, copy-paste toolkit to **flash STM32 and CH32 (Cortex-M) boards** from the command line using **OpenOCD** and an **ST-Link** (or optionally a WCH-Link in ARM mode). It is intended for use with **STM32CubeIDE** projects: you build in the IDE, then run one script to program the chip.

No IDE integration or plugins are required—just OpenOCD on your system and this folder in your project.

---

## What it does

- **Finds your project**  
  Detects the STM32CubeIDE project name from `.project` or `.ioc`, or you pass it as an argument.

- **Locates the built ELF**  
  Looks for `Debug/ProjectName.elf` (or `Release/ProjectName.elf` if Debug is missing).

- **Programs the MCU**  
  Runs OpenOCD with ST-Link + STM32F1 target config to **program**, **verify**, and **reset** the device.

- **CH32 / STM32F1 clones**  
  CH32F103 and similar clones use a different SW-DP ID (`0x2ba01477`) than genuine STM32F1 (`0x1ba01477`). The scripts set `CPUTAPID 0x2ba01477` so OpenOCD connects correctly.

- **Retry on failure**  
  If the first flash attempt fails (e.g. chip stuck in run mode), the script automatically retries with a different reset configuration (e.g. `connect_assert_srst`).

So in practice: **build in STM32CubeIDE → run one script → device is flashed and running.**

---

## Supported hardware

| Item | Notes |
|------|--------|
| **Debug probe** | ST-Link (v2 or onboard). Optionally WCH-Link in ARM/SWD mode (see [WCH-Link](#wch-link-optional) below). |
| **MCU** | STM32F1 and compatible (e.g. CH32F103, CS32F103). Uses OpenOCD `target/stm32f1x.cfg`. |
| **IDE** | STM32CubeIDE (for building the `.elf`). The toolkit itself is IDE-agnostic. |

---

## Project layout

After copying the toolkit into your STM32CubeIDE project root, you get:

```text
MyProject/
  .project
  MyProject.ioc
  Debug/
    MyProject.elf          ← built by STM32CubeIDE
  stm32_openocd_toolkit/
    README.md              ← this file
    SETUP_AND_FLASH.sh      ← main entry: install deps (Linux) + flash
    SETUP_AND_FLASH.bat     ← main entry on Windows
    flash_ch32.sh           ← flash-only script (Linux)
    flash_ch32.bat          ← flash-only script (Windows)
    init.sh                 ← one-time: install OpenOCD + chmod (Linux)
    openocd_ch32_arm.cfg    ← optional OpenOCD config for WCH-Link + CH32 ARM
    tools/
      WCH-Link_Setup.txt   ← one-time WinUSB setup for WCH-Link on Windows
```

- **SETUP_AND_FLASH** scripts: full flow (optional one-time setup + flash). Prefer these for first-time use and daily workflow.
- **flash_ch32** scripts: flash only; assume OpenOCD is already installed and scripts are executable (Linux). Useful for automation or after `init.sh` / manual setup.
- **init.sh** (Linux): installs OpenOCD, sets `OPENOCD_SCRIPTS`, makes scripts executable, then runs `SETUP_AND_FLASH.sh` once.

---

## New project from scratch (create project, clone toolkit, then run setup)

This section is for when you **create a new STM32CubeIDE project**, **clone this toolkit’s Git repo into that project**, and then run the setup/flash scripts.

### Step 1: Create the project in STM32CubeIDE

1. Open **STM32CubeIDE**.
2. **File → New → STM32 Project** (or use the project wizard).
3. Select your MCU/board (e.g. STM32F103 or compatible like CH32F103), set project name and location, finish the wizard.
4. Generate code from the `.ioc` if needed, then **build the project** at least once (Ctrl+B / Project → Build Project) so that `Debug/YourProjectName.elf` is produced.

Your project root will contain `.project`, `*.ioc`, `Core/`, `Debug/`, etc.

### Step 2: Clone the toolkit repo into the project root

Clone this repository **inside** your STM32CubeIDE project directory, so that the toolkit appears as a folder named `stm32_openocd_toolkit` next to `.project`, `Debug/`, etc.

**From your project root** (the directory that contains `.project` and `Debug/`):

**Linux / macOS:**

```bash
cd /path/to/YourStm32Project
git clone https://github.com/armanossiloko/stm32-openocd-flash.git stm32_openocd_toolkit
```

**Windows (cmd):**

```bat
cd C:\path\to\YourStm32Project
git clone https://github.com/armanossiloko/stm32-openocd-flash.git stm32_openocd_toolkit
```

Resulting layout:

```text
YourStm32Project/
  .project
  YourStm32Project.ioc
  Core/
  Debug/
    YourStm32Project.elf
  stm32_openocd_toolkit/    ← cloned here
    README.md
    SETUP_AND_FLASH.sh
    ...
```

Do **not** clone into your workspace root or elsewhere; the scripts expect `stm32_openocd_toolkit` to be inside the **same directory** as `.project` and `Debug/`.

### Step 3: One-time setup and make scripts executable (Linux only)

**Linux:** make the scripts executable (one-time):

```bash
cd stm32_openocd_toolkit
chmod +x SETUP_AND_FLASH.sh flash_ch32.sh
```

Optional: if you want the script to install OpenOCD and run a first flash for you:

```bash
./init.sh
```

(Ensure `init.sh` uses a valid shebang, e.g. `#!/usr/bin/env bash`, for your system.)

**Windows:** no `chmod` needed; ensure OpenOCD is installed and on `PATH` (see [Prerequisites](#prerequisites)).

### Step 4: Wire ST-Link to the board

Connect **SWCLK**, **SWDIO**, **GND**, and optionally **NRST** between the ST-Link and the target board (see [Wiring](#5-wiring-st-link-to-board) below).

### Step 5: Run the setup / flash script

From the **project root** or from inside `stm32_openocd_toolkit`:

**Linux:**

```bash
cd stm32_openocd_toolkit
./SETUP_AND_FLASH.sh
```

**Windows (cmd):**

```bat
cd stm32_openocd_toolkit
SETUP_AND_FLASH.bat
```

If the project name is not detected correctly, pass it explicitly:

```bash
./SETUP_AND_FLASH.sh YourStm32Project
```

```bat
SETUP_AND_FLASH.bat YourStm32Project
```

After this, your **daily workflow** is: build in STM32CubeIDE → run `./SETUP_AND_FLASH.sh` or `SETUP_AND_FLASH.bat` to flash.

---

## Prerequisites

1. **STM32CubeIDE** installed (used only to create and build the project).
2. **OpenOCD** installed and on your `PATH`, with:
   - `interface/stlink.cfg`
   - `target/stm32f1x.cfg`
3. **Hardware**: ST-Link connected to the board (SWCLK, SWDIO, GND; NRST recommended).

---

## Quickstart

Use this on a machine where **STM32CubeIDE is already installed** and you have (or will install) OpenOCD.

### 1. Install OpenOCD

**Linux (Debian / Ubuntu / Mint):**

```bash
sudo apt update
sudo apt install openocd
```

**Linux (Arch):**

```bash
sudo pacman -S openocd
```

**Linux (Fedora):**

```bash
sudo dnf install openocd
```

**Windows:**  
Use a build that includes `interface/stlink.cfg` and `target/stm32f1x.cfg`, for example:

- [xPack OpenOCD](https://github.com/xpack-dev-tools/openocd-xpack/releases), or  
- The OpenOCD bundled with STM32CubeIDE (add its `bin` and script path to `PATH`).

Check:

```bash
openocd --version
```

(Linux/macOS) or `openocd --version` in `cmd` on Windows. If the command is not found, OpenOCD is not on your `PATH`.

---

### 2. OpenOCD scripts path (if required)

If OpenOCD cannot find `interface/stlink.cfg` or `target/stm32f1x.cfg`, set the scripts directory.

**Linux:**  
Scripts are often under `/usr/share/openocd/scripts`. Set:

```bash
export OPENOCD_SCRIPTS=/usr/share/openocd/scripts
```

**Windows (cmd):**

```bat
set OPENOCD_SCRIPTS=C:\path\to\openocd\scripts
```

Examples: `C:\xpack-openocd\share\openocd\scripts`, or the `scripts` directory inside the STM32CubeIDE OpenOCD install.

---

### 3. Create and build your project in STM32CubeIDE

1. Create the project in STM32CubeIDE.  
2. Write your code and build so that `Debug/ProjectName.elf` (or `Release/ProjectName.elf`) exists.

---

### 4. Copy the toolkit into the project

Copy the whole `stm32_openocd_toolkit` folder into the **project root** (same level as `.project`, `*.ioc`, and `Debug/`).

**Linux:** make scripts executable (one-time):

```bash
cd stm32_openocd_toolkit
chmod +x SETUP_AND_FLASH.sh flash_ch32.sh
```

Optional one-time setup that installs OpenOCD and runs the flash script once:

```bash
./init.sh
```

(You may need to fix the shebang in `init.sh` to point to `#!/usr/bin/env bash` or your `bash` path if your system uses a different layout.)

---

### 5. Wiring (ST-Link to board)

- **SWCLK** → **SWCLK**  
- **SWDIO** → **SWDIO**  
- **GND** → **GND**  
- **3.3V** → **3.3V** (if needed)  
- **NRST** → **NRST** (recommended; helps if the chip is stuck)

---

### 6. Flash

**Linux:**

```bash
cd stm32_openocd_toolkit
./SETUP_AND_FLASH.sh
```

If project-name auto-detection fails, pass the name explicitly:

```bash
./SETUP_AND_FLASH.sh MyProjectName
```

**Windows (cmd):**

```bat
cd stm32_openocd_toolkit
SETUP_AND_FLASH.bat MyProjectName
```

Pass the STM32CubeIDE project name explicitly on Windows:

```bat
SETUP_AND_FLASH.bat MyProjectName
```

If you use a custom OpenOCD scripts path, set it before running:

**Linux:**

```bash
export OPENOCD_SCRIPTS=/usr/share/openocd/scripts
cd stm32_openocd_toolkit
./SETUP_AND_FLASH.sh
```

**Windows:**

```bat
set OPENOCD_SCRIPTS=C:\path\to\openocd\scripts
cd stm32_openocd_toolkit
SETUP_AND_FLASH.bat MyProjectName
```

---

### 7. Daily workflow

After each code change:

1. Build in STM32CubeIDE.  
2. From the toolkit directory run:
   - **Linux:** `./SETUP_AND_FLASH.sh`  
   - **Windows:** `SETUP_AND_FLASH.bat MyProjectName`  

No need to reopen the IDE for flashing—just build then run the script.

---

## If flashing fails

- **OpenOCD can’t find config files**  
  Set `OPENOCD_SCRIPTS` (or add OpenOCD’s `scripts` directory to your OpenOCD install/PATH).

- **Chip stuck / first connect fails**  
  - Prefer wiring **NRST** from ST-Link to board NRST and run the script again.  
  - If NRST is not available: put the MCU in bootloader (e.g. **BOOT0 = 1**), flash, then set **BOOT0 = 0** and reset.

- **Linux: permission denied on USB**  
  If `sudo ./SETUP_AND_FLASH.sh` works but your user does not, it’s a udev permission issue for the ST-Link. Add a udev rule for the ST-Link USB VID/PID or run with `sudo` until you fix it.

- **CH32 / clone: “UNEXPECTED idcode” or “expected 1 of 1: 0x1ba01477”**  
  The scripts already set `CPUTAPID 0x2ba01477` for CH32F103-style cores. If you still see this, ensure you’re using the provided `SETUP_AND_FLASH` or `flash_ch32` scripts (they pass the correct OpenOCD options).

---

## WCH-Link (optional)

If you use a **WCH-Link** in ARM/SWD mode instead of an ST-Link:

- **Windows:** One-time driver setup is described in `tools/WCH-Link_Setup.txt`: use Zadig to install **WinUSB** for the WCH-Link (not USB Serial).  
- **OpenOCD:** You need an OpenOCD build that supports the WCH-Link (e.g. `interface/wlink.cfg` or equivalent). The included `openocd_ch32_arm.cfg` is an example config for WCH-Link + CH32 ARM SWD; use it with OpenOCD’s `-f` option if you script your own flash command.

The main `SETUP_AND_FLASH` and `flash_ch32` scripts in this toolkit are written for **ST-Link**; they use `interface/stlink.cfg` and `target/stm32f1x.cfg`. For WCH-Link you would replace the interface config and possibly the script path in your own wrapper or use `openocd_ch32_arm.cfg` as a starting point.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Install OpenOCD (and set `OPENOCD_SCRIPTS` if needed). |
| 2 | Create and build an STM32CubeIDE project so `Debug/ProjectName.elf` exists. |
| 3 | Add the toolkit: **copy** `stm32_openocd_toolkit` into the project root, or **clone** the repo there: `git clone https://github.com/armanossiloko/stm32-openocd-flash.git stm32_openocd_toolkit`. On Linux run `chmod +x SETUP_AND_FLASH.sh flash_ch32.sh`. |
| 4 | Connect ST-Link (SWCLK, SWDIO, GND, optionally NRST). |
| 5 | Run `./SETUP_AND_FLASH.sh` (Linux) or `SETUP_AND_FLASH.bat` (Windows). |

After that, **build in the IDE → run the script** to flash and run.

For a **full step-by-step when creating a new project and cloning the toolkit**, see [New project from scratch (create project, clone toolkit, then run setup)](#new-project-from-scratch-create-project-clone-toolkit-then-run-setup).
