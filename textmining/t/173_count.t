use Mojo::Base -strict;
use Test::More;
use FindBin;

use Data::Printer;

my $number_of_tests_run = 1;
BEGIN { 
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus::Count' );
}

my $test_ngram = '2';
my $test_windowsize = '2';
my $test_file = "$FindBin::Bin/examples/corpus.xml";

# Test for new
$number_of_tests_run++;
my $test_count = Textmining::Plugin::StructureHelper::Corpus::Count->new();

like($test_count,
    qr/Textmining::Plugin::StructureHelper::Corpus::Count/,
    'new Textmining::Plugin::StructureHelper::Corpus::Count');

# Test for vrt_token
$number_of_tests_run++;
my $got = $test_count->vrt_token();
my $test_token = { wortform => "^(.+?)\t", 
                   pos      => "\t(.+?)\t",
                   lemma    => "\t([^\t]+)\$" 
                };

is_deeply($got, $test_token, 'vrt_token');


# Test for get_permutations
$number_of_tests_run++;
my @test_permutations = qw(0 1 2 0 1 3 0 1 4 0 2 3 0 2 4 0 3 4 1 2 3 1 2 4 1 3 4 2 3 4);

my @got = $test_count->get_permu(5, 3);
#p @got;
is_deeply(\@got, \@test_permutations, 'get_permute');

# Test for calc_freq_combo
$number_of_tests_run++;
my @expect_combo = ([ 2, 0, 1 ], [ 1, 0 ], [ 1, 1 ]);

undef @got;
@got = $test_count->calc_freq_combo($test_ngram);
is_deeply(\@got, \@expect_combo, 'calc_freq_combo');

my @test_freq_combo =   @expect_combo;

# Test for get_ngram_freq
undef @test_permutations;
@test_permutations = $test_count->get_permu(
        $test_windowsize - 1 ,
        $test_ngram - 1
    );

my $expect_ngram_freq = {
    'a<>test<>'          => 1,
    'Count<>.<>'         => 1,
    'for<>Count<>'       => 1,
    'is<>a<>'            => 1,
    '.<>pm<>'            => 1,
    'pm<>their<>'        => 1,
    'test<>written<>'    => 1,
    'their<>them<>'      => 1,
    'them<>together<>'   => 1,
    'this<>is<>'         => 1,
    'together<>wither<>' => 1,
    'wither<>tithe<>'    => 1,
    'written<>for<>'     => 1
};

$number_of_tests_run++;
undef @got;
my %got;

open FH, "$test_file";
while (<FH>) {
    while ( /$test_token->{wortform}/g ) {
        my $token = $&;

        %got = $test_count->get_ngram_freq(
            \@test_permutations,
            \@test_freq_combo,
            $token,
            $test_windowsize,
            $test_ngram);
    }
}
close FH;

#p %got;
is_deeply(\%got, $expect_ngram_freq, 'get_ngram_freq');

# Test for get_frequency
my $expect_freq = {
    '.<>1'                => 1,
    '.<>2'                => 1,
    'a<>test<>0'          => 1,
    'a<>1'                => 1,
    'a<>2'                => 1,
    'Count<>.<>0'         => 1,
    'Count<>1'            => 1,
    'Count<>2'            => 1,
    'for<>Count<>0'       => 1,
    'for<>1'              => 1,
    'for<>2'              => 1,
    'is<>a<>0'            => 1,
    'is<>1'               => 1,
    'is<>2'               => 1,
    '.<>pm<>0'            => 1,
    'pm<>their<>0'        => 1,
    'pm<>1'               => 1,
    'pm<>2'               => 1,
    'test<>written<>0'    => 1,
    'test<>1'             => 1,
    'test<>2'             => 1,
    'their<>them<>0'      => 1,
    'their<>1'            => 1,
    'their<>2'            => 1,
    'them<>together<>0'   => 1,
    'them<>1'             => 1,
    'them<>2'             => 1,
    'this<>is<>0'         => 1,
    'this<>1'             => 1,
    'tithe<>2'            => 1,
    'together<>wither<>0' => 1,
    'together<>1'         => 1,
    'together<>2'         => 1,
    'wither<>tithe<>0'    => 1,
    'wither<>1'           => 1,
    'wither<>2'           => 1,
    'written<>for<>0'     => 1,
    'written<>1'          => 1,
    'written<>2'          => 1
};

my $test_ngram_freq =  $expect_ngram_freq;
$number_of_tests_run++;
$got = $test_count->get_frequency( $test_ngram, $test_ngram_freq);
is_deeply($got, $expect_freq, 'get_frequency');

# Test for sort_ngram_freq
my $expect_sort_ngram_freq = '13
this<>is<>1 1 1 
test<>written<>1 1 1 
Count<>.<>1 1 1 
.<>pm<>1 1 1 
for<>Count<>1 1 1 
a<>test<>1 1 1 
is<>a<>1 1 1 
them<>together<>1 1 1 
pm<>their<>1 1 1 
their<>them<>1 1 1 
written<>for<>1 1 1 
wither<>tithe<>1 1 1 
together<>wither<>1 1 1 
';

undef $got;
$number_of_tests_run++;
$got = $test_count->sort_ngram_freq(
        $test_ngram,
        $test_ngram_freq
    );

is($got, $expect_sort_ngram_freq, 'sort_ngram_freq');

done_testing( $number_of_tests_run );
