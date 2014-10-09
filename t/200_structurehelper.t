use Mojo::Base -strict;
use Mojo::Asset::File;
use Mojo::JSON;
use Mojo::Util qw(encode decode camelize);
use Test::More;
use Test::Mojo;

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

my @publicstruct = qw(module library corpus);
my $test_hash = {};
for (values @publicstruct) {
    my $path = join('/', $test_data_dir, 'test_course', $_ ); 
    make_path( $path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $path, "$_.xml"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
}
make_path( $test_public_dir );

# Test for new
# prepare app
my $t = Test::Mojo->new('Textmining');
$number_of_tests_run++;
my $test_structhelper = Textmining::Plugin::StructureHelper->new->init($t->app);
like($test_structhelper, qr/Textmining::Plugin::StructureHelper/, 'new Textmining::Plugin::StructureHelper');

$test_structhelper->{_path}->{data} = $test_data_dir;
$test_structhelper->{_path}->{public} = $test_public_dir;

## {{{ utils
## Test for _exists_check($object)
$number_of_tests_run++;
cmp_ok(&Textmining::Plugin::StructureHelper::_exists_check($dir), '==' , 0, '_exists_check');

## Test for _tree($path, $max_deep = 5)
$number_of_tests_run++;
my $tree_hash = {};
$tree_hash = &Textmining::Plugin::StructureHelper::_tree($test_data_dir, 10);
is_deeply($tree_hash, $test_hash, '_tree');

## Test for _search_tree($tree, $pattern)
# prepare expect
my $expect_path = "test_course/module/module.xml";
$number_of_tests_run++;
my $got = &Textmining::Plugin::StructureHelper::_search_tree($test_hash, 'module.xml');
is($got, $expect_path, '_search_tree');

## Test for _get_files($dir)
# prepare expect
my @expect_files = qw(module.xml);
$number_of_tests_run++;
my @got = &Textmining::Plugin::StructureHelper::_get_files(
    join( '/', $test_data_dir, 'test_course', 'module')
);

is_deeply(\@got, \@expect_files, '_get_files');

## Test for hash_to_json($self, $meta_struct)
my $json = Mojo::JSON->new;

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

# Test for save_struct($self, $location, $meta_struct)
$number_of_tests_run++;
my $test_path = "$test_public_dir/test_course";
make_path($test_path);
$test_structhelper->save_struct(
        $test_path,
        $test_json_hash
    );
is(&Textmining::Plugin::StructureHelper::_exists_check("$test_path/.meta"),
     '0', 'save_struct');
 
# Test for load_struct($self, $course)
$number_of_tests_run++;
is_deeply($test_structhelper->load_struct( $test_path ),
        $test_json_hash,
        'load_struct and compare deeply with the saved one');

# remove old public/test_course
remove_tree("$test_public_dir/test_course");

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

# Test for get_data_path($self)
$number_of_tests_run++;
is($test_structhelper->get_data_path(), $test_data_dir, 'get_data_path');

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
        path    => join('/', $test_structhelper->{_path}->{data}, 'test_course', 'module'),
        files   => \@{$test_structhelper->{_data_struct}->{test_course}->{module}}
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
# Test for get_public_path($self)
$number_of_tests_run++;
is($test_structhelper->get_public_path(), $test_public_dir, 'get_public_path');

# Test for create_public_path($self, $suffix)
$number_of_tests_run++;
$test_structhelper->create_public_path('test_public_path');
is(&Textmining::Plugin::StructureHelper::_exists_check(join('/', $test_public_dir, 'test_public_path')), '0', 'create_public_path');

# Test for rm_public_path($self, $suffix)
$number_of_tests_run++;
$test_structhelper->rm_public_path('test_public_path');
is(&Textmining::Plugin::StructureHelper::_exists_check(join('/', $test_public_dir, 'test_public_path')), '1', 'rm_public_path');

# Test for create_public_chapter($self, $course, $course_meta_struct)
# prepare test
my $test_modul = $test_structhelper->get_data_modul('test_course');
my $test_modul_meta_struct = Textmining::Plugin::StructureHelper::Course->new->get_modul_struct(
        join( '/', $test_modul->{path}, 'module.xml')
);
# prepare expect
my @expect_chapter_dirs = (
    {
        dir       => "test_course/module/Test Modul/0_testziel",
        pagecnt   => 2
    },
    {
        dir       => "test_course/module/Test Modul/1_twotestid",
        pagecnt   => 3
    },
    {
        dir       => "test_course/module/Test Modul/2_threetetestid",
        pagecnt   => 1
    },
    {
        dir       => "test_course/module/Test Modul/3_fourtestid",
        pagecnt   => 1
    },
    {
        dir       => "test_course/module/Test Modul/4_fivetestid",
        pagecnt   => 3
    }
);

my @test_chapter_dirs    = $test_structhelper->create_public_chapter(
    'test_course',
    $test_modul_meta_struct
);
$number_of_tests_run++;
is_deeply(\@test_chapter_dirs, \@expect_chapter_dirs, 'create_public_chapter');

#{{{ subtest
$got    = $test_structhelper->create_public_chapter(
    'test_course',
    $test_modul_meta_struct
);
$number_of_tests_run++;
isa_ok( $got, 'ARRAY' );
$number_of_tests_run++;
is_deeply($got, \@expect_chapter_dirs, 'create_public_chapter return ref');
#}}}

# Test for create_public_pages
# prepare test data
my $test_chapter_dirs = \@expect_chapter_dirs;
my $test_dir_hash;
for (values @publicstruct) {
    my $path = join('/', $test_data_dir, 'test_course', $_ ); 
    if ( $_ =~ 'corpus') {
        $test_dir_hash->{test_course}->{$_} = { "$_.xml" => undef};
    } else {
        push @{$test_dir_hash->{test_course}->{$_}}, "$_.xml";
    } 
}
my $test_modul_pages;
foreach (@{$test_dir_hash->{test_course}->{module}}) {
    $test_modul_pages->{$_} = $test_structhelper->{transform}->xml_doc_pages(
        join('/', $test_data_dir, 'test_course', 'module', $_),
        join('/', $test_data_dir, 'test_course', 'library'),
        $test_dir_hash->{test_course}->{library}
    );
}
# prepare expect data
my $expect_page_meta_list = ([
    "$dir/test-public/test_course/module/Test Modul/0_testziel/1.html",
    "$dir/test-public/test_course/module/Test Modul/0_testziel/2.html",
    "$dir/test-public/test_course/module/Test Modul/1_twotestid/1.html",
    "$dir/test-public/test_course/module/Test Modul/1_twotestid/2.html",
    "$dir/test-public/test_course/module/Test Modul/1_twotestid/3.html",
    "$dir/test-public/test_course/module/Test Modul/2_threetetestid/1.html",
    "$dir/test-public/test_course/module/Test Modul/3_fourtestid/1.html",
    "$dir/test-public/test_course/module/Test Modul/4_fivetestid/1.html",
    "$dir/test-public/test_course/module/Test Modul/4_fivetestid/2.html",
    "$dir/test-public/test_course/module/Test Modul/4_fivetestid/3.html"
]);
undef @got;
@got = $test_structhelper->create_public_pages( $test_modul_pages, $test_chapter_dirs);

$number_of_tests_run++;
is_deeply(\@got, $expect_page_meta_list, 'create_public_pages');
$got = $test_structhelper->create_public_pages( $test_modul_pages, $test_chapter_dirs);

remove_tree($_) foreach (values $expect_page_meta_list);
#{{{ subtest
$number_of_tests_run++;
isa_ok( $got, 'ARRAY' );
$number_of_tests_run++;
is_deeply($got, $expect_page_meta_list, 'create_public_pages return ref');
#}}}

# Test for create_public_corpus
# prepare test data
$test_hash = {};
for (values @publicstruct) {
    my $test_path = join('/', $test_public_dir, 'test_course', $_ ); 
    make_path( "$test_path/$_" );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml"));
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml.vrt"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
}
my $test_corpus_dir = "$dir/test-public/test_course/corpus";
my $test_corpus_files = &Textmining::Plugin::StructureHelper::_tree($test_corpus_dir);

# prepare expect;
my $expect_token = {
    lemma     => {
        '.'       => 5,
        'a'       => 6,
        'count'   => 6,
        'for'     => 6,
        'is'      => 6,
        'pm'      => 5,
        'test'    => 6,
        'their'   => 5,
        'them'    => 5,
        'this'    => 6,
        'tithe'   => 7,
        'togehter'=> 6,
        'wither'  => 6,
        'write'   => 6
    },
    pos      => {
        'BA' => 6,
        'FO' => 12,
        'GL' => 11,
        'IN' => 11,
        'LO' => 13,
        'NN' => 6,
        'NNO'=> 6,
        'NO' => 10,
        'RA' => 6
    },
    wortform => {
        '.'       => 5,
        'a'       => 6,
        'Count'   => 6,
        'for'     => 6,
        'is'      => 6,
        'pm'      => 5,
        'test'    => 6,
        'their'   => 5,
        'them'    => 5,
        'this'    => 6,
        'tithe'   => 7,
        'together'=> 6,
        'wither'  => 6,
        'written' => 6
    }
};
my $expect_corpus = {
    'corpus-file' => {
        id      => {
            foobarid   => {
                author   =>  "Blablub",
                corpus     => {
                    statistic    => {
                        chi2   => {
                            '26.9637'   => {
                                'tithe'       => [ 7,7 ]
                            },
                            '28.6299'   => {
                                'a'           => [ 6,6 ],
                                'count'       => [ 6,6 ],
                                'for'         => [ 6,6 ],
                                'is'          => [ 6,6 ],
                                'test'        => [ 6,6 ],
                                'this'        => [ 6,6 ],
                                'togehter'    => [ 6,6 ],
                                'wither'      => [ 6,6 ],
                                'write'       => [ 6,6 ]
                            },
                            '30.3502'   => {
                                '.'         => [ 5,5 ],
                                'pm'        => [ 5,5 ],
                                'their'     => [ 5,5 ],
                                'them'      => [ 5,5 ]
                            }
                        },
                        llr    => {
                            '-0.0000'  =>  {
                                '.'          => [ 5,5 ],
                                'a'          => [ 6,6 ],
                                'count'      => [ 6,6 ],
                                'for'        => [ 6,6 ],
                                'is'         => [ 6,6 ],
                                'pm'         => [ 5,5 ],
                                'test'       => [ 6,6 ],
                                'their'      => [ 5,5 ],
                                'them'       => [ 5,5 ],
                                'this'       => [ 6,6 ],
                                'tithe'      => [ 7,7 ],
                                'togehter'   => [ 6,6 ],
                                'wither'     => [ 6,6 ],
                                'write'      => [ 6,6 ]
                            }
                        }


                    },
                    token       => $expect_token,
                    windowsize  => [ $expect_token ]
                },
                date     => undef,
                fpath    => "vrt",
                id       => "foobarid",
                party    => "undef",
                subtitle => undef,
                title    => undef,
                type     => undef,
                year     => 2014
            }
        },
        party   => {
            undef   => {
                foobarid  => $expect_token
            }
        },
        year    => {
            2014   => {
                foobarid  => $expect_token
            }
        }
    }
};

$got = $test_structhelper->create_public_corpus( $test_corpus_dir, $test_corpus_files, $test_modul_meta_struct->{meta}->{corpora});
#p $got;
$number_of_tests_run++;
is_deeply($got, $expect_corpus, 'create_public_corpus');

# Test for update_public_struct($self)
remove_tree("$test_public_dir/test_course");
# create test struct
$test_hash = {};
for (values @publicstruct) {
    my $test_path = join('/', $test_public_dir, 'test_course', $_ ); 
    make_path( $test_path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml"));
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml.vrt"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef,
                                        "$_.xml.vrt" => undef};
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
# prepare test struct
$test_hash = {};
for (values @publicstruct) {
    my $test_path = join('/', $test_data_dir, 'test_course', $_ ); 
    make_path( $test_path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml"));
    copy("$FindBin::Bin/examples/$_.xml", join("/", $test_path, "$_.xml.vrt"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef,
                                        "$_.xml.vrt" => undef};
}
$test_structhelper->update_data_struct;
# prepare expect
my $expect_public_meta_struct = {
    test_course   => {
        corpus    => {
            'corpus-file' => undef
        },
        library   => {
        },
        module     => {
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
    $expect_public_meta_struct, 'init_public_course');

# Test for get_public_struct($self)
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_struct(), 
    $expect_public_meta_struct, 'get_public_struct');

# Test for get_public_modul_struct($self,$course)
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_modul_struct('test_course'), 
    $expect_public_meta_struct->{test_course}, 'get_public_modul_struct with defined $course');

$number_of_tests_run++;
is($test_structhelper->get_public_modul_struct(), 
    undef, 'get_public_modul_struct with undefined $course');

# Test for get_public_page_path($self, $course_struct, $modul)
# prepare test data
my $test_course_meta_struct = Textmining::Plugin::StructureHelper::Course->new->get_course_struct( 
        join( '/', $test_modul->{path}, 'module.xml')
);
$test_course_meta_struct->{$test_modul_meta_struct->{meta}->{title}} =
        $test_modul_meta_struct;
$number_of_tests_run++;
is_deeply($test_structhelper->get_public_page_path(
            $test_course_meta_struct->{test_course}, 'module'),
        $test_course_meta_struct->{test_course}->{module},
        'get_public_page_path normal' );

$number_of_tests_run++;
is($test_structhelper->get_public_page_path( undef, 'module'), 
        undef,
        'get_public_page_path with undefined $course_struct');

$number_of_tests_run++;
is($test_structhelper->get_public_page_path($test_hash, 'module'),
        undef,
        'get_public_page_path with invalid $course_struct' );

$number_of_tests_run++;
is($test_structhelper->get_public_page_path( 
            $test_hash->{test_course}, undef),
        undef,
        'get_public_page_path with undefined $module');

# Test for get_public_navbar($self, $meta_struct, $modul)
# create test array
my @test_navbar_array = (
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
undef @got;
@got = $test_structhelper->get_public_navbar(
            $test_course_meta_struct, 'Test Modul');
is_deeply(\@got,
        \@test_navbar_array,
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
