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
my $test_files = { 'corpus.xml.vrt' => undef };
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
    corpus  => undef,
    date    => undef,
    fpath   => undef,
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
my @expect_array = (
            undef,
            {
            lemma     => {
                '.<>'       => 1,
                'a<>'       => 1,
                'count<>'   => 1,
                'for<>'     => 1,
                'is<>'      => 1,
                'pm<>'      => 1,
                'test<>'    => 1,
                'their<>'   => 1,
                'them<>'    => 1,
                'this<>'    => 1,
                'tithe<>'   => 1,
                'togehter<>'=> 1,
                'wither<>'  => 1,
                'write<>'   => 1
            },
            pos      => {
                'BA<>' => 1,
                'FO<>' => 2,
                'GL<>' => 2,
                'IN<>' => 2,
                'LO<>' => 2,
                'NN<>' => 1,
                'NNO<>'=> 1,
                'NO<>' => 2,
                'RA<>' => 1
            },
            wortform => {
                '.<>'       => 1,
                'a<>'       => 1,
                'Count<>'   => 1,
                'for<>'     => 1,
                'is<>'      => 1,
                'pm<>'      => 1,
                'test<>'    => 1,
                'their<>'   => 1,
                'them<>'    => 1,
                'this<>'    => 1,
                'tithe<>'   => 1,
                'together<>'=> 1,
                'wither<>'  => 1,
                'written<>' => 1
            }
        }
    );
undef $got;
$number_of_tests_run++;
$got = $test_corpus->count_corpus($test_extract_corpus, 'vrt', 1);
is_deeply($got, \@expect_array, 'count_corpus');


# TODO Test for get_corpus 
# prepare expect
undef $expect_hash;
$expect_hash = {
    id => {
        foobarid => {
            author  => "Blablub",
            corpus  => \@expect_array,
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
            foobarid  => \@expect_array
        }
    },
    year   => {
        2014  => {
            foobarid  => \@expect_array
        }
    }
};

my $test_filter = [qw(party year)];
undef $got;
$number_of_tests_run++;
$got = $test_corpus->get_corpus($test_dir, $test_files, $test_filter, $test_corpus->keywords);
is_deeply($got, $expect_hash, 'get_corpus');

done_testing( $number_of_tests_run );
