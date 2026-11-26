# A NixOS host that serves the shop's release. Besides this SDK's appDeployments and projects
# modules, the host imports its own fleet modules (README.md, "Host contract").
{ inputs, ... }:
{
  fleet.services.projects = {
    defaultOwner = "alice";
    releaseCacheStore = "https://cache.example.net";
    repositoryRemotes.forge = {
      checkoutUrlPrefix = "git@forge.example.net:";
      releaseUrlPrefix = "git+https://forge.example.net/";
    };
  };

  # CI promotes each new release through this webhook. With sops-nix this names a SOPS key; without
  # it, a file.
  fleet.appDeployments.webhook.tokenSecretName = "/run/keys/app-deployments-webhook-token";

  projects.shop = {
    source = inputs.shop;
    repository = {
      remote = "forge";
      path = "team/shop.git";
    };
    # Release only; a development instance needs devenv (docs/projects.md).
    development = null;
    release = {
      delivery.mode = "cache";
      grant = {
        hostNames = [ "shop.example.net" ];
        public = true;
        # The placement that applies until the repository places the release itself.
        default.endpoint = {
          hostName = "shop.example.net";
          visibility = "public";
        };
      };
    };
  };

  users.users.alice = {
    isNormalUser = true;
    uid = 1000;
  };
}
