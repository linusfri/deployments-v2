{ inputs, ... }:
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        inherit (prev.stdenv) system;
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
      in
      {

      }
    )
  ];
}
