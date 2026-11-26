fmt:
    nix fmt
    nix develop -c pnpm exec vp fmt

check:
    nix flake check --all-systems
    nix develop -c pnpm check

# Secrets in the working tree.
scan:
    nix develop -c gitleaks detect --source . --no-git --redact
