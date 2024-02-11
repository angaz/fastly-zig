{
  description = "POC for using Zig on Fastly Compute";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";

    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";
  };

  outputs = inputs@{ flake-parts, zig, zls, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = { pkgs, system, ... }: {
        devshells.default = {
          commands = [
            {
              name = "serve";
              help = "Start a local dev server";
              command = ''
                zig build -Doptimize=ReleaseSmall && fastly compute serve --skip-build --file zig-out/bin/main.wasm
              '';
            }
          ];

          packages = with pkgs; [
            fastly
            zig.packages.${system}.master
            zls.packages.${system}.zls
          ];
        };
      };
    };
}
