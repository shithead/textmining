use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $number_of_tests_run = 4;
BEGIN { 
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus::Statistic' );
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus::Count' );
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus::Statistic::CHI2' );
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR' );
}

my $t = Test::Mojo->new('Textmining');

# Test for new
$number_of_tests_run++;
my $test_statistic = Textmining::Plugin::StructureHelper::Corpus::Statistic->new->init($t->app);
like($test_statistic, qr/Textmining::Plugin::StructureHelper::Corpus::Statistic/, 'new Textmining::Plugin::StructureHelper::Corpus::Statistic');

# Test for CHI2 wrapping
$number_of_tests_run++;
my $got = Textmining::Plugin::StructureHelper::Corpus::Statistic::CHI2->new();
is($got->getName(), 'Chi-squared test', 'chi2 getName');

# Test for LLR wrapping
$number_of_tests_run++;
$got = Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR->new();   
is($got->getName(), 'Log-likelihood', 'llr getName');

# Test for get_freq_idx
# prepare except array
my @expect_array = ( [ undef, 1 ], [ 2, 0 ] );
$number_of_tests_run++;
$got = $test_statistic->get_freq_idx(2);
is_deeply($got, \@expect_array, 'get_freq_idx with bigram');

# Test for statistic
my $test_ngram =
"11
line<>of<>2 3 2
of<>text<>2 2 2
second<>line<>1 1 3
line<>and<>1 3 1
and<>a<>1 1 1
a<>third<>1 1 1
first<>line<>1 1 3
third<>line<>1 1 3
text<>second<>1 1 1
";

my $expect_ngram = {
    'chi2' => {
        '2.9333'  =>  {
            '1 1 3' =>  {
                'first<>line'  =>  undef,
                'second<>line' =>  undef,
                'third<>line'  =>  undef
            },
            '1 3 1' =>  {
                'line<>and'  => undef
            }
        },
        '6.5185'  =>  {
            '2 3 2' =>  {
                'line<>of'  => undef
            }
        },
        '11.0000' =>  {
            '1 1 1' =>  {
                'and<>a'        => undef,
                'a<>third'      => undef,
                'text<>second'  => undef
            },
            '2 2 2' =>  {
                'of<>text' => undef
            }
        }
    },
    llr   => {
        '2.8829'   => {
            '1 1 3'  => {
                'first<>line'   => undef,
                'second<>line'  => undef,
                'third<>line'   => undef
            },
            '1 3 1'  => {
                'line<>and'  => undef
            }
        },
        '6.6120'   => {
            '2 3 2'  => {
                'line<>of'  => undef
            }
        },
        '6.7020'   => {
            '1 1 1'  => {
                'and<>a'        => undef,
                'a<>third'      => undef,
                'text<>second'  => undef
            }
        },
        '10.4311'  => {
            '2 2 2'  => {
                'of<>text'  => undef
            }
        }
    }
};

$number_of_tests_run++;

$got = $test_statistic->collocation('chi2', $test_ngram);
my $got_llr = $test_statistic->collocation('llr', $test_ngram);
$got->{llr} = $got_llr->{llr};
is_deeply($got, $expect_ngram, 'statistic');

# Test for compare
# prepare expect
my $expect_compare = {
    chi2   => {
        '1.9141'   => {
            'line<>of'  => [ 2,2 ],
            'of<>text'  => [ 2,2 ]
        },
        '3.4341'   => {
            'and<>a'         => [ 1,1 ],
            'a<>third'       => [ 1,1 ],
            'first<>line'    => [ 1,1 ],
            'line<>and'      => [ 1,1 ],
            'second<>line'   => [ 1,1 ],
            'text<>second'   => [ 1,1 ],
            'third<>line'    => [ 1,1 ]
        }
    },
    llr    => {
        '0.0000'   => {
            'and<>a'        => [ 1,1 ],
            'a<>third'      => [ 1,1 ],
            'first<>line'   => [ 1,1 ],
            'line<>and'     => [ 1,1 ],
            'line<>of'      => [ 2,2 ],
            'of<>text'      => [ 2,2 ],
            'second<>line'  => [ 1,1 ],
            'text<>second'  => [ 1,1 ],
            'third<>line'   => [ 1,1 ]
        }
    }
};

# prepare test data
my $test_token = {
'line<>of'    => 2,
'of<>text'    => 2,
'second<>line'=> 1,
'line<>and'   => 1,
'and<>a'      => 1,
'a<>third'    => 1,
'first<>line' => 1,
'third<>line' => 1,
'text<>second'=> 1
};

my @test_ngrams = ($test_token, $test_token );
undef $got;

$number_of_tests_run++;
$got = $test_statistic->compare(\@test_ngrams, 1);

is_deeply($got, $expect_compare, 'compare');

done_testing( $number_of_tests_run );
