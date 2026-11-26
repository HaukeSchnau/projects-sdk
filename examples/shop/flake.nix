# The shop's flake: `lib.project` for hosts, and the release CI builds.
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    projects-sdk = {
      url = "github:<owner>/projects-sdk/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, projects-sdk, ... }:
    projects-sdk.lib.projectFlake {
      inherit nixpkgs;
      modules = [ ./project.nix ];
      release =
        { pkgs, ... }:
        {
          root = pkgs.writeTextDir "index.html" "<h1>Shop</h1>\n";
        };
    };
}
