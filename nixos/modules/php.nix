# Pin PHP 8.4 to a patched release (CVE fixes) ahead of nixpkgs.
# Also applies to pkgs.php, php84Packages and php84Extensions.
# Remove once nixpkgs ships >= this version.
{
  nixpkgs.overlays = [
    (final: prev: {
      # packageOverrides can't be used here: php's wrapper binds it at the
      # original call site, so .override ignores it. Instead patch the
      # extension in the enabled list.
      php84 =
        (prev.php84.override {
          version = "8.4.27";
          hash = "sha256-slMKh3xyL0sIyeF0owywi6wrfhkD7m6eMV8KqfX4LCQ=";
        }).withExtensions
          (
            { enabled, ... }:
            map (
              ext:
              # 8.4.27's new tests/oom_filter_*.phpt fail when the extension
              # is built standalone in the nix sandbox.
              if ext.extensionName == "filter" then ext.overrideAttrs { doCheck = false; } else ext
            ) enabled
          );

      # Make sure everything defaulting to pkgs.php (phpfpm pools, wp-cli, ...)
      # gets the patched 8.4 build.
      php = final.php84;
    })
  ];
}
