# {
#   inputs = {
#     nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
#     omarchy-nix = {
#         url = "github:henrysipp/omarchy-nix";
#         inputs.nixpkgs.follows = "nixpkgs";
#         inputs.home-manager.follows = "home-manager";
#     };
#     home-manager = {
#       url = "github:nix-community/home-manager";
#       inputs.nixpkgs.follows = "nixpkgs";
#     };
#   };
#
#   outputs = { nixpkgs, omarchy-nix, home-manager, ... }: {
#     nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
#       modules = [
#         omarchy-nix.nixosModules.default
#         home-manager.nixosModules.home-manager #Add this import
#         {
#           # Configure omarchy
#           omarchy = {
#             full_name = "Your Name";
#             email_address = "your.email@example.com";
#             theme = "tokyo-night";
#           };
#
#           home-manager = {
#             users.your-username = {
#               imports = [ omarchy-nix.homeManagerModules.default ]; # And this one
#             };
#           };
#         }
#       ];
#     };
#   };
# }

{
  # A NEW ERA WE ARE MAKING THE SWITCH VERY SLOWLY. YOU CAN CHANGE THE DESCRIPTION WHEN WE HAVE SWITCHED!
  description = "Home-manager flake for djh";

  # Inputs: nixpkgs and home-manager. We pin nixpkgs to match your home.stateVersion.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # Zen Browser (Special because not supported in nixpkgs)     # zen-browser = {
    #   url = "github:LunaCOLON3/zen-browser-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, ... }:
  let
    # Target system (your machine architecture)
    system = "x86_64-linux";

    # Import nixpkgs for this system so we can reference packages in modules
    pkgs = import nixpkgs { inherit system; };

    # Convenience: home-manager helper library
    hm = home-manager.lib;
  in {
    # Expose a single Home-Manager configuration named "djh".
    # This is the target you will apply with `home-manager switch --flake .#djh`.
    homeConfigurations.djh = hm.homeManagerConfiguration {
      inherit pkgs;

      # The modules list composes the "base" home.nix you already maintain
      modules = [
        ./home.nix
        zen-browser.homeModules.twilight
      ];
      extraSpecialArgs = { inherit zen-browser; };
    };
  };
}
