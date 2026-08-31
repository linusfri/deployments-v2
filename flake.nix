{
  description = "OpenTofu-provisioned NixOS hosts installed with nixos-anywhere and deployed with deploy-rs";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    arion.url = "github:hercules-ci/arion";

    lgl-site.url = "git+ssh://git@github.com/linusfri/ladugardLive";
    strapi.url = "git+ssh://git@github.com/linusfri/strapi_docknix";
    calc-api.url = "git+ssh://git@github.com/linusfri/calc_api";
    handy-gleam.url = "git+ssh://git@github.com/linusfri/handy-gleam";
    conversions.url = "git+ssh://git@github.com/linusfri/conversions";
    website-for-friends.url = "github:linusfri/website-for-friends";
    github-docs.url = "git+ssh://git@github.com/linusfri/html";
    schoolity-portal = {
      url = "git+ssh://git@github.com/skaggetse/schoolity-portal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mailserver.url = "git+https://gitlab.com/simple-nixos-mailserver/nixos-mailserver.git?ref=nixos-26.05";

    devops-templates.url = "github:ts1997/devops-templates?ref=feat/migrate_to_native_process_manager";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      disko,
      nixos-anywhere,
      deploy-rs,
      agenix,
      agenix-rekey,
      arion,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      infrastructure = import ./lib/infrastructure.nix { inherit lib; };

      mkHost =
        name:
        let
          node = infrastructure.nodes.${name};
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs node;
            inherit (infrastructure) nodes;
            infrastructureMeta = infrastructure.meta;
          };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            agenix-rekey.nixosModules.default
            arion.nixosModules.arion
            ./nixos/servers/${name}/disk-config.nix
            ./nixos/servers/${name}
          ];
        };

      hostNames = builtins.attrNames infrastructure.nodes;
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      deploy = {
        nodes = lib.genAttrs hostNames (
          name:
          let
            node = infrastructure.nodes.${name};
          in
          {
            hostname = node.ip;
            sshUser = "root";
            profiles.system = {
              user = "root";
              path = deploy-rs.lib.${system}.activate.nixos nixosConfigurations.${name};
            };
          }
        );
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ agenix-rekey.overlays.default ];
      };
      workflows = import ./scripts/workflow.nix { inherit pkgs; };
    in
    {
      inherit deploy nixosConfigurations;
      infrastructure.nodes = infrastructure.nodes;

      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations // {
          tofuTokens = lib.nixosSystem {
            inherit system;
            modules = [
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
              {
                age.rekey = {
                  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf9Wqvahm9Fm2twattmjSccCLsqpqMHrIft868NWaAd";
                  masterIdentities = import ./secrets/master-identity.nix;
                  storageMode = "local";
                  localStorageDir = ./secrets/rekeyed/tofu-tokens;
                };
                age.secrets.tokens.rekeyFile = ./secrets/tofu-tokens/tokens.json.age;
              }
            ];
          };
        };
        agePackage = p: p.age;
      };

      checks.${system} =
        deploy-rs.lib.${system}.deployChecks deploy
        // lib.mapAttrs' (
          name: configuration: lib.nameValuePair "nixos-${name}" configuration.config.system.build.toplevel
        ) nixosConfigurations;

      apps.${system} = {
        default = {
          type = "app";
          program = lib.getExe deploy-rs.packages.${system}.default;
        };
        deploy-rs = {
          type = "app";
          program = lib.getExe deploy-rs.packages.${system}.default;
        };
        nixos-anywhere = {
          type = "app";
          program = lib.getExe' nixos-anywhere.packages.${system}.default "nixos-anywhere";
        };
      };

      packages.${system} = workflows // {
        default = workflows.deploy-system;
      };

      devShells.${system}.default = import ./devshell.nix {
        inherit pkgs workflows;
        deploy-rs = deploy-rs.packages.${system}.default;
        nixos-anywhere = nixos-anywhere.packages.${system}.default;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
