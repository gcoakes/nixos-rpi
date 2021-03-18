{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixboot = {
      url = "github:gcoakes/nixboot";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixboot }: let
    pi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      extraArgs = { inherit nixboot; };
      modules = [ ./configuration.nix ];
    };
  in
    {
      nixosConfigurations.pi = pi;
    } // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        img = pi.config.system.build.sdImage;
      in
        rec {
          apps.flash-rpi-sd-card = with pkgs; writeShellScriptBin "flash-rpi-sd-card" ''
            while [ "$#" -gt 0 ]; do
              case "$1" in
                -f) shift
                  FLASH_RPI_FORCE=1
                  ;;
                *)
                  FLASH_RPI_OUTPUT="$1"
                  shift
                  ;;
              esac
            done
            [ "$FLASH_RPI_FORCE" -eq 1 ] \
              && resp=y \
              || read -p "Flash image to $FLASH_RPI_OUTPUT? [y/N] " resp
            case "$resp" in
              y*|Y*) ;;
              *) exit 1 ;;
            esac
            ${zstd}/bin/zstd -dcf ${img}/sd-image/nixos-sd-image-*.img.zst \
              | ${coreutils}/bin/dd "of=$FLASH_RPI_OUTPUT" status=progress bs=4M oflag=sync
          '';
          defaultApp = flake-utils.lib.mkApp { drv = apps.flash-rpi-sd-card; };
          packages.sdImage = img;
          defaultPackage = packages.sdImage;
        }
    );
}
