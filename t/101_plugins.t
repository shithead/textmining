use Mojo::Base -strict;
use Test::More;

use File::Path qw(remove_tree make_path);

my $number_of_tests_run = 1;
require_ok('Textmining::Plugin::StructureHelper');

$number_of_tests_run++;
require_ok('Textmining::Plugin::StructureHelper::Course');

$number_of_tests_run++;
require_ok('Textmining::Plugin::StructureHelper::Corpus');

done_testing( $number_of_tests_run );
