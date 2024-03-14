{
  inputs = {
    # mmcv fails to build because of newer torch version
    nixpkgs.url = "github:NixOS/nixpkgs/5a623156afb531ba64c69363776bb2b2fe55e46b";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    {
      nixpkgs,
      devenv,
      systems,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # https://devenv.sh/reference/options/
                dotenv.disableHint = true;

                # python
                languages.python = {
                  enable = true;
                  # provide hard to compile packages to pip
                  package = pkgs.python3.withPackages (
                    ps:
                    let
                      mmcv-patched = ps.callPackage ./nix/mmcv { };
                    in
                    with ps;
                    [
                      mmcv-patched
                      (ps.callPackage ./nix/mmdet { mmcv = mmcv-patched; })
                      (ps.callPackage ./nix/mmpose {
                        mmcv = mmcv-patched;
                        xtcocotools = ps.callPackage ./nix/xtcocotools { };
                      })
                      numpy
                      pillow
                      flake8
                      black
                    ]
                  );
                };
              }
            ];
          };
        }
      );

      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        { }
      );
    };
}
