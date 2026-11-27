# The example: the shop's flake builds its release, and a host places it.
{
  lib,
  nixpkgs,
  pkgs,
  self,
  system,
  ...
}:
let
  mkFleetSystem = import ../checks/mk-fleet-system.nix { inherit lib self system; };
  # As a flake input would arrive: the flake's outputs and its source.
  shop =
    (import ./shop/flake.nix).outputs {
      inherit nixpkgs;
      projects-sdk = self;
    }
    // {
      outPath = ./shop;
    };
  host = mkFleetSystem "host-01" [
    self.nixosModules.projects
    ./host.nix
    { _module.args.inputs = { inherit shop; }; }
  ];
  failed = map (a: a.message) (lib.filter (a: !a.assertion) host.config.assertions);
  app = host.config.fleet.services.appDeployments.apps.shop;
in
{
  example =
    assert failed == [ ];
    assert app.project.grant.default.endpoint.hostName == "shop.example.net";
    pkgs.runCommand "example-check" { } ''
      test -f ${shop.packages.${system}.projectRelease}/index.html
      test -f ${shop.packages.${system}.projectRelease}/share/project/descriptor.json
      touch "$out"
    '';
}
