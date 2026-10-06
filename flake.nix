{
  description = "Home Manager configuration for djh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, git-hooks, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Shared lint/format checks: gate local commits (modules/hm-auto-commit.nix),
      # the manual `nix develop` pre-commit hook, and CI (.github/workflows/check.yml)
      # all run the exact same thing, so none of them can drift from the others.
      preCommitCheck = git-hooks.lib.${system}.run {
        src = ./.;
        excludes = [ "^templates/" "^archive_config/" ];
        hooks = {
          statix.enable = true;
          deadnix = {
            enable = true;
            settings.noLambdaPatternNames = true;
          };
          nixpkgs-fmt.enable = true;
        };
      };
    in
    {
      homeConfigurations.djh = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          # Zen Browser is not in nixpkgs; this flake input provides the package
          # and installs it via its own home-manager module.
          zen-browser.homeModules.twilight
        ];
      };

      formatter.${system} = pkgs.nixpkgs-fmt;

      checks.${system} = {
        pre-commit-check = preCommitCheck;
        # Builds the full home-manager activation closure, the same thing
        # `home-manager build`/`switch` builds. Catches real evaluation and
        # build breakage, not just style issues.
        home-activation = self.homeConfigurations.djh.activationPackage;
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (preCommitCheck) shellHook;
      };
    };
}
