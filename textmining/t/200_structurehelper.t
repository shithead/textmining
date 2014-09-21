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

# Test for get_data_modul($self, $course)
$test_hash = {
        path    => join('/', $test_structhelper->{_path}->{data}, 'test_course', 'modul'),
        files   => \@{$test_structhelper->{_data_struct}->{test_course}->{modul}}
};

$number_of_tests_run++;
is_deeply($test_structhelper->get_data_modul('test_course'), $test_hash, 'get_data_modul');

# Test for get_data_library($self, $course)
$test_hash = {
        path    => join('/', $test_structhelper->{_path}->{data}, 'test_course', 'library'),
        files   => \@{$test_structhelper->{_data_struct}->{test_course}->{library}}
};

$number_of_tests_run++;
is_deeply($test_structhelper->get_data_library('test_course'), $test_hash, 'get_data_library');

# Test for get_data_corpus($self, $course)
$test_hash = {
        path    => join('/', $test_structhelper->{_path}->{data}, 'test_course', 'corpus'),
        files   => $test_structhelper->{_data_struct}->{test_course}->{corpus}
};

$number_of_tests_run++;
is_deeply($test_structhelper->get_data_corpus('test_course'), $test_hash, 'get_data_corpus');

# }}} data directory

# {{{ public directory

# Test for create_public_path($self, $suffix)
$number_of_tests_run++;
$test_structhelper->create_public_path('test_public_path');
is(&Textmining::Plugin::StructureHelper::_exists_check(join('/', $test_public_dir, 'test_public_path')), '0', 'create_public_path');

# Test for rm_public_path($self, $suffix)
$number_of_tests_run++;
$test_structhelper->rm_public_path('test_public_path');
is(&Textmining::Plugin::StructureHelper::_exists_check(join('/', $test_public_dir, 'test_public_path')), '1', 'rm_public_path');

# Test for create_public_chapter($self, $course, $course_meta_struct)
$number_of_tests_run++;
my $test_modul = $test_structhelper->get_data_modul('test_course');
my $test_course_meta_struct = $test_structhelper->{transform}->get_meta_struct(
    $test_modul->{path},
    @{$test_modul->{files}}
);
my @chapter_dirs    = $test_structhelper->create_public_chapter(
    'test_course',
    $test_course_meta_struct
);
my @test_array = (
    {
        dir       => "test_course/modul/Test Modul/0_testziel",
        pagecnt   => 2
    },
    {
        dir       => "test_course/modul/Test Modul/1_twotestid",
        pagecnt   => 3
    },
    {
        dir       => "test_course/modul/Test Modul/2_threetetestid",
        pagecnt   => 1
    },
    {
        dir       => "test_course/modul/Test Modul/3_fourtestid",
        pagecnt   => 1
    },
    {
        dir       => "test_course/modul/Test Modul/4_fivetestid",
        pagecnt   => 3
    }
);
is_deeply(\@chapter_dirs, \@test_array, 'create_public_chapter');

#{{{ subtest
$number_of_tests_run++;
my $chapter_dirs    = $test_structhelper->create_public_chapter(
    'test_course',
    $test_course_meta_struct
);
isa_ok( $chapter_dirs, 'ARRAY' );
#}}}

# Test for save_public_struct($self, $location, $meta_struct)
$number_of_tests_run++;
my $test_path = "$test_public_dir/test_course/.meta.json";
$test_structhelper->save_public_struct(
        $test_path,
        $test_course_meta_struct
    );
is(&Textmining::Plugin::StructureHelper::_exists_check($test_path),
     '0', 'save_public_struct');
 
# Test for load_public_struct($self, $location)
$number_of_tests_run++;
is_deeply($test_structhelper->load_public_struct( $test_path ),
        $test_course_meta_struct,
        'load_public_struct and compare deeply with the saved one');

# remove old public/test_course
remove_tree("$test_public_dir/test_course");

# Test for update_public_struct($self)
# create test struct
$test_hash = {};
for (values @publicstruct) {
    my $path = join('/', $test_public_dir, 'test_course', $_ ); 
    make_path( $path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $path, "$_.xml"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
}

$number_of_tests_run++;

$test_structhelper->update_public_struct();
is_deeply(
    $test_structhelper->{_public_struct}, 
    $test_hash,
    'update_public_struct'
);

remove_tree("$test_public_dir/test_course");
$test_structhelper->{_public_struct} = {};

# Test for init_public_course($self, $course)
# create test struct
$test_hash = {
    test_course   => {
        corpus    => {
        },
        library   => {
        },
        modul     => {
            'Test Modul'   => {
                '0_testziel' =>       {
                   "1.html"     =>  undef,
                   "2.html"     =>  undef
                },
                "1_twotestid" =>      {
                   "1.html"     =>  undef,
                   "2.html"     =>  undef,
                   "3.html"     =>  undef
                },
                "2_threetetestid"  =>  {
                   "1.html"     =>  undef
                },
                "3_fourtestid"    =>  {
                   "1.html"     =>  undef
                },
                "4_fivetestid"    =>  {
                   "1.html"     =>  undef,
                   "2.html"     =>  undef,
                   "3.html"     =>  undef
                }
            }
        }

    }
};

$number_of_tests_run++;

$test_structhelper->init_public_course('test_course');
is_deeply($test_structhelper->{_public_struct}, 
    $test_hash, 'init_public_course');

# Test for get_public_struct($self)
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_struct(), 
    $test_hash, 'get_public_struct');

# Test for get_public_modul_struct($self,$course)
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_modul_struct('test_course'), 
    $test_hash->{test_course}, 'get_public_modul_struct with defined $course');

$number_of_tests_run++;
is($test_structhelper->get_public_modul_struct(), 
    undef, 'get_public_modul_struct with undefined $course');

# Test for get_public_page_path($self, $course_struct, $modul)
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_page_path(
            $test_course_meta_struct->{test_course}, 'modul'),
        $test_course_meta_struct->{test_course}->{modul},
        'get_public_page_path normal' );

$number_of_tests_run++;
is($test_structhelper->get_public_page_path( undef, 'modul'), 
        undef,
        'get_public_page_path with undefined $course_struct');

$number_of_tests_run++;
is($test_structhelper->get_public_page_path($test_hash, 'modul'),
        undef,
        'get_public_page_path with invalid $course_struct' );

$number_of_tests_run++;
is($test_structhelper->get_public_page_path( 
            $test_hash->{test_course}, undef),
        undef,
        'get_public_page_path with undefined $modul');

# Test for get_public_navbar($self, $meta_struct, $modul)
# create test array
@test_array = (
    {
        Testziel    =>  0
    },
    {
        Twotestid   =>  2
    },
    {
        Threetetestid   =>  5
    },
    {
        Fourtestid  =>  6
    },
    {
        Fivetestid  =>  7
    }
);

$number_of_tests_run++;
my @got_array = $test_structhelper->get_public_navbar(
            $test_course_meta_struct, 'Test Modul');
is_deeply(\@got_array,
        \@test_array,
        'get_public_navbar normal' );

$number_of_tests_run++;
is($test_structhelper->get_public_navbar( undef, 'Test Modul'), 
        undef,
        'get_public_navbar with undefined $course_struct');

$number_of_tests_run++;
is($test_structhelper->get_public_navbar($test_hash, 'Test Modul'),
        undef,
        'get_public_navbar with invalid $course_struct' );

$number_of_tests_run++;
is($test_structhelper->get_public_navbar( 
            $test_course_meta_struct, undef),
        undef,
        'get_public_navbar with undefined $modul');

# }}} public directory
done_testing( $number_of_tests_run );
