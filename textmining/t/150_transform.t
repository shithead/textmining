use Mojo::Base -strict;
use Test::More;

use File::Basename;
use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use FindBin;

my $number_of_tests_run = 1;
BEGIN {
    use_ok( 'Textmining::Plugin::StructureHelper::Transform' );
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

my $xslt = XML::LibXSLT->new();
my $need_hash = {};
bless $need_hash;


# test for get_xsl
$number_of_tests_run++;

my $expect_xsl;
eval{ $expect_xsl = XML::LibXML->load_xml(location => 't/examples/page.xsl', , no_cdata => 1); };

my $got_xsl = $need_hash->Textmining::Plugin::StructureHelper::Transform::get_xsl('t/examples/page.xsl');
is_deeply($got_xsl, $expect_xsl, "loading a xslt-file works (get_xsl)");

my $got_stylesheet  = $xslt->parse_stylesheet($got_xsl);
$need_hash->{xslt} = $got_stylesheet;


# Test for new
$number_of_tests_run++;
my $test_transform = Textmining::Plugin::StructureHelper::Transform->new();
like($test_transform, qr/Textmining::Plugin::StructureHelper::Transform/, 'new Textmining::Plugin::StructureHelper::Transform');

$test_transform->{_path}->{data} = $test_data_dir;
$test_transform->{_path}->{public} = $test_public_dir;


# test for get_doc
$number_of_tests_run++;

my $expect_doc = XML::LibXML->load_xml(location => 't/examples/modul.xml');
my $got_doc = $test_transform->get_doc('t/examples/modul.xml');
is_deeply($got_doc, $expect_doc, "loading a xml-file works (get_doc)");


# Test for doctohtml
$number_of_tests_run++;

my $expect_html;
eval { $expect_html = $test_transform->{xslt}->transform($got_doc) };

my $got_html = $test_transform->doctohtml($got_doc);
is_deeply($got_html, $expect_html, "transform docs to html works (doctohtml)");
undef $expect_html;


# Test for nodestohtml
$number_of_tests_run++;

my @test_nodes = ("<node1>", "<node2>", "<node3>");
my @expect_results;
for my $node (@test_nodes) {
    my $expect_html;
    eval { $expect_html = $test_transform->doctohtml($node->toString)->toString };
    push @expect_results, $expect_html;
}

my @got_results = $test_transform->nodestohtml(@test_nodes);
is_deeply(\@expect_results, \@got_results, "transform nodes to html works (notestohtml)");

# Test for xml_doc_pages
$number_of_tests_run++;

my @got_pages = $test_transform->xml_doc_pages('t/examples/modul.xml','t/examples/',['t/examles/library.xml']);

for my $page (@got_pages) {
    ok($page->exists("library"), "page ok");
    $number_of_tests_run++;
}


# done
done_testing( $number_of_tests_run );

