use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use File::Basename;
use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use FindBin;

use XML::LibXML;
use XML::LibXSLT;
$XML::LibXML::skipXMLDeclaration = 1;

my $number_of_tests_run = 1;
BEGIN {
    use_ok( 'Textmining::Plugin::StructureHelper::Transform' );
}

my $dir = tempdir( CLEANUP => 1 );
my $test_public = 'test-public';
my $test_data = 'test-data';
my $test_public_path = join('/', $dir, $test_public );
my $test_data_path = join('/', $dir, $test_data );

my @publicstruct = qw(module library corpus res);
my $test_hash = {};
for (values @publicstruct) {
    my $path = join('/', $test_data_path, 'test_course', $_ );
    make_path( $path );
    copy("$FindBin::Bin/examples/$_.xml", join("/", $path, "$_.xml"));
    $test_hash->{test_course}->{$_} = { "$_.xml" => undef};
}

my $test_res = join("/", $dir, "templates/res");
make_path($test_res);
make_path(join('/', $test_res, 'xsl'));
copy("$FindBin::Bin/examples/page.xsl", join("/", $test_res, 'xsl', "page.xsl"));
copy("$FindBin::Bin/examples/library.xml", join("/", $test_res, "library.xml"));
make_path( $test_public_path );

my $expect_xslfile = "$FindBin::Bin/examples/page.xsl";

# Test for get_xsl
$number_of_tests_run++;

my $expect_xsl;
$expect_xsl = XML::LibXML->load_xml(location => $expect_xslfile, no_cdata => 1);;

my $got_xsl = Textmining::Plugin::StructureHelper::Transform->get_xsl($expect_xslfile);
is_deeply($got_xsl, $expect_xsl, "get_xsl");

# Test for new
# prepare app
my $t = Test::Mojo->new('Textmining');
$t->app->home->parse($dir);

$number_of_tests_run++;
my $test_transform = Textmining::Plugin::StructureHelper::Transform->new->init($t->app);
isa_ok($test_transform, "Textmining::Plugin::StructureHelper::Transform");

# Test for get_doc
$number_of_tests_run++;

my $expect_module = join('/', $test_data_path, "test_course", 'module', 'module.xml');
my $expect_doc = XML::LibXML->load_xml(location => $expect_module);
my $got = $test_transform->get_doc($expect_module);
is_deeply($got, $expect_doc, "get_doc");


# Test for doctohtml
$number_of_tests_run++;

my $xslt = XML::LibXSLT->new();
my $expect_stylesheet  = $xslt->parse_stylesheet($expect_xsl);
my $expect_html = $expect_stylesheet->transform($expect_doc);

undef $got;
$test_transform->get_xsl($expect_xslfile);
$got = $test_transform->doctohtml($expect_doc);
is_deeply($got, $expect_html, "doctohtml");
undef $expect_html;


# TODO Test for nodestohtml
#$number_of_tests_run++;
#
#my @test_nodes = ("<node1>", "<node2>", "<node3>");
#my @expect_results;
#for my $node (@test_nodes) {
#    my $expect_html;
#    eval { $expect_html = $test_transform->doctohtml($node)->toString };
#    push @expect_results, $expect_html;
#}
#
undef $got;
#my @got_results = $test_transform->nodestohtml(\@test_nodes);
#is_deeply(\@expect_results, \@got_results, "nodestohtml");

# Test for update_xml_tag_img
# prepare test
my $test_course_path = join '/', $test_public_path, 'test_course';
$test_course_path =~ s/$dir//;
$test_course_path =~ s/\/[^\/]+\///;

#prepare expect
my @expect_img_src = (
    "test_course/test-img",
    "test_course/test-img-two",
    "test_course/test-img-two-two",
    "test_course/test-img-two-three",
    "test_course/test-img-three",
    "test_course/test-img-four",
    "https://test-img-five",
    "http://test-img-five-two",
    ""
);

$number_of_tests_run++;
undef $got;
$got = $test_transform->update_xml_tag_img($test_course_path, $expect_doc);
my @test_img_src = ($got->toString =~ m/<img.+src="(.*)">/g);
is_deeply(\@test_img_src, \@expect_img_src, 'update_xml_tag_img');

# Test for get_library_node
# prepare expect
my $expect_libraries_node ="<libraries><library>$test_res/library.xml</library></libraries>";

undef $got;
$got = $test_transform->get_library_node($expect_doc ,$test_res, ['library.xml']);
$number_of_tests_run++;
is($got->toString, $expect_libraries_node, 'get_library_node');

# TODO Test for xml_doc_pages
undef $got;
#$number_of_tests_run++;
my @got = $test_transform->xml_doc_pages(
        join('/', $test_data_path, 'test_course', 'module', 'module.xml'),
        join('/', 'test_course', 'library'),
        ['library.xml']
    );

my $counter = 0;
foreach (@got) {
    $number_of_tests_run++;
    $counter++;
    like($_->toString, qr/libraries/, "page $counter exists libraries");
}
undef $counter;
#
#
# done
done_testing( $number_of_tests_run );

