use Mojo::Base -strict;
use Test::More;

my $number_of_tests_run = 1;
require_ok('File::Path');

$number_of_tests_run++;
require_ok('File::Basename');

$number_of_tests_run++;
require_ok('File::Temp');

$number_of_tests_run++;
require_ok('File::Copy');

$number_of_tests_run++;
require_ok('XML::LibXML');

$number_of_tests_run++;
require_ok('XML::LibXSLT');

done_testing( $number_of_tests_run );
