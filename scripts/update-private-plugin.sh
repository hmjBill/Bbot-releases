#!/usr/bin/env bash
set -euo pipefail

# 私有源无损更新 Bbot（需要本机已配置 npm 私有仓库访问权限）：
# - 备份 openclaw.json
# - 停止网关
# - 清理旧插件目录（不删除配置）
# - 安装私有包指定版本或 dev（默认）
# - 启动网关并输出状态

PKG="${BBOT_PRIVATE_PKG:-@hmjbill/bbot-private}"
VER="${1:-dev}"
OPENCLAW_HOME="${HOME}/.openclaw"
CFG="${OPENCLAW_HOME}/openclaw.json"
EXT="${OPENCLAW_HOME}/extensions/bbot"
TS="$(date +%Y%m%d-%H%M%S)"
BAK="${OPENCLAW_HOME}/openclaw.json.bak.${TS}"
TMP_ONEBOT="${OPENCLAW_HOME}/.onebot-channel.tmp.${TS}.json"
INSTALLED_PKG_JSON="${EXT}/package.json"

step() { printf '[onebot-private-update] %s\n' "$*"; }

cleanup_tmp() {
  rm -f "${TMP_ONEBOT}" >/dev/null 2>&1 || true
}
trap cleanup_tmp EXIT

sanitize_config_for_install() {
  [ -f "${CFG}" ] || return 0
  node - "${CFG}" "${TMP_ONEBOT}" "${PKG}" <<'NODE'
const fs = require('fs');
const [cfgPath, tempPath, pkgName] = process.argv.slice(2);
const raw = fs.readFileSync(cfgPath, 'utf8');
const cfg = JSON.parse(raw);

const onebotChannel = cfg?.channels?.onebot;
if (onebotChannel !== undefined) fs.writeFileSync(tempPath, JSON.stringify(onebotChannel, null, 2));

if (cfg.channels && Object.prototype.hasOwnProperty.call(cfg.channels, 'onebot')) delete cfg.channels.onebot;

const cleanupNames = new Set(['bbot', 'openclaw-onebot', '@hmjbill/bbot', '@hmjbill/openclaw-onebot', pkgName]);
if (cfg.plugins && Array.isArray(cfg.plugins.allow)) {
  cfg.plugins.allow = cfg.plugins.allow.filter((item) => !cleanupNames.has(String(item)));
}
if (cfg.plugins && cfg.plugins.entries && typeof cfg.plugins.entries === 'object') {
  for (const name of cleanupNames) delete cfg.plugins.entries[name];
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

if (!cfg.channels || typeof cfg.channels !== 'object') cfg.channels = {};
cfg.channels.onebot = onebot;

if (!cfg.plugins || typeof cfg.plugins !== 'object') cfg.plugins = {};
if (!Array.isArray(cfg.plugins.allow)) cfg.plugins.allow = [];
if (!cfg.plugins.allow.includes('bbot')) cfg.plugins.allow.push('bbot');

fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
NODE
}

sync_install_metadata() {
  [ -f "${CFG}" ] || return 0
  [ -f "${INSTALLED_PKG_JSON}" ] || return 0
  node - "${CFG}" "${INSTALLED_PKG_JSON}" "${EXT}" "${PKG}" <<'NODE'
const fs = require('fs');
const [cfgPath, pkgPath, installPath, pkgName] = process.argv.slice(2);
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const now = new Date().toISOString();

if (!cfg.plugins || typeof cfg.plugins !== 'object') cfg.plugins = {};
if (!cfg.plugins.installs || typeof cfg.plugins.installs !== 'object') cfg.plugins.installs = {};

const current = cfg.plugins.installs['bbot'] || cfg.plugins.installs['openclaw-onebot'] || {};
const merged = {
  ...current,
  source: 'npm',
  spec: pkgName,
  installPath,
  version: pkg.version,
  resolvedName: pkgName,
  resolvedVersion: pkg.version,
  resolvedSpec: `${pkgName}@${pkg.version}`,
  installedAt: now
};
cfg.plugins.installs['bbot'] = merged;
delete cfg.plugins.installs['openclaw-onebot'];
fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
NODE
}

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw 命令不存在，请先安装 OpenClaw。"
  exit 1
fi

if [ -f "${CFG}" ]; then
  step "备份配置 -> ${BAK}"
  cp "${CFG}" "${BAK}"
else
  step "未发现 ${CFG}，跳过配置备份"
fi

step "停止网关"
pkill -f 'openclaw-gateway' >/dev/null 2>&1 || true
pkill -f '[o]penclaw gateway' >/dev/null 2>&1 || true

step "临时清理冲突配置（安装后自动恢复）"
sanitize_config_for_install

step "清理旧插件目录（无交互） -> ${EXT}"
rm -rf "${EXT}"

install_plugin() {
  if [ "${VER}" = "latest" ] || [ "${VER}" = "dev" ]; then
    # OpenClaw 对预发布要求显式声明 tag 或版本，这里固定使用 dev tag
    openclaw plugins install "${PKG}@dev"
  else
    openclaw plugins install "${PKG}@${VER}"
  fi
}

if [ "${VER}" = "latest" ] || [ "${VER}" = "dev" ]; then
  step "安装私有最新 dev 版本 ${PKG}@dev"
else
  step "安装私有指定版本 ${PKG}@${VER}"
fi

if ! install_plugin; then
  step "安装失败，尝试自动修复配置并重试"
  openclaw doctor --fix || true
  install_plugin
fi

step "恢复 onebot 渠道配置"
restore_onebot_channel_config

step "同步插件安装元数据"
sync_install_metadata

step "启动网关"
openclaw gateway start

step "当前状态"
openclaw status || true

step "私有更新完成（配置未改动，备份: ${BAK}）"
