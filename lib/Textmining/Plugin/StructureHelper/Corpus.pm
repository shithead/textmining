#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Corpus;
# ABSTRACT: Corpus library for create corpus.

=head1 SYNOPSIS

...

=method get_body()

This method

=method get_metastruct()

This method

=method get_word_freq()

This method

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Corpus>
* L<Textmining::Plugin::StructureHelper::Corpus::Count>
* L<Textmining::Plugin::StructureHelper::Corpus::Statistic>
* L<Textmining::Plugin::StructureHelper::Transform>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;
use File::Basename;
use Textmining::Plugin::StructureHelper::Transform;
use Textmining::Plugin::StructureHelper::Corpus::Count;
use Textmining::Plugin::StructureHelper::Corpus::Statistic;

sub init ($$) {
    my ($self, $app)    =   @_;
    $self->{log}        =   $app->log;
    $self->{transform}  = Textmining::Plugin::StructureHelper::Transform->new->init($app);
    return $self;
}

has collocation => 2;
has keywords    => 1;

sub extract_corpus ($$$) {
    my $self    = shift;
    my $corpus_doc = shift;
    my $xpath   = shift or scalar "/"; # set another node or the current one
    my $first_node = fileparse($xpath);
    my $body = undef;
    if ($corpus_doc->exists($xpath)) {
        $body = $corpus_doc->findnodes($xpath)->get_node(1)->toString();
        chomp $body;
        $body =~ s/<$first_node>//;
        $body =~ s/<\/$first_node>//;
        $body =~ s/^\s*//;
        $body =~ s/\s*$//;
    }
    return $body;
}

sub get_metastruct ($$$) {
    my $self    = shift;
    my $corpus_doc  = shift;
    my $xpath   = shift || scalar "/"; # set another node or the current one

    my $hash = {
        author  => "",
        corpus  => {
            token => {},
            windowsize => [],
            statistic  => {
                chi2 => {},
                llr => {}
            }
        },
        date    => "",
        fpath   => "",
        id      => "",
        party   => "",
        subtitle=> "",
        title   => "",
        type    => "",
        year    => ""
    };

    if ($corpus_doc->exists($xpath)) {
        my $node = $corpus_doc->find($xpath)->get_node(1);
        foreach my $attr  (keys $hash) {
            $hash->{$attr} = $node->getAttribute($attr)
                    unless ( $attr ~~ [qw(corpus fpath)] );
        }
    }
    return $hash;
}

sub get_corpus_docs($$$) {
    my $self    =   shift;
    my $dir     =   shift;
    my $files   =   shift;
    my @docs;

    for my $file (sort values $files) {
        my $path = join('/', $dir, $file);
        my $doc =   $self->{transform}->get_doc($path);
        push @docs, $doc;
    }
    return wantarray ? @docs : \@docs;
}

sub count_corpus ($$$$) {
    my $self        = shift;
    my $corpus      = shift || undef;
    my $token_type  = shift;
    my $ngram       = shift || scalar '2';

    return undef unless (defined $corpus);

    my $count =
    Textmining::Plugin::StructureHelper::Corpus::Count->new;
    my $tokens;
    if ($token_type =~ /vrt/) {
        $tokens         = $count->vrt_token();
    }

    my $freq_comb       = $count->get_freq_combo($ngram);

    my $words;
    for my $line (split '\n', $corpus) {
        for my $key (keys $tokens) {
            if ( $line =~ $tokens->{$key}) {
                push @{$words->{$key}}, $1;
            }
        }
    }

    my @ngrams_freq;
    my @windows = (0);
    @windows = qw(0 2 3 4 5 6 7 8 9 10) if ($ngram > 1);
    #@windows = qw(1 2 3 4 5) if ($ngram > 1);
    for my $window_size (values @windows) {
        my $permu = $count->get_permu(
            $window_size - 1,
            $ngram - 1
        );

        my $ngram_freq = {};
        foreach my $key (keys $words) {
            $ngram_freq->{$key} = { $count->get_ngram_freq(
                    $permu,
                    $freq_comb,
                    $_,
                    $window_size,
                    $ngram
                ) } foreach (values $words->{$key});
            $count->clearup();
            $count->calc_freq_combo($ngram);

            $ngrams_freq[$window_size] = $ngram_freq;
        }
    }
    return wantarray ? @ngrams_freq : \@ngrams_freq;
}

sub compare_corpus ($$$) {
    my $self        = shift;
    my $corpus_data = shift;
    my $min_freq    = shift;

    my $corpus_total;
    my $corpus_parts;
    for my $id (keys $corpus_data->{id}) {
        my $corpus_token = $corpus_data->{id}->{$id}->{corpus}->{token};
        for my $token (keys $corpus_token) {
            for my $word (keys $corpus_token->{$token}) {
                $corpus_total->{$token}->{$word} = 0
                        unless (defined $corpus_total->{$token}->{$word});
                $corpus_total->{$token}->{$word} +=
                        $corpus_token->{$token}->{$word};
            }
        }
        $corpus_parts->{$id} = $corpus_token;
    }

    my $statistic = Textmining::Plugin::StructureHelper::Corpus::Statistic->new();
    for my $token (keys $corpus_total) {
        my $ngrams_freq->[1] = $corpus_total->{$token};
        for my $id (keys $corpus_parts) {
            $ngrams_freq->[0] = $corpus_parts->{$id}->{$token};
            $corpus_data->{id}->{$id}->{corpus}->{statistic}
                    = $statistic->compare($ngrams_freq, $min_freq);
        }
    }
    return $corpus_data;
}

sub collocation_corpus ($$$) {
    my $self        =   shift;
    my $corpus_data =   shift;
    my $ngram       =   shift;

    my $counter = Textmining::Plugin::StructureHelper::Corpus::Count->new;
    my $stat = Textmining::Plugin::StructureHelper::Corpus::Statistic->new;
    my $corpus_parts;
    for my $id (keys $corpus_data->{id}) {
        my @corpus_ws = @{$corpus_data->{id}->{$id}->{corpus}->{windowsize}};
        shift @corpus_ws; shift @corpus_ws; # remove the first two indizes
        #return \@corpus_w;
        for my $index (0..$#corpus_ws) {
            for my $token (keys $corpus_ws[$index]) {
                my $sort_ngram_freq =
                        $counter->sort_ngram_freq(
                            $ngram,
                            $corpus_ws[$index]->{$token});

                my $stats = {chi2 => {}, llr => {}};
                $stats->{$_} = $stat->collocation($_, $sort_ngram_freq)->{$_}
                    foreach (qw(chi2 llr));
                $corpus_data->{id}->{$id}->{corpus}->{statistic} = $stats;
            }
        }
    }
    return $corpus_data;
}

sub get_corpus ($$$$) {
    my $self    =   shift;
    my $dir     =   shift;
    my $files   =   shift;
    my $filter  =   shift || undef;
    my $type    =   shift; # indirect a ngram value

    my @corpus_docs =    $self->get_corpus_docs($dir, $files);
    my $hash;
    my @file_list = (sort values $files);

    foreach my $doc (values @corpus_docs) {
        my $file = shift @file_list;
        $file = fileparse($file);
        my $suffix = $1 if ($file =~ qr/\.([^\.]+)$/);

        #extract_corpus from document
        my $corpus;
        if  ($suffix =~ /vrt/) {
            $corpus = $self->extract_corpus($doc, '//text/body' );
        }
        #get meta structure (filled) from doc
        my $m_s = $self->get_metastruct($doc, '//text');
        $m_s->{fpath} = $suffix;

        my @counts = $self->count_corpus($corpus, $suffix, $type);
        $m_s->{corpus}->{windowsize} = \@counts;
        $m_s->{corpus}->{token} = $counts[0];
        $hash->{id}->{$m_s->{id}} = $m_s;

        my $statistic = Textmining::Plugin::StructureHelper::Corpus::Statistic->new;
        if ($type == $self->keywords) {
            if (defined $filter) {
                $hash->{$_}->{$m_s->{$_}}->{$m_s->{id}} = $m_s->{corpus}->{token}
                foreach (values $filter);
            }
        }
    }
    ####################################
    # {}- idvalue - ...
    #   \
    #     $filter - {$filter}value - idvalue - \ref on idvalue->corpus
    ####################################
    #unterscheiden welche statistictool zu versenden ist durch den type 
    #mit den Modulattributen

    return $hash;
}

1;
