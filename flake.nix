{
  description = "A flake with nixpkgs stable and numtide flake-utils for x86_64-linux with git and docker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        dependencies = with pkgs; [ docker docker-compose ];
        dev-dependencies = with pkgs; [ git postgresql postgrest supabase-cli ];
        supabase = pkgs.callPackage ./package.nix {};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = dev-dependencies ++ dependencies ++ [
            supabase
          ];
        };
      });
}