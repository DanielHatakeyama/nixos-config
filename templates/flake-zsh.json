{
  description = "Development environment with zsh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Add your development tools here
            # Example:
            # python311
            # nodejs
            # cargo
          ];

          # Use zsh as the shell in nix develop
          shellHook = ''
            # Start zsh if not already in zsh
            if [ -z "$ZSH_VERSION" ]; then
              exec ${pkgs.zsh}/bin/zsh
            fi
          '';
        };
      }
    );
}
