{
  pkgs ? null,
  lib,
  nixosSystem,
  format,
  formatModule,
  system ? null,
  specialArgs ? {},
  modules ? [],
}: let
  image = nixosSystem {
    inherit pkgs specialArgs;
    system =
      if system != null
      then system
      else pkgs.system;
    lib =
      if lib != null
      then lib
      else pkgs.lib;
    modules =
      [
        {
          imports = [
            formatModule
            (
              {
                lib,
                modulesPath,
                ...
              }: {
                options = {
                  fileExtension = lib.mkOption {
                    type = lib.types.str;
                    description = "Declare the path of the wanted file in the output directory";
                    default = "";
                  };
                  formatAttr = lib.mkOption {
                    type = lib.types.str;
                    description = "Declare the default attribute to build";
                  };
                };
              }
            )
          ];
        }
      ]
      ++ modules;
  };
in
  image.config.system.build.${image.config.formatAttr}
