{ libfs ? import ./filesystem.nix
, lib   ? ( builtins.getFlake "nixpkgs" ).lib
, libpath ? import ./paths.nix { inherit lib; }
}:
let
/* -------------------------------------------------------------------------- */

  showList = xs:
    let lines = builtins.concatStringsSep "\n" ( map toString xs );
    in builtins.trace ( "\n" + lines ) true;

  show = x: showList ( if ( builtins.isList x ) then x else [x] );


/* -------------------------------------------------------------------------- */

  pwd' = builtins.getEnv "PWD";
  pwd  = toString ./.;


/* -------------------------------------------------------------------------- */

  unGlob = path:
    builtins.head ( builtins.split "\\*" ( toString path ) );

  lsDir' = dir:
    let
      files = libfs.listFiles dir;
      dirs = libfs.listSubdirs dir;
    in files ++ ( map ( d: d + "/" ) dirs );

  lsDirGlob' = path':
    let
      inherit (builtins) substring stringLength split head replaceStrings;
      path = toString path';
      wasAbs = libpath.isAbspath path;
      ng = unGlob path;
      dir = if ( ng == "" ) then ( toString ./. ) else ( libpath.asAbspath ng );
      plen = stringLength path;
      isSGlob = ( 2 <= plen ) && ( substring ( plen - 2 ) plen path ) == "/*";
      isDGlob = ( 3 <= plen ) && ( substring ( plen - 3 ) plen path ) == "/**";
      files = libfs.listFiles dir;
      subs  = builtins.concatLists ( libfs.mapSubdirs libfs.listDir dir );
      lines = if isSGlob then ( files ++ subs ) else
              if isDGlob then ( lib.filesystem.listFilesRecursive dir ) else
              ( lsDir' dir );
      makeRel = p: libpath.realpathRel' dir p;
      relLines = if wasAbs then lines else ( map makeRel lines );
    in show relLines;


/* -------------------------------------------------------------------------- */

in {
  inherit show;
  inherit pwd' pwd lsDirGlob';
  inherit unGlob;
  ls' = lsDirGlob' ./.;
}
