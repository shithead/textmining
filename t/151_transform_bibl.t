use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use File::Basename;
use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use FindBin;

my $number_of_tests_run = 1;
BEGIN {
    use_ok( 'Textmining::Plugin::StructureHelper::Transform' );
}

my $dir = tempdir( CLEANUP => 1 );
my $test_public = 'test-public';
my $test_data = 'test-data';
my $test_public_path = join('/', $dir, $test_public );
my $test_data_path = join('/', $dir, $test_data );

my @publicstruct = qw(library res);
for (values @publicstruct) {
    my $dest_dir = join('/', $test_data_path, 'test_course', $_ );
    make_path( $dest_dir );
}
copy("$FindBin::Bin/examples/library.xml", join('/', $test_data_path, 'test_course', "library", "library.xml"));
my $test_bibl = join('/', $test_data_path, 'test_course', "library", "library.xml");

dircopy("$FindBin::Bin/../templates/res/xsl", join('/', $test_data_path, 'test_course', "res", "xsl"));
my $test_xsl = join('/', $test_data_path, 'test_course', "res", "xsl", "page-library.xsl");

# prepare app
my $t = Test::Mojo->new('Textmining');
$t->app->home->parse($dir);

#$number_of_tests_run++;
my $transform = Textmining::Plugin::StructureHelper::Transform->new->init($t->app);
my $xsl_doc = $transform->get_xsl($test_xsl);
my $bibl_doc = $transform->get_doc($test_bibl);

# test library/biblography transforming
my $expect_html_string='<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/><meta charset="utf-8"/><link rel="stylesheet" href="css/bootstrap.min.css" media="screen"/><link rel="stylesheet" href="css/bootstrap.css" media="screen"/><link rel="stylesheet" href="css/font-awesome.min.css"/></head><body><dl class="listBibl"><dt><a name="test-one"><!--anchor--></a>
                    Testname one
                </dt><dd>
        
            <span class="titlem">
                Test bibo one
            </span>, 
            
                    Testname one
                . . 
            

</dd><dt><a name="test-two"><!--anchor--></a>
                is named
            </dt><dd>
    
        <span class="titlem">
            Test bibo two
        </span>, 
        
                Test
             
                is named
            . 
        

</dd></dl></body></html>';
$number_of_tests_run++;
my $test_html = $transform->doctohtml($bibl_doc);
is($test_html->toString, $expect_html_string, "biblo transform");

done_testing( $number_of_tests_run );
