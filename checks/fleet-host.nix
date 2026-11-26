# What the host modules need from the host's own fleet modules (README.md, "Host contract"): the
# fleet switch, the base domain and the ingress's virtual hosts. The checks import this in their
# place. nix-infra-modules' caddyIngress declares the same options with the same types.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.fleet = {
    enable = lib.mkEnableOption "the fleet modules";

    baseDomain = mkOption {
      type = types.str;
      default = "example.net";
    };

    services.caddy.virtualHosts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              hostName = mkOption {
                type = types.str;
                default = name;
              };
              backend = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      scheme = mkOption {
                        type = types.enum [
                          "http"
                          "https"
                        ];
                        default = "http";
                      };
                      address = mkOption {
                        type = types.str;
                        default = "127.0.0.1";
                      };
                      port = mkOption { type = types.port; };
                    };
                  }
                );
                default = null;
              };
              tailscaleOnly = mkOption {
                type = types.bool;
                default = true;
              };
              sourceRanges = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = null;
              };
              extraConfig = mkOption {
                type = types.lines;
                default = "";
              };
            };
          }
        )
      );
      default = { };
    };
  };
}
