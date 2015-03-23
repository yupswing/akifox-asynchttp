rm -rf docs/* &&
rm -rf docs/* docs/.??* &&
rm -rf bin/xml/* bin/xml/.??* &&
haxe scripts/gen_docs.hxml &&
haxelib run dox -o docs -i bin/xml -in com &&
open docs/index.html