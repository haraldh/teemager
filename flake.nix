{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tdx-attest.url = "github:haraldh/tdx-attest";
    teepot-flake.url = "github:matter-labs/teepot?ref=f661c8b975b37f45a69fd0a12c7d54f6bdf18f8b";
    nixsgx-flake.url = "github:matter-labs/nixsgx";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        overlays = with inputs; [
          (final: prev: {tdx_attest = tdx-attest.packages.${system}.tdx_attest;})
          teepot-flake.overlays.default
          nixsgx-flake.overlays.default
        ];
      };
    allVMs = ["x86_64-linux"];
    forAllVMs = f:
      nixpkgs.lib.genAttrs allVMs (system:
        f {
          inherit system;
          pkgs = pkgsForSystem system;
        });
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" "aarch64-darwin"];
  in {
    packages = forAllVMs ({
      system,
      pkgs,
    }: {
      verity = inputs.nixos-generators.nixosGenerate {
        system = system;
        specialArgs = {
          pkgs = pkgs;
        };
        modules = [
          ./configuration.nix
        ];
        customFormats = {"verity" = ./formats/verity.nix;};
        format = "verity";
      };
      uki = inputs.nixos-generators.nixosGenerate {
        system = system;
        specialArgs = {
          pkgs = pkgs;
        };
        modules = [
          ./configuration.nix
        ];
        customFormats = {"uki" = ./formats/uki.nix;};
        format = "uki";
      };
    });
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
