#!/usr/bin/env bash
set -euo pipefail

# 一键无损更新 Bbot：
# - 备份 openclaw.json
# - 停止网关
# - 清理旧插件目录（不删除配置）
# - 安装指定版本或 latest
# - 启动网关并输出状态

PKG="@hmjbill/bbot"
VER="${1:-latest}"
SCRIPT_REPO_RAW="https://raw.githubusercontent.com/hmjBill/Bbot-releases/main"
MANIFEST_URL="${SCRIPT_REPO_RAW}/manifest.json"
OPENCLAW_HOME="${HOME}/.openclaw"
CFG="${OPENCLAW_HOME}/openclaw.json"
EXT="${OPENCLAW_HOME}/extensions/bbot"
TS="$(date +%Y%m%d-%H%M%S)"
BAK="${OPENCLAW_HOME}/openclaw.json.bak.${TS}"
TMP_ONEBOT="${OPENCLAW_HOME}/.onebot-channel.tmp.${TS}.json"
TMP_PKG="${OPENCLAW_HOME}/.bbot-plugin.tmp.${TS}.tgz"
INSTALLED_PKG_JSON="${EXT}/package.json"
RESOLVED_VER=""
TARBALL_URL=""
EXPECTED_SHA256=""

# ── 自动检测 CLI 命令（支持 BClaw 和 OpenClaw） ──
if command -v bclaw >/dev/null 2>&1; then
  CLI="bclaw"
elif command -v openclaw >/dev/null 2>&1; then
  CLI="openclaw"
else
  echo "未找到 bclaw 或 openclaw 命令，请先安装 BClaw 或 OpenClaw。"
  exit 1
fi

step() { printf '[onebot-update] %s\n' "$*"; }

cleanup_tmp() {
  rm -f "${TMP_ONEBOT}" >/dev/null 2>&1 || true
  rm -f "${TMP_PKG}" >/dev/null 2>&1 || true
}
trap cleanup_tmp EXIT

sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${file}" | awk '{print $1}'
  else
    echo "无法计算 SHA256：请安装 sha256sum 或 shasum" >&2
    exit 1
  fi
}

resolve_manifest() {
  local manifest_json manifest_result
  manifest_json="$(curl -fsSL "${MANIFEST_URL}")"
  manifest_result="$(
    node -e '
      const manifest = JSON.parse(process.argv[1]);
      const req = process.argv[2];
      const resolved = req === "latest" ? manifest.latest : req;
      if (!resolved) {
        throw new Error("manifest 缺少 latest");
      }
      const entry = manifest.versions?.[resolved];
      if (!entry) {
        throw new Error(`manifest 未包含版本 ${resolved}`);
      }
      if (!entry.tarballUrl || !entry.sha256) {
        throw new Error(`manifest 版本 ${resolved} 缺少 tarballUrl 或 sha256`);
      }
      process.stdout.write(`${resolved}\n${entry.tarballUrl}\n${String(entry.sha256).toLowerCase()}\n`);
    ' "${manifest_json}" "${VER}"
  )"
  RESOLVED_VER="$(printf '%s\n' "${manifest_result}" | sed -n '1p')"
  TARBALL_URL="$(printf '%s\n' "${manifest_result}" | sed -n '2p')"
  EXPECTED_SHA256="$(printf '%s\n' "${manifest_result}" | sed -n '3p')"
}

download_and_verify_package() {
  step "读取版本清单 -> ${MANIFEST_URL}"
  resolve_manifest
  step "下载插件包 -> ${TARBALL_URL}"
  curl -fsSL "${TARBALL_URL}" -o "${TMP_PKG}"

  local actual_sha256
  actual_sha256="$(sha256_file "${TMP_PKG}" | tr '[:upper:]' '[:lower:]')"
  if [ "${actual_sha256}" != "${EXPECTED_SHA256}" ]; then
    echo "插件包哈希校验失败：expected=${EXPECTED_SHA256} actual=${actual_sha256}" >&2
    exit 1
  fi
  step "插件包哈希校验通过（${RESOLVED_VER}）"
}

sanitize_config_for_install() {
  [ -f "${CFG}" ] || return 0
  node - "${CFG}" "${TMP_ONEBOT}" <<'NODE'
const fs = require('fs');
const [cfgPath, tempPath] = process.argv.slice(2);
const raw = fs.readFileSync(cfgPath, 'utf8');
const cfg = JSON.parse(raw);

const onebotChannel = cfg?.channels?.onebot;
if (onebotChannel !== undefined) {
  fs.writeFileSync(tempPath, JSON.stringify(onebotChannel, null, 2));
}

if (cfg.channels && Object.prototype.hasOwnProperty.call(cfg.channels, 'onebot')) {
  delete cfg.channels.onebot;
}

if (cfg.plugins && Array.isArray(cfg.plugins.allow)) {
  cfg.plugins.allow = cfg.plugins.allow.filter(
    (item) => !['bbot', 'openclaw-onebot', '@hmjbill/bbot', '@hmjbill/openclaw-onebot'].includes(String(item))
  );
}

if (cfg.plugins && cfg.plugins.entries && typeof cfg.plugins.entries === 'object') {
  delete cfg.plugins.entries['bbot'];
  delete cfg.plugins.entries['openclaw-onebot'];
  delete cfg.plugins.entries['@hmjbill/bbot'];
  delete cfg.plugins.entries['@hmjbill/openclaw-onebot'];
}

fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
NODE
}

restore_onebot_channel_config() {
  [ -f "${CFG}" ] || return 0
  [ -f "${TMP_ONEBOT}" ] || return 0
  node - "${CFG}" "${TMP_ONEBOT}" <<'NODE'
const fs = require('fs');
const [cfgPath, tempPath] = process.argv.slice(2);
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const onebot = JSON.parse(fs.readFileSync(tempPath, 'utf8'));

if (!cfg.channels || typeof cfg.channels !== 'object') {
  cfg.channels = {};
}
cfg.channels.onebot = onebot;

if (!cfg.plugins || typeof cfg.plugins !== 'object') {
  cfg.plugins = {};
}
if (!Array.isArray(cfg.plugins.allow)) {
  cfg.plugins.allow = [];
}
if (!cfg.plugins.allow.includes('bbot')) {
  cfg.plugins.allow.push('bbot');
}

fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
NODE
}

sync_install_metadata() {
  [ -f "${CFG}" ] || return 0
  [ -f "${INSTALLED_PKG_JSON}" ] || return 0
  node - "${CFG}" "${INSTALLED_PKG_JSON}" "${EXT}" <<'NODE'
const fs = require('fs');
const [cfgPath, pkgPath, installPath] = process.argv.slice(2);
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const now = new Date().toISOString();

if (!cfg.plugins || typeof cfg.plugins !== 'object') cfg.plugins = {};
if (!cfg.plugins.installs || typeof cfg.plugins.installs !== 'object') cfg.plugins.installs = {};

const current = cfg.plugins.installs['bbot'] || cfg.plugins.installs['openclaw-onebot'] || {};
const merged = {
  ...current,
  source: 'npm',
  spec: '@hmjbill/bbot',
  installPath,
  version: pkg.version,
  resolvedName: '@hmjbill/bbot',
  resolvedVersion: pkg.version,
  resolvedSpec: `@hmjbill/bbot@${pkg.version}`,
  installedAt: now
};

cfg.plugins.installs['bbot'] = merged;
delete cfg.plugins.installs['openclaw-onebot'];
fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
NODE
}

step "使用 CLI: ${CLI}"

if [ -f "${CFG}" ]; then
  step "备份配置 -> ${BAK}"
  cp "${CFG}" "${BAK}"
else
  step "未发现 ${CFG}，跳过配置备份"
fi

step "停止网关"
# 避免网关 stop 在部分环境阻塞，直接按进程名终止
pkill -f 'openclaw-gateway' >/dev/null 2>&1 || true
pkill -f 'bclaw-gateway' >/dev/null 2>&1 || true
pkill -f '[o]penclaw gateway' >/dev/null 2>&1 || true
pkill -f '[b]claw gateway' >/dev/null 2>&1 || true

step "临时清理冲突配置（安装后自动恢复）"
sanitize_config_for_install

step "清理旧插件目录（无交互） -> ${EXT}"
rm -rf "${EXT}"

install_plugin() {
  "${CLI}" plugins install "${TMP_PKG}"
}

download_and_verify_package

step "安装版本 ${PKG}@${RESOLVED_VER}"

if ! install_plugin; then
  step "安装失败，尝试自动修复配置并重试"
  "${CLI}" doctor --fix || true
  install_plugin
fi

step "恢复 onebot 渠道配置"
restore_onebot_channel_config

step "同步插件安装元数据"
sync_install_metadata

step "启动网关"
"${CLI}" gateway start

step "当前状态"
"${CLI}" status || true

step "更新完成（配置未改动，备份: ${BAK}）"
