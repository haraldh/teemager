{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    nixos-generators,
    ...
  }:
    {
      packages.x86_64-linux = {
        verity = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
          ];
          customFormats = {"verity" = ./formats/verity.nix;};
          format = "verity";
        };
        uki = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
          ];
          customFormats = {"uki" = ./formats/uki.nix;};
          format = "uki";
        };
      };
    }
    // (
      let
        forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" "aarch64-darwin"];
      in {
        formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
      }
    );
}
