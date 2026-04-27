#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
package_dir="$repo_root/macos/CodexAuthStatusBar"
app_dir="$repo_root/dist/CodexAuthStatusBar.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"

cd "$package_dir"
swift build -c release --product CodexAuthStatusBar

binary_path="$package_dir/.build/release/CodexAuthStatusBar"
if [ ! -x "$binary_path" ]; then
  binary_path=$(find "$package_dir/.build" -path "*/release/CodexAuthStatusBar" -type f -perm -111 | head -n 1)
fi

if [ ! -x "$binary_path" ]; then
  echo "CodexAuthStatusBar release binary was not found." >&2
  exit 1
fi

rm -rf "$app_dir"
mkdir -p "$macos_dir"
cp "$binary_path" "$macos_dir/CodexAuthStatusBar"
chmod +x "$macos_dir/CodexAuthStatusBar"

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>CodexAuthStatusBar</string>
  <key>CFBundleIdentifier</key>
  <string>com.loongphy.codex-auth.statusbar</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Codex Auth</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf "APPL????" > "$contents_dir/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$app_dir" >/dev/null 2>&1 || true
fi

echo "$app_dir"
