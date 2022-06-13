{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, ...
} @ args: let

  inherit (lib) libdbg libpath;

  tests = with libpath; {

    testIsCoercibleToPath = {
      expr = map isCoercibleToPath ["" ./.];
      expected = [true true];
    };

    testExtSuffix = {
      expr = extSuffix "foo.bar.baz";
      expected = "bar.baz";
    };

    testExtSuffix' = {
      expr = extSuffix' "foo.bar.baz";
      expected = "baz";
    };

  };  # End tests

  harness = libdbg.mkTestHarness ( {
    inherit tests withDrv;
    name = "test-paths";
    inputs = args // { inherit lib system nixpkgs pkgs; };
  } // ( if withDrv then { inherit writeText; } else {} ) );

in harness
