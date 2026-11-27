# projects-sdk

A Project is a repository that says what it needs to run: secrets, directories, a database,
parameters, endpoints, health checks. Hosts decide where it runs and bind those needs to real
hostnames, secrets and resources. This SDK is both halves: what a repository writes, and the
NixOS and nix-darwin modules that run it.

## In a repository

| Export                                            | What it is                                                                              | Docs                                                      |
| ------------------------------------------------- | --------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `projectModules.default`, `lib.projectDefinition` | The `project.nix` schema and its normalized descriptor                                  | [Project definition](docs/project-definition.md)          |
| `lib.projectFlake`, `lib.projectSource`           | The flake outputs a Project needs: `lib.project` and `packages.<system>.projectRelease` | [Project definition](docs/project-definition.md#flakenix) |
| `lib.projectRuntime`                              | Release artifacts, the runtime context and release planning                             | [Project runtime](docs/project-runtime.md)                |
| `devenvModules.project`                           | Process and task annotations for devenv, and the development contract they export       | [Project devenv](docs/project-devenv.md)                  |
| `lib.toolchain`                                   | The Node and pnpm every TypeScript repository shares                                    | [Toolchain](docs/toolchain.md)                            |
| `@schnau/fleet`                                   | Alchemy provider: `Fleet.Service` and `Fleet.Placement` against a host's grant          | [packages/fleet](packages/fleet/README.md)                |

Take a release tag in the flake and in `devenv.yaml`:

```nix
inputs.projects-sdk = {
  url = "github:<owner>/projects-sdk/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```yaml
inputs:
  projectSdk:
    url: github:<owner>/projects-sdk/v0.1.0
    flake: false
```

## On a host

| Export                                               | What it does                                                                   | Docs                                                                   |
| ---------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `nixosModules.projects`                              | Development instances of checkouts, and releases placed within grants          | [Projects](docs/projects.md)                                           |
| `nixosModules.appDeployments`                        | The release pipeline: webhook, placements, activation, health checks, rollback | [App deployments](docs/app-deployments.md)                             |
| `nixosModules.services`                              | The service controller for `Fleet.Service`, with no NixOS switch               | [Services](docs/services.md)                                           |
| `darwinModules.projects`                             | Releases on a Mac through the same webhook and pipeline                        | [Projects](docs/projects.md#nix-darwin)                                |
| `lib.projectDescriptor`, `lib.nixos.nixFlakeService` | Helpers for host adapters                                                      | [Project definition](docs/project-definition.md#normalized-descriptor) |
| `packages.<system>.project-controller`               | The `project` controller as a Python package                                   | [Projects](docs/projects.md#development)                               |

### Host contract

The NixOS modules run inside a host's own fleet modules and read these options from them:

- `fleet.enable`, which switches the modules on, and `fleet.baseDomain`, under which
  development hostnames live;
- `fleet.services.caddy.virtualHosts.<name>`, where app deployments put their routes:
  `hostName`, `backend` (`scheme`, `address`, `port`), `tailscaleOnly`, `sourceRanges` and
  `extraConfig`.

nix-infra-modules' `nixosModules.caddyIngress` declares all three. Any module that declares
them with the same types will do; [checks/fleet-host.nix](checks/fleet-host.nix) is the one the
checks use. The nix-darwin module declares everything it reads itself.

## Example

[examples/](examples) has a repository and a host. `examples/shop` is a static site:
`project.nix` says what it needs, and `flake.nix` builds its release with `lib.projectFlake`.
`examples/host.nix` places that release on a NixOS host behind `shop.example.net`. The check
`example` builds the release and evaluates the host.

## Releases

Releases are tags `vMAJOR.MINOR.PATCH`. A release that changes an option, the descriptor schema or
the provider's API in a way callers notice raises the minor version while the major is 0.

## Checks

```sh
nix flake check --all-systems     # every module, the controller's tests, the service controller VM test
nix develop -c pnpm install
nix develop -c pnpm check         # oxfmt, oxlint and the type check of @schnau/fleet
```

The service controller's VM test needs `kvm`, so it builds on x86_64-linux.

## License

MIT, see [LICENSE](LICENSE). `tools/oxlint/anti-slop` is vendored under its own license.
