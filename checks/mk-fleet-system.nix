{
  lib,
  self,
  system,
}:
name: extraModules:
lib.nixosSystem {
  inherit system;
  modules = [
    ./fleet-host.nix
    self.nixosModules.appDeployments
    self.nixosModules.services
    {
      networking.hostName = name;
      boot.isContainer = true;
      system.stateVersion = "25.05";
      fleet = {
        enable = true;
        baseDomain = "example.net";
      };
    }
  ]
  ++ extraModules;
}
