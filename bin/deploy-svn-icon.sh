#!/usr/bin/env bash
set -euo pipefail

PLUGIN_SLUG="${PLUGIN_SLUG:-nr-post-exporter}"
SVN_URL="${SVN_URL:-https://plugins.svn.wordpress.org/${PLUGIN_SLUG}/}"
SOURCE_ICON="${SOURCE_ICON:-assets/icon.svg}"
SVN_WORKDIR="${SVN_WORKDIR:-}"
SVN_COMMIT_MSG="${SVN_COMMIT_MSG:-Add plugin icon}"

info() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*" 1>&2; }

if [[ ! -f "${SOURCE_ICON}" ]]; then
  err "Missing ${SOURCE_ICON}. Ensure the SVG exists in the repo assets directory."
  exit 1
fi

if ! command -v svn >/dev/null 2>&1; then
  err "svn is required but not installed."
  exit 1
fi

cleanup() {
  if [[ -n "${SVN_WORKDIR}" && -d "${SVN_WORKDIR}" && "${SVN_WORKDIR}" == /tmp/* ]]; then
    rm -rf "${SVN_WORKDIR}"
  fi
}
trap cleanup EXIT

if [[ -z "${SVN_WORKDIR}" ]]; then
  SVN_WORKDIR="$(mktemp -d -t "${PLUGIN_SLUG}-svn.XXXXXX")"
fi

info "Checking out ${SVN_URL} into ${SVN_WORKDIR}"
svn checkout "${SVN_URL}" "${SVN_WORKDIR}"

mkdir -p "${SVN_WORKDIR}/assets"
cp "${SOURCE_ICON}" "${SVN_WORKDIR}/assets/icon.svg"

info "Adding icon.svg to SVN assets"
svn add --force "${SVN_WORKDIR}/assets/icon.svg" >/dev/null

info "Committing icon.svg to SVN"
svn commit -m "${SVN_COMMIT_MSG}" "${SVN_WORKDIR}/assets/icon.svg"
