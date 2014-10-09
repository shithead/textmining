use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use XML::LibXML;
use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use FindBin;

my $number_of_tests_run = 1;
BEGIN { 
    use_ok( 'Textmining::Plugin::StructureHelper::Course' );
}

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
}
copy("$FindBin::Bin/examples/page.xsl", join("/", $test_data_dir, "page.xsl"));
my $test_doc  = XML::LibXML->load_xml(location => join('/', $test_data_dir, 'test_course', 'modul', 'modul.xml' ));

# Test for new
# prepare app
my $t = Test::Mojo->new('Textmining');
$number_of_tests_run++;
my $test_struct_course = Textmining::Plugin::StructureHelper::Course->new->init($t->app);
like($test_struct_course, qr/Textmining::Plugin::StructureHelper::Course/, 'new Textmining::Plugin::StructureHelper::Course');

# Test for get_node_metastruct
# prepare expect
my $expect_course_hash = {
        meta  => {
            authors  => [
                "Matthias Jakobi",
                "N. N."
            ],
            date     => "2014-09-18",
            title    => "test course",
            version  => '1.0'
        },
        sub   => [],
        type  => ""
};
my $got = $test_struct_course->get_node_metastruct($test_doc, '/course');
$number_of_tests_run++;
is_deeply($got, $expect_course_hash, 'get_node_metastruct /course');

# prepare expect
my $expect_course_modul_hash = {
    meta  => {
        authors    => [
            "Matthias Jakobi"
        ],
        corpora    => {
            'corpus-directory'  => {
                parts  => "party,year",
                src    => "corpus",
                type   => "keywords"
            },
            'corpus-file'       => {
                parts  => "party,year",
                src    => "corpus.xml.vrt",
                type   => "keywords"
            },
            'corpus-file-two'       => {
                parts  => undef,
                src    => "corpus2.xml.vrt",
                type   => "collocation"
            }
        },
        date        => "2014-09-18",
        libraries   => [
            "library.xml"
        ],
        title    => "Test Modul",
        version  => '1.0'
    },
    sub   => [],
    type  => ""
};

$got = $test_struct_course->get_node_metastruct($test_doc, '/course/module');
$number_of_tests_run++;
is_deeply($got, $expect_course_modul_hash, 'get_node_metastruct /course/module');

# Test for get_modul_struct
# prepare expect
$expect_course_modul_hash->{sub} = [
    {
        head     => "Ziele des Tests\"",
        id       => "testziel",
        pagecnt  => 2,
        type     => "test-type"
    },
    {
        head     => "Test Two",
        id       => "twotestid",
        pagecnt  => 3,
        type     => undef
    },
    {
        head     => "Test Three",
        id       => "threetetestid",
        pagecnt  => 1,
        type     => undef
    },
    {
        head     => "Test four",
        id       => "fourtestid",
        pagecnt  => 1,
        type     => undef
    },
    {
        head     => "Test five",
        id       => "fivetestid",
        pagecnt  => 3,
        type     => undef
    }
];
$expect_course_modul_hash->{type} =   "modul";
$got = $test_struct_course->get_modul_struct(join('/', $test_data_dir, 'test_course', 'modul', 'modul.xml'));

$number_of_tests_run++;
is_deeply($got, $expect_course_modul_hash, 'get_modul_struct');

# Test get_course_struct
# prepare expect
$expect_course_hash->{type} =   "course";
$got = $test_struct_course->get_course_struct( join('/', $test_data_dir, 'test_course', 'modul', 'modul.xml'));
$number_of_tests_run++;
is_deeply($got, $expect_course_hash, 'get_course_struct');

done_testing($number_of_tests_run);
