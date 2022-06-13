args @ { lib, runCommandNoCC, linkutils, tarutils, ... }: let

  inherit (builtins) typeOf tryEval mapAttrs toJSON;

in {

  # Stash our inputs in case we'd like to refer to them later.
  # Think of these as "read-only", since overriding this attribute won't have
  # any effect on the tests themselves.
  inputs = args // { inherit lib; };

  testTrivial = {
    expr = let x = 0; in x;
    expected = 0;
  };

  testTar = {
    expr = let
      drv = runCommandNoCC "source" {} ''
        mkdir -p $out/sub
        echo "Howdy"   > "$out/a"
        echo "Partner" > "$out/b"
        echo "Nest"    > "$out/sub/c"
      '';
      tarballAll = tarutils.tar {
        src =
          # FIXME: The effort required here to remove directories bad.
          # This needs to be reworked, unforunately `tar' doesn't provide
          # useful flags for handling directory structures.
          # Note that getting pathnames to be written without `./<NAME>' is
          # also an issue that needs attention.
          map ( p: lib.libstr.yank "\\./(.*)"
            ( lib.libpath.realpathRel' drv.outPath p ) )
            ( lib.filesystem.listFilesRecursive drv.outPath );
        tarFlagsLate = ["-C" "${drv}"];
      };
      tarballSingles = tarutils.tar {
        src = ["a" "b" "sub/c"];
        tarFlagsLate = ["-C" "${drv}"];
      };
      fileLists = runCommandNoCC "tarball-files.log" {
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        tar -tf ${tarballAll}     >  "$out"
        echo "***"                >> "$out"
        tar -tf ${tarballSingles} >> "$out"
      '';
    in builtins.readFile fileLists.outPath;
    expected = ''
      a
      b
      sub/c
      ***
      a
      b
      sub/c
    '';
  };

}
