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
my $test_public = 'test-public';
my $test_data = 'test-data';
my $test_public_dir = join('/', $dir, $test_public );
my $test_data_dir = join('/', $dir, $test_data );

my @publicstruct = qw(modul library corpus);
my $test_hash = {};
for (values @publicstruct) {
    my $path = join('/', $test_data_dir, 'test_course', $_ ); 
    make_path( $path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $path, "$_.xml"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
}
make_path( $test_public_dir );

## {{{ utils
## Test for _exists_check($object)
$number_of_tests_run++;
cmp_ok(&Textmining::Plugin::StructureHelper::_exists_check($dir), '==' , 0, '_exists_check');

## Test for _tree($path, $max_deep = 5)
$number_of_tests_run++;
my $tree_hash = {};
$tree_hash = &Textmining::Plugin::StructureHelper::_tree($test_data_dir, 10);
is_deeply($tree_hash, $test_hash, '_tree');

my $json = Mojo::JSON->new;

## Test for hash_to_json($self, $meta_struct)
my $json_bytes = Textmining::Plugin::StructureHelper->hash_to_json($test_hash);
my $test_json_bytes = decode('UTF-8', $json->encode($test_hash));
my $err = $json->error;

$number_of_tests_run++;
if (defined $err) {
    fail('hash_to_json failed');
} else {
    pass('hash_to_json successed');
}

$number_of_tests_run++;
is($json_bytes, $test_json_bytes, 'json_bytes eq test_json_bytes');

## Test for json_to_hash($self, $json_bytes)
my $json_hash = Textmining::Plugin::StructureHelper->json_to_hash($json_bytes);
my $test_json_hash = $json->decode($json_bytes);
$err = $json->error;

$number_of_tests_run++;
if (defined $err) {
    fail('json_to_hash failed');
} else {
    pass('json_to_hash successed');
}

$number_of_tests_run++;
is_deeply($json_hash, $test_json_hash, 'json_hash eq test_json_hash');
# }}} utils

# {{{ data directory
# XXX prepare test_hash '_data_struct'
$test_hash = {};
for (values @publicstruct) {
    my $path = join('/', $test_data_dir, 'test_course', $_ ); 
    if ( $_ =~ 'corpus') {
        $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
    } else {
        push @{$test_hash->{test_course}->{$_}}, "$_.xml";
    } 
}


my $test_structhelper = Textmining::Plugin::StructureHelper->new();

$test_structhelper->{_path}->{data} = $test_data_dir;
$test_structhelper->{_path}->{public} = $test_public_dir;

# for update_data_struct($self)
$number_of_tests_run++;
$test_structhelper->update_data_struct;

is_deeply($test_structhelper->{_data_struct}, $test_hash, 'update_data_struct');

# Test for get_data_struct($self)
$number_of_tests_run++;
is_deeply($test_structhelper->get_data_struct, $test_hash, 'get_data_struct');

# Test for get_data_course($self)
$number_of_tests_run++;
is_deeply($test_structhelper->get_data_course, @{['test_course']}, 'get_data_course');

# }}} data directory


done_testing( $number_of_tests_run );
