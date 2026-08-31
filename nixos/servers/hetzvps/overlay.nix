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
        inherit (pkgs) netdata netdataCloud;
        inherit (inputs.lgl-site.packages.${system}) ladugard-live;
        inherit (inputs.calc-api.packages.${system}) calc-api;
        inherit (inputs.handy-gleam.packages.${system}) handygleam;
        inherit (inputs.conversions.packages.${system}) conversions conversions-frontend;
        inherit (inputs.website-for-friends.packages.${system}) bedrock-wp;
        inherit (inputs.strapi.packages.${system}) next;
        github-doc-sync = inputs.github-docs.packages.${system}.default;
        strapiHashProd = inputs.strapi.strapiHash.${system};
      }
    )
  ];
}
