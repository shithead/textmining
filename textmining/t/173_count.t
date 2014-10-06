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
my $CorpusCount = Textmining::Plugin::StructureHelper::Corpus::Count->new();

like($CorpusCount,
    qr/Textmining::Plugin::StructureHelper::Corpus::Count/,
    'new Textmining::Plugin::StructureHelper::Corpus::Count');

# Test for vrt_token
$number_of_tests_run++;
my $got = $CorpusCount->vrt_token();
my $test_token = { wortform => "^(.+?)\t", 
                   pos      => "\t(.+?)\t",
                   lemma    => "\t([^\t]+)\$" 
                };

is_deeply($got, $test_token, 'vrt_token');


# Test for get_permutations
$number_of_tests_run++;
my @test_permutations = qw(0 1 2 0 1 3 0 1 4 0 2 3 0 2 4 0 3 4 1 2 3 1 2 4 1 3 4 2 3 4);

my @got = $CorpusCount->get_permu(5, 3);
#p @got;
is_deeply(\@got, \@test_permutations, 'get_permute');

# Test for calc_freq_combo
$number_of_tests_run++;
my @expect_combo = ([ 2, 0, 1 ], [ 1, 0 ], [ 1, 1 ]);

undef @got;
@got = $CorpusCount->calc_freq_combo($test_ngram);
is_deeply(\@got, \@expect_combo, 'calc_freq_combo');

my @test_freq_combo =   @expect_combo;

# Test for get_ngram_freq
undef @test_permutations;
@test_permutations = $CorpusCount->get_permu(
        $test_windowsize - 1 ,
        $test_ngram - 1
    );

my $expect_hash_token = {
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

        %got = $CorpusCount->get_ngram_freq(
            \@test_permutations,
            \@test_freq_combo,
            $token,
            $test_windowsize,
            $test_ngram);
    }
}
close FH;

#p %got;
is_deeply(\%got, $expect_hash_token, 'get_ngram_freq');

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

my $test_ngram_freq = $expect_hash_token;

undef $got;
$number_of_tests_run++;
$got = $CorpusCount->sort_ngram_freq(
        $test_ngram_freq,
        \@test_freq_combo
    );

is($got, $expect_sort_ngram_freq, 'sort_ngram_freq');

done_testing( $number_of_tests_run );
