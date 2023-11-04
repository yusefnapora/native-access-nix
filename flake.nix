{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    wrapWine = pkgs.callPackage ./wrapWine.nix {};
    native-access = pkgs.callPackage ./native-access.nix {
      inherit wrapWine;
    };

  in {
    packages.${system} = rec {
      inherit native-access;
      default = native-access;
    };
  };
}
