use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use File::Path qw(remove_tree make_path);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use FindBin;

use Data::Printer;

my $number_of_tests_run = 1;
BEGIN { 
    use_ok( 'Textmining::Plugin::StructureHelper::Corpus' );
}

my $dir = tempdir( CLEANUP => 1 );
#my $dir = tempdir();
#($fh, $filename) = tempfile( DIR => $dir );
my $test_corpus_dir = 'test-corpus';

my $test_dir = join('/', $dir, $test_corpus_dir );
my $test_files = [qw(corpus.xml.vrt)];
my $test_path = join("/", $test_dir, "corpus.xml.vrt");
make_path( $test_dir );
copy( "$FindBin::Bin/examples/corpus.xml", $test_path);

# prepare app
my $t = Test::Mojo->new('Textmining');

# Test for new
$number_of_tests_run++;
my $test_corpus = Textmining::Plugin::StructureHelper::Corpus->new->init($t->app);

like( $test_corpus,
    qr/Textmining::Plugin::StructureHelper::Corpus/, 
    "new Textmining::Plugin::StructureHelper::Corpus");


# Test attributes
$number_of_tests_run += 2;
is($test_corpus->keywords, 1, 'attribute keywords');
is($test_corpus->collocation, 2, 'attribute collocation');

# Test for get_corpus_docs
my $expect_doc_content =
'<text id="foobarid" author="Blablub" party="undef" year="2014">
<body>
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
.	IN	.
pm	GL	pm
their	NO	their
them	NO	them
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
.	IN	.
pm	GL	pm
their	NO	their
them	NO	them
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
.	IN	.
pm	GL	pm
their	NO	their
them	NO	them
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
.	IN	.
pm	GL	pm
their	NO	their
them	NO	them
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
tithe	LO	tithe
this	FO	this
is	BA	is
a	RA	a
test	NN	test
written	GL	write
for	IN	for
Count	NNO	count
.	IN	.
pm	GL	pm
their	NO	their
them	NO	them
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
together	FO	togehter
wither	LO	wither
tithe	LO	tithe
</body>
</text>';

my $got = $test_corpus->get_corpus_docs( $test_dir, $test_files );

$number_of_tests_run++;
like(ref $got, qr/ARRAY/, 'get_corpus_docs return ARRAY');

$number_of_tests_run++;
is(@{$got}, 1,  'get_corpus_docs return one element');

$number_of_tests_run++;
is($got->[0], $expect_doc_content, 'get_corpus_docs is Document');


# Test for get_metastruct
my $test_docs = $got;
# create test hash
my $expect_hash = {
    author  => "Blablub",
    corpus  => {
        token => {},
        windowsize => [],
        statistic  => {
            chi2 => {},
            llr => {}
        } 
    },
    date    => undef,
    fpath   => '',
    id      => "foobarid",
    party   => 'undef',
    subtitle=> undef,
    title   => undef,
    type    => undef,
    year    => 2014
};

$number_of_tests_run++;
undef $got;
$got = $test_corpus->get_metastruct($test_docs->[0], '/text');
is_deeply($got, $expect_hash, 'get_metastruct' );

# Test for extract_corpus
# TODO More tests;
$number_of_tests_run++;
undef $got;

$got = $test_corpus->extract_corpus($test_docs->[0], '/text/body' );
ok(length($got) > 0, 'extract_corpus');

# Test for calc_corpus
my $test_extract_corpus = $got;

# prepare expect
my @expect_freq_array = (
    {
        lemma     => {
            '.'       => 5,
            'a'       => 6,
            'count'   => 6,
            'for'     => 6,
            'is'      => 6,
            'pm'      => 5,
            'test'    => 6,
            'their'   => 5,
            'them'    => 5,
            'this'    => 6,
            'tithe'   => 7,
            'togehter'=> 6,
            'wither'  => 6,
            'write'   => 6
        },
        pos      => {
            'BA' => 6,
            'FO' => 12,
            'GL' => 11,
            'IN' => 11,
            'LO' => 13,
            'NN' => 6,
            'NNO'=> 6,
            'NO' => 10,
            'RA' => 6
        },
        wortform => {
            '.'       => 5,
            'a'       => 6,
            'Count'   => 6,
            'for'     => 6,
            'is'      => 6,
            'pm'      => 5,
            'test'    => 6,
            'their'   => 5,
            'them'    => 5,
            'this'    => 6,
            'tithe'   => 7,
            'together'=> 6,
            'wither'  => 6,
            'written' => 6
        }
    }
);
undef $got;
$number_of_tests_run++;
$got = $test_corpus->count_corpus($test_extract_corpus, 'vrt', $test_corpus->keywords);
#p $got;
is_deeply($got, \@expect_freq_array, 'count_corpus');

# Test for get_corpus
# prepare expect
undef $expect_hash;
my $expect_freq_hash = {
    id => {
        foobarid => {
            author  => "Blablub",
            corpus  => {
                token => $expect_freq_array[0],
                windowsize =>\@expect_freq_array,
                statistic  => {
                    chi2 => {},
                    llr => {}
                } 
            },
            date    => undef,
            fpath   => "vrt",
            id      => "foobarid",
            party   => 'undef',
            subtitle=> undef,
            title   => undef,
            type    => undef,
            year    => 2014
        }
    },
    party  => {
        undef  => {
            foobarid  => $expect_freq_array[0]
        }
    },
    year   => {
        2014  => {
            foobarid  => $expect_freq_array[0]
        }
    }
};

my $test_filter = [qw(party year)];
undef $got;
$number_of_tests_run++;
$got = $test_corpus->get_corpus($test_dir, $test_files, $test_filter, $test_corpus->keywords);
#p $got;
is_deeply($got, $expect_freq_hash, 'get_corpus');

# Test for compare_corpus
my $test_freq_hash = $expect_freq_hash;
$expect_freq_hash->{id}->{foobarid}->{corpus}->{statistic} = {
    chi2 =>  {                                                            
        '4.8407' =>  {
            '.'          => [ 1,1 ],
            'a'          => [ 1,1 ],
            'Count'      => [ 1,1 ],
            'for'        => [ 1,1 ],
            'is'         => [ 1,1 ],
            'pm'         => [ 1,1 ],
            'test'       => [ 1,1 ],
            'their'      => [ 1,1 ],
            'them'       => [ 1,1 ],
            'this'       => [ 1,1 ],
            'tithe'      => [ 1,1 ],
            'together'   => [ 1,1 ],
            'wither'     => [ 1,1 ],
            'written'    => [ 1,1 ]
        }
    },
    llr =>   {
        '0.0000' =>  {
            '.'          => [ 1,1 ],
            'a'          => [ 1,1 ],
            'Count'      => [ 1,1 ],
            'for'        => [ 1,1 ],
            'is'         => [ 1,1 ],
            'pm'         => [ 1,1 ],
            'test'       => [ 1,1 ],
            'their'      => [ 1,1 ],
            'them'       => [ 1,1 ],
            'this'       => [ 1,1 ],
            'tithe'      => [ 1,1 ],
            'together'   => [ 1,1 ],
            'wither'     => [ 1,1 ],
            'written'    => [ 1,1 ]
        }
    }
};
$number_of_tests_run++;
$got = $test_corpus->compare_corpus($test_freq_hash, 1);
#p $got;
is_deeply($got, $expect_freq_hash, 'compare corpus');

# Test for collocation_corpus
my $test_ngram_freq = {
    wortfrom => {
        'line<>of<>'    =>  2,
        'of<>text<>'    =>  2,
        'second<>line<>'=>  1,
        'line<>and<>'   =>  1,
        'and<>a<>'      =>  1,
        'a<>third<>'    =>  1,
        'first<>line<>' =>  1,
        'third<>line<>' =>  1,
        'text<>second<>'=>  1
    }
};
$test_freq_hash->{id}->{foobarid}->{corpus}->{token} = $test_ngram_freq;
$test_freq_hash->{id}->{foobarid}->{corpus}->{windowsize} = 
        [$test_ngram_freq, undef, $test_ngram_freq];
$test_freq_hash->{party}->{undef}->{foobarid} = $test_ngram_freq;
$test_freq_hash->{year}->{2014}->{foobarid} = $test_ngram_freq;

my $expect_ngram_stat = {
    chi2  => {
        '2.2500'  => {
            '1 1 3'  => {
                'first<>line'    => undef,
                'second<>line'   => undef,
                'third<>line'    => undef
            }
        },
        '3.9375'   => {
            '1 2 1'   => {
                'line<>and'   => undef,
                'line<>of'    => undef
            }
        },
        '9.0000'   => {
            '1 1 1'   => {
                'and<>a'         => undef,
                'a<>third'       => undef,
                'of<>text'       => undef,
                'text<>second'   => undef
            }
        }
    },
    llr    => {
        '2.4599'   => {
            '1 1 3'   => {
                'first<>line'    => undef,
                'second<>line'   => undef,
                'third<>line'    => undef
            }
        },
        '3.5064'   => {
            '1 2 1'   => {
                'line<>and'   => undef,
                'line<>of'    => undef
            }
        },
        '6.2790'   => {
            '1 1 1'   => {
                'and<>a'         => undef,
                'a<>third'       => undef,
                'of<>text'       => undef,
                'text<>second'   => undef
            }
        }
    }
};

my $expect_collocation_freq_hash = $test_freq_hash;
$expect_collocation_freq_hash->{id}->{foobarid}->{corpus}->{statistic} =
        $expect_ngram_stat;

$number_of_tests_run++;
$got = $test_corpus->collocation_corpus(
        $test_freq_hash,
        $test_corpus->collocation
    );

#p $got;
is_deeply($got, $expect_collocation_freq_hash, 'collocation_corpus');

done_testing( $number_of_tests_run );
