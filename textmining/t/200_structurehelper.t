use Mojo::Base -strict;
use Mojo::Asset::File;
use Mojo::JSON;
use Mojo::Util qw(encode decode camelize);
use Test::More;

use File::Basename;
use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use FindBin;

my $number_of_tests_run = 1;
BEGIN { 
    use_ok( 'Textmining::Plugin::StructureHelper' );
}

#my ($fh, $filename) = tempfile();
#($fh, $filename) = tempfile( $template, DIR => $dir);
#($fh, $filename) = tempfile( $template, SUFFIX => '.dat');
#($fh, $filename) = tempfile( $template, TMPDIR => 1 );
my $dir = tempdir( CLEANUP => 1 );
#my $dir = tempdir();
#($fh, $filename) = tempfile( DIR => $dir );

my @coursestruct = qw(modul library corpus);
my $tmp_hash = {};
for (values @coursestruct) {
    my $path = join('/', $dir, $_ ); 
    make_path( $path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $path, "$_.xml"));
    $tmp_hash->{$_} = { "$_.xml" => undef};
}

## {{{ utils
## Test for _exists_check($object)
$number_of_tests_run++;
cmp_ok(&Textmining::Plugin::StructureHelper::_exists_check($dir), '==' , 0, '_exists_check');

## Test for _tree($path, $max_deep = 5)
$number_of_tests_run++;
my $tree_hash = {};
$tree_hash = &Textmining::Plugin::StructureHelper::_tree($dir);
is_deeply($tree_hash, $tmp_hash, '_tree');

my $json = Mojo::JSON->new;

## Test for hash_to_json($self, $meta_struct)
my $json_bytes = Textmining::Plugin::StructureHelper->hash_to_json($tmp_hash);
my $tmp_json_bytes = decode('UTF-8', $json->encode($tmp_hash));
my $err = $json->error;

$number_of_tests_run++;
if (defined $err) {
    fail('hash_to_json failed');
} else {
    pass('hash_to_json successed');
}

$number_of_tests_run++;
is($json_bytes, $tmp_json_bytes, 'json_bytes eq tmp_json_bytes');

## Test for json_to_hash($self, $json_bytes)
my $json_hash = Textmining::Plugin::StructureHelper->json_to_hash($json_bytes);
my $tmp_json_hash = $json->decode($json_bytes);
$err = $json->error;

$number_of_tests_run++;
if (defined $err) {
    fail('json_to_hash failed');
} else {
    pass('json_to_hash successed');
}

$number_of_tests_run++;
is_deeply($json_hash, $tmp_json_hash, 'json_hash eq tmp_json_hash');
# }}} utils


done_testing( $number_of_tests_run );
