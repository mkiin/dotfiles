{
  config,
  lib,
  pkgs,
  ...
}:
let
  dmg = "${config.home.homeDirectory}/.local/share/fonts/SF-Pro.dmg";
  fontDir = "${config.home.homeDirectory}/.local/share/fonts/sf-pro";
  stamp = "${fontDir}/.source-hash";
in
{
  home.activation.installSfPro = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${dmg}" ]; then
      echo "SF Pro: ${dmg} not found; skipping"
    else
      current_hash="$(${pkgs.coreutils}/bin/sha256sum "${dmg}" | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
      installed_hash=""

      if [ -f "${stamp}" ]; then
        installed_hash="$(${pkgs.coreutils}/bin/cat "${stamp}")"
      fi

      if [ "$current_hash" != "$installed_hash" ]; then
        echo "SF Pro: installing from SF-Pro.dmg"

        workdir="$(${pkgs.coreutils}/bin/mktemp -d)"
        trap '${pkgs.coreutils}/bin/rm -rf "$workdir"' EXIT

        cd "$workdir"

        ${pkgs.p7zip}/bin/7z x "${dmg}" >/dev/null

        if [ ! -f 'Payload~' ]; then
          echo "SF Pro: Payload~ not found"
          exit 1
        fi

        ${pkgs.coreutils}/bin/mkdir -p payload
        cd payload

        ${pkgs.cpio}/bin/cpio -id \
          './Library/Fonts/SF-Pro-Text-*.otf' \
          < ../'Payload~'

        ${pkgs.coreutils}/bin/rm -rf "${fontDir}"
        ${pkgs.coreutils}/bin/mkdir -p "${fontDir}"

        ${pkgs.coreutils}/bin/cp \
          ./Library/Fonts/SF-Pro-Text-*.otf \
          "${fontDir}/"

        printf '%s\n' "$current_hash" > "${stamp}"

        ${pkgs.fontconfig}/bin/fc-cache -f "${fontDir}"

        echo "SF Pro: installed"
      else
        echo "SF Pro: already up to date"
      fi
    fi
  '';
}
