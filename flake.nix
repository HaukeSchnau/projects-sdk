{
  description = "Projects: repositories that describe what they need, and hosts that run them";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Only the checks of the nix-darwin module use it.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
    }:
    let
      lib = nixpkgs.lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      linuxSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      lib.projectDefinition = import ./lib/project-definition.nix { inherit lib; };
      lib.projectFlake = import ./lib/project-flake.nix { inherit lib; };
      lib.projectSource = import ./lib/project-source.nix { inherit lib; };
      lib.projectDescriptor = import ./lib/project-descriptor.nix { inherit lib; };
      lib.projectRuntime = import ./lib/project-runtime.nix { inherit lib; };
      lib.toolchain = import ./lib/toolchain.nix;
      lib.nixos.nixFlakeService = import ./modules/nixos/deploy/nix-flake-service.nix;

      projectModules.default = ./modules/project;
      devenvModules.project = ./modules/devenv/project.nix;

      nixosModules = {
        appDeployments = ./modules/nixos/deploy/app-deployments.nix;
        projects = ./modules/nixos/projects;
        services = ./modules/nixos/services;
      };

      darwinModules.projects = ./modules/darwin/projects.nix;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          # The `project` controller as a Python package, for host tooling built on its registry.
          project-controller = pkgs.callPackage ./modules/nixos/projects/controller/package.nix { };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.writeShellApplication {
          name = "projects-sdk-fmt";
          runtimeInputs = [
            pkgs.findutils
            pkgs.nixfmt
          ];
          text = ''
            targets=("$@")
            if [ "''${#targets[@]}" -eq 0 ]; then
              targets=(.)
            fi
            find "''${targets[@]}" -type f -name '*.nix' -print0 | xargs -0 nixfmt
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                gitleaks
                just
                nixfmt
              ]
              # @schnau/fleet
              ++ builtins.attrValues (self.lib.toolchain { inherit pkgs; });
          };
        }
      );

      checks = {
        aarch64-darwin = import ./modules/darwin/checks.nix {
          inherit lib nix-darwin self;
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
        };
      }
      // lib.genAttrs linuxSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          checkArgs = {
            inherit
              lib
              nixpkgs
              pkgs
              self
              system
              ;
          };
          domainChecks = lib.mergeAttrsList (
            map (path: import path checkArgs) [
              ./modules/project/checks.nix
              ./lib/project-runtime/checks.nix
              ./modules/nixos/deploy/checks.nix
              ./modules/nixos/projects/checks.nix
              ./modules/nixos/services/checks.nix
              ./examples/checks.nix
            ]
          );
        in
        {
          format =
            pkgs.runCommand "projects-sdk-format"
              {
                nativeBuildInputs = [
                  pkgs.findutils
                  pkgs.nixfmt
                ];
              }
              ''
                find ${./.} -type f -name '*.nix' -print0 | xargs -0 nixfmt --check
                touch $out
              '';
        }
        // domainChecks
      );
    };
}
