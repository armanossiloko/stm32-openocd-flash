#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
if [[ -f "$SCRIPT_DIR/../.project" ]]; then
  PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$PROJECT_DIR"

PROJECT_NAME="${1:-Stm32Project}"
if [[ $# -eq 0 ]]; then
  if [[ -f ".project" ]]; then
    detected_name="$(sed -n 's:.*<name>\([^<][^<]*\)</name>.*:\1:p' .project | head -n1)"
    if [[ -n "$detected_name" ]]; then
      PROJECT_NAME="$detected_name"
    fi
  fi
  if [[ "$PROJECT_NAME" == "Stm32Project" ]]; then
    for f in *.ioc; do
      if [[ -f "$f" ]]; then
        PROJECT_NAME="${f%.ioc}"
        break
      fi
    done
  fi
fi

OPENOCD_CMD=(openocd)
if [[ -n "${OPENOCD_SCRIPTS:-}" ]]; then
  OPENOCD_CMD=(openocd -s "$OPENOCD_SCRIPTS")
fi

ELF_PATH="Debug/${PROJECT_NAME}.elf"
if [[ ! -f "Debug/${PROJECT_NAME}.elf" && -f "Release/${PROJECT_NAME}.elf" ]]; then
  ELF_PATH="Release/${PROJECT_NAME}.elf"
fi

if [[ ! -f "$ELF_PATH" ]]; then
  echo "Error: $ELF_PATH not found. Build the project in STM32CubeIDE first."
  exit 1
fi

# CH32/CS32 (and STM32F1 clones) use idcode 0x2ba01477; STM32F1 SW-DP is 0x1ba01477
OPENOCD_EXTRA=(-c "set CPUTAPID 0x2ba01477")

echo "Flashing $ELF_PATH to CH32..."
"${OPENOCD_CMD[@]}" "${OPENOCD_EXTRA[@]}" -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program $ELF_PATH verify reset exit"
status=$?

if [[ $status -ne 0 ]]; then
  echo
  echo "Retry with NRST held during connect..."
  "${OPENOCD_CMD[@]}" "${OPENOCD_EXTRA[@]}" -f interface/stlink.cfg -c "reset_config srst_only srst_nogate connect_assert_srst" -f target/stm32f1x.cfg -c "program $ELF_PATH verify reset exit"
  status=$?
fi

if [[ $status -ne 0 ]]; then
  echo
  echo "Flash failed."
  echo "If old code is still running, wire ST-Link NRST to board NRST and run this again."
  echo "Keep SWDIO, SWCLK, GND, and NRST connected."
  exit 1
fi

echo "Done. Device should be running."
