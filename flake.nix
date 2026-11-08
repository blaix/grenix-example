{
  description = "A Gren command line application";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      manifest = builtins.fromJSON (builtins.readFile ./package.json);
      binName = builtins.head (builtins.attrNames manifest.bin);

      # Expected output for smoke tests
      expectedOutput = "Hello. I like you and I love you.";

      packageFor =
        pkgs:
        pkgs.stdenv.mkDerivation {
          pname = binName;
          inherit (manifest) version;
          src = ./.;
          strictDeps = true;
          nativeBuildInputs = [ pkgs.gren ];
          buildInputs = [ pkgs.nodejs-slim_24 ];
          buildPhase = ''
            runHook preBuild
            gren make Main --optimize
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            install -Dm755 app $out/bin/${binName}
            runHook postInstall
          '';
          meta = {
            inherit (manifest) description;
            mainProgram = binName;
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = packageFor (pkgsFor system);
      });

      # Define what runs with `nix flake check`.
      # Great for CI since it runs in a sandbox.
      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {

          # Make sure the app is runnable with nix...
          smoke = pkgs.runCommand "${binName}-smoke" { } ''
            [ "$(${packageFor pkgs}/bin/${binName})" = "${expectedOutput}" ]
            touch $out
          '';

          # Make sure the app is runnable with npm...
          npm =
            pkgs.runCommand "${binName}-npm"
              {
                src = ./.;
                nativeBuildInputs = [
                  pkgs.gren
                  pkgs.nodejs_24
                ];
              }
              ''
                export HOME=$TMPDIR

                # copy project to a writable dir
                cp -r $src project
                chmod -R u+w project
                cd project

                # mimic an npm publish + global install
                npm pack --offline
                npm install --global --offline --prefix $TMPDIR/prefix ./*.tgz
                patchShebangs $TMPDIR/prefix

                # run the installed npm package
                [ "$($TMPDIR/prefix/bin/${binName})" = "${expectedOutput}" ]

                touch $out
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.gren
              pkgs.nodejs_24
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
