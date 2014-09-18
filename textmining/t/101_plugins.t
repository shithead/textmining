use Mojo::Base -strict;
use Test::More;

use File::Path qw(remove_tree make_path);

my $number_of_tests_run = 1;
require_ok('Textmining::Plugin::StructureHelper');

done_testing( $number_of_tests_run );
