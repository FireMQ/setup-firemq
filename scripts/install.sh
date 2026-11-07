#!/usr/bin/env bash
# Installs firemq into a folder on PATH, from a release or from source.
set -euo pipefail

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) target=x86_64-unknown-linux-musl ;;
  Linux-aarch64 | Linux-arm64) target=aarch64-unknown-linux-musl ;;
  Darwin-arm64) target=aarch64-apple-darwin ;;
  Darwin-x86_64) target=x86_64-apple-darwin ;;
  MINGW* | MSYS* | CYGWIN*) target=x86_64-pc-windows-msvc ;;
  *) echo "::error::FireMQ has no build for $(uname -s) $(uname -m)"; exit 1 ;;
esac

if [ -n "$REF" ]; then
  root="$RUNNER_TEMP/firemq-src-$REF"
  if [ ! -x "$root/bin/firemq" ] && [ ! -x "$root/bin/firemq.exe" ]; then
    if [[ $REF =~ ^[0-9a-f]{7,40}$ ]]; then how=(--rev "$REF")
    elif [[ $REF =~ ^v[0-9] ]]; then how=(--tag "$REF")
    else how=(--branch "$REF"); fi
    echo "Building FireMQ from source at $REF"
    cargo install --locked --quiet --git https://github.com/FireMQ/firemq "${how[@]}" --root "$root" firemq
  fi
  echo "$root/bin" >> "$GITHUB_PATH"
  exit 0
fi

if [ "$VERSION" = latest ]; then
  base=https://github.com/FireMQ/firemq/releases/latest/download
else
  base="https://github.com/FireMQ/firemq/releases/download/$VERSION"
fi
ext=tar.gz
[ "$target" = x86_64-pc-windows-msvc ] && ext=zip
file="firemq-$target.$ext"
dir="$RUNNER_TEMP/firemq-$VERSION"
mkdir -p "$dir"
cd "$dir"
echo "Downloading $base/$file"
curl -fsSL --retry 3 -o "$file" "$base/$file"
curl -fsSL --retry 3 -o "$file.sha256" "$base/$file.sha256"
expected=$(awk '{print $1}' "$file.sha256")
if command -v sha256sum >/dev/null; then actual=$(sha256sum "$file" | awk '{print $1}')
else actual=$(shasum -a 256 "$file" | awk '{print $1}'); fi
if [ "$expected" != "$actual" ]; then
  echo "::error::Checksum mismatch for $file"
  exit 1
fi
if [ "$ext" = zip ]; then unzip -q -o "$file"; else tar -xzf "$file"; fi
echo "$dir/firemq-$target" >> "$GITHUB_PATH"
