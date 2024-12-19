{
  inputs = {
    nixsgx-flake.url = "github:matter-labs/nixsgx";
    nixpkgs.follows = "nixsgx-flake/nixpkgs";
    teepot-flake = {
      url = "github:matter-labs/teepot?ref=d5e83471799ea62e10d86b644477f4a28d75ee74";
      inputs.nixsgx-flake.follows = "nixsgx-flake";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    nixosGenerate = import ./nixos-generate.nix;

    overlays = with inputs; [
      teepot-flake.overlays.default
      nixsgx-flake.overlays.default
    ];

    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        inherit overlays;
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
      verity = nixosGenerate {
        inherit (nixpkgs) lib;
        inherit (nixpkgs.lib) nixosSystem;
        inherit system pkgs;
        modules = [
          ./configuration.nix
        ];
        formatModule = ./formats/verity.nix;
        format = "verity";
      };

      uki = nixosGenerate {
        inherit (nixpkgs) lib;
        inherit (nixpkgs.lib) nixosSystem;
        inherit system pkgs;
        modules = [
          ./configuration.nix
        ];
        formatModule = ./formats/uki.nix;
        format = "uki";
      };
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    devShells = forAllSystems (
      system: let
        pkgs = pkgsForSystem system;
      in {
        default = pkgs.callPackage ./devShell.nix {};
      }
    );

    nixosConfigurations.test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {nixpkgs.overlays = overlays;}
        ./formats/test.nix
        ./configuration.nix
      ];
    };
  };
}
