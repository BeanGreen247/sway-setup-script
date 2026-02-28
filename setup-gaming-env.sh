#!/bin/bash
# setup-gaming-env.sh
# Sets up shader cache directories and writes gaming performance variables
# to /etc/environment for system-wide availability.
#
# Steam/Lutris launch options (ProtonGE):
#   CLUTTER_VBLANK=none MESA_GLSL_CACHE_ENABLE=true ... gamemoderun mangohud %command%
#
# For linux-native titles, omit DXVK_ASYNC=1.
# For CP2077, append: --launcher-skip --skip-launcher -skipStartscreen
#
# Usage: sudo bash setup-gaming-env.sh

set -e

# ---------------------------------------------------------------------------
# Resolve the real (non-root) user — works whether called via sudo or directly
# ---------------------------------------------------------------------------
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || id -un)}"
if [[ -z "${REAL_USER}" || "${REAL_USER}" == "root" ]]; then
    read -rp "Enter the username to configure shader cache for: " REAL_USER
fi
REAL_HOME=$(getent passwd "${REAL_USER}" | cut -d: -f6)
if [[ -z "${REAL_HOME}" ]]; then
    echo "Error: could not determine home directory for user '${REAL_USER}'."
    exit 1
fi
echo "==> Configuring for user: ${REAL_USER} (home: ${REAL_HOME})"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SHADER_CACHE_ROOT="${REAL_HOME}/Shader_CACHE"
MESA_CACHE_DIR="${SHADER_CACHE_ROOT}/MESA_SHADER_CACHE"
GL_CACHE_DIR="${SHADER_CACHE_ROOT}/GL_SHADER_DISK_CACHE"
DXVK_CACHE_DIR="${SHADER_CACHE_ROOT}/DXVK_State_Cache"
ORIGIN_CACHE_DIR="${MESA_CACHE_DIR}/shadercacheOriginSteam"

ETC_ENV="/etc/environment"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Add or update a KEY=VALUE line in /etc/environment.
# If the key already exists it is replaced; otherwise the line is appended.
set_env_var() {
    local key="$1"
    local value="$2"
    local line="${key}=${value}"

    if grep -qE "^${key}=" "${ETC_ENV}" 2>/dev/null; then
        # Replace existing entry — escape $ so sed does not expand $LIB etc.
        local escaped_line="${line//\$/\\$}"
        sed -i "s|^${key}=.*|${escaped_line}|" "${ETC_ENV}"
        echo "  updated : ${line}"
    else
        echo "${line}" >> "${ETC_ENV}"
        echo "  appended: ${line}"
    fi
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)."
    exit 1
fi

# ---------------------------------------------------------------------------
# 0. Install gamemode multiarch packages
#    libgamemodeauto0:i386 is required so that LD_PRELOAD works for 32-bit
#    processes (Wine / Proton games). Without it gamemoderun silently fails
#    for 32-bit titles even though it appears to launch fine.
# ---------------------------------------------------------------------------
echo ""
echo "==> Installing gamemode multiarch packages…"
dpkg --add-architecture i386
apt-get update -qq
apt-get install -y \
    gamemode \
    libgamemode0 \
    libgamemodeauto0 \
    libgamemode0:i386 \
    libgamemodeauto0:i386
echo "  done"

# ---------------------------------------------------------------------------
# 1. Create shader cache directories
# ---------------------------------------------------------------------------
echo ""
echo "==> Creating shader cache directories…"

for dir in \
    "${SHADER_CACHE_ROOT}" \
    "${MESA_CACHE_DIR}" \
    "${GL_CACHE_DIR}" \
    "${DXVK_CACHE_DIR}" \
    "${ORIGIN_CACHE_DIR}"
do
    if [[ -d "${dir}" ]]; then
        echo "  exists  : ${dir}"
    else
        mkdir -p "${dir}"
        chown "${REAL_USER}:${REAL_USER}" "${dir}"
        echo "  created : ${dir}"
    fi
done
# Ensure ownership on all cache dirs regardless
chown -R "${REAL_USER}:${REAL_USER}" "${SHADER_CACHE_ROOT}"

# ---------------------------------------------------------------------------
# 2. Back up /etc/environment
# ---------------------------------------------------------------------------
echo ""
echo "==> Backing up ${ETC_ENV} → ${ETC_ENV}.bak"
cp -f "${ETC_ENV}" "${ETC_ENV}.bak" 2>/dev/null || touch "${ETC_ENV}"
echo "  done"

# ---------------------------------------------------------------------------
# 3. Write gaming environment variables to /etc/environment
# ---------------------------------------------------------------------------
echo ""
echo "==> Writing gaming env vars to ${ETC_ENV}…"

# Disable vblank synchronisation (removes screen-tear stutter in many games)
set_env_var "CLUTTER_VBLANK"            "none"
set_env_var "vblank_mode"               "0"

# Mesa / OpenGL shader cache
set_env_var "MESA_GLSL_CACHE_ENABLE"    "true"
set_env_var "MESA_GLSL_CACHE_DIR"       "${MESA_CACHE_DIR}"
set_env_var "MESA_SHADER_CACHE_DISABLE" "false"
set_env_var "MESA_SHADER_CACHE_DIR"     "${MESA_CACHE_DIR}"
set_env_var "MESA_SHADER_CACHE_MAX_SIZE" "160G"
set_env_var "mesa_glthread"             "true"

# NVIDIA / GL shader disk cache
set_env_var "__GL_THREADED_OPTIMIZATIONS" "1"
set_env_var "__GL_SHADER_DISK_CACHE"    "1"
set_env_var "__GL_SHADER_DISK_CACHE_PATH" "${GL_CACHE_DIR}"

# NOTE: LD_PRELOAD is intentionally NOT set in /etc/environment.
# PAM does not perform $LIB shell expansion, so the literal string
# "/usr/$LIB/libgamemodeauto.so.0" gets preloaded for every process
# (including login shells / TTY sessions), causing "gamemodeauto:" messages
# on every login.  Use "gamemoderun %command%" in Steam / Lutris launch
# options instead — that is the correct per-game invocation path.

# DXVK state cache + async shader compilation
set_env_var "DXVK_ASYNC"               "1"
set_env_var "DXVK_STATE_CACHE"          "1"
set_env_var "DXVK_STATE_CACHE_PATH"     "${DXVK_CACHE_DIR}"

# ---------------------------------------------------------------------------
# 4. Print current /etc/environment for review
# ---------------------------------------------------------------------------
echo ""
echo "==> Current ${ETC_ENV}:"
cat "${ETC_ENV}"

# ---------------------------------------------------------------------------
# 5. Reminder: Steam / Lutris per-game launch options
# ---------------------------------------------------------------------------
# Use a regular string (not heredoc) so ${MESA_CACHE_DIR} etc. expand correctly
echo ""
echo "==> Steam / Lutris launch option strings (copy-paste as needed)"
echo "--------------------------------------------------------------------"
echo "# ProtonGE / Windows titles:"
echo "CLUTTER_VBLANK=none MESA_GLSL_CACHE_ENABLE=true MESA_GLSL_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_DISABLE=false MESA_SHADER_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_MAX_SIZE=160G DXVK_ASYNC=1 DXVK_STATE_CACHE=1 DXVK_STATE_CACHE_PATH=${DXVK_CACHE_DIR}/ __GL_THREADED_OPTIMIZATIONS=1 __GL_SHADER_DISK_CACHE_PATH=${GL_CACHE_DIR}/ __GL_SHADER_DISK_CACHE=1 vblank_mode=0 mesa_glthread=true gamemoderun mangohud %command%"
echo ""
echo "# Linux-native titles (no DXVK_ASYNC):"
echo "CLUTTER_VBLANK=none MESA_GLSL_CACHE_ENABLE=true MESA_GLSL_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_DISABLE=false MESA_SHADER_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_MAX_SIZE=160G DXVK_STATE_CACHE=1 DXVK_STATE_CACHE_PATH=${DXVK_CACHE_DIR}/ __GL_THREADED_OPTIMIZATIONS=1 __GL_SHADER_DISK_CACHE_PATH=${GL_CACHE_DIR}/ __GL_SHADER_DISK_CACHE=1 vblank_mode=0 mesa_glthread=true gamemoderun mangohud %command%"
echo ""
echo "# Cyberpunk 2077 (adds launcher-skip flags):"
echo "CLUTTER_VBLANK=none MESA_GLSL_CACHE_ENABLE=true MESA_GLSL_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_DISABLE=false MESA_SHADER_CACHE_DIR=${MESA_CACHE_DIR}/ MESA_SHADER_CACHE_MAX_SIZE=160G DXVK_STATE_CACHE=1 DXVK_STATE_CACHE_PATH=${DXVK_CACHE_DIR}/ __GL_SHADER_DISK_CACHE_PATH=${GL_CACHE_DIR}/ __GL_THREADED_OPTIMIZATIONS=1 __GL_SHADER_DISK_CACHE=1 DXVK_ASYNC=1 vblank_mode=0 mesa_glthread=true gamemoderun mangohud %command% --launcher-skip --skip-launcher -skipStartscreen"
echo "--------------------------------------------------------------------"
echo ""
echo "==> Monitor shader cache disk usage with:"
echo "    watch -n 1 du -h --max-depth=1 ${SHADER_CACHE_ROOT}/"
echo ""
echo "==> Done. A reboot (or re-login) is required for /etc/environment changes to take effect."
