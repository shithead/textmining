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
        corpus  => "",
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
        $hash->{$_} = $node->getAttribute($_) foreach (keys $hash);
    }
    return $hash;
}

sub get_corpus_docs($$$) {
    my $self    =   shift;
    my $dir     =   shift;
    my $files   =   shift;
    my @docs;

    for my $file (sort keys $files) {
        my $path = join('/', $dir, $file);
        my $doc =   $self->{transform}->get_doc($path);
        push @docs, $doc;
    }
    return wantarray ? @docs : \@docs;
}

sub count_corpus ($$$$) {
    my $self        = shift;
    my $corpus      = shift;
    my $token_type  = shift;
    my $ngram       = shift || scalar '2';

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
    my @windows = (1);
    @windows = qw(2 3 4 5 6 7 8 9 10) if ($ngram > 1);
    for my $window_size (values @windows) {
        my $permu = $count->get_permu( $window_size - 1,
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
                ) } foreach ( values $words->{$key});
            $count->clearup();
            $count->calc_freq_combo($ngram);

            $ngrams_freq[$window_size] = $ngram_freq;
        }
    }
    return wantarray ? @ngrams_freq : \@ngrams_freq;
}

sub get_corpus ($$$$) {
    my $self    =   shift;
    my $dir     =   shift;
    my $files   =   shift;
    my $filter  =   shift;
    my $type    =   shift; # indirect a ngram value

    my @corpus_docs =    $self->get_corpus_docs($dir, $files);
    my $hash;
    my @file_list = (sort keys $files);
    foreach my $doc (values @corpus_docs) {
        my $file = shift @file_list;
        $file = fileparse($file);
        my $suffix = $1 if ($file =~ qr/\.([^\.]+)$/); 

        #extract_corpus from document
        my $corpus;
        if  ($suffix =~ /vrt/) {
            $corpus = $self->extract_corpus($doc, '/text/body' );
        }
        #get meta structure (filled) from doc
        my $m_s = $self->get_metastruct($doc, '/text');
        $m_s->{fpath} = $suffix;

        my @counts = $self->count_corpus($corpus, $suffix, $type);
        $m_s->{corpus} = \@counts;
        $hash->{id}->{$m_s->{id}} = $m_s;
        $hash->{$_}->{$m_s->{$_}}->{$m_s->{id}} = $m_s->{corpus}
                foreach (values $filter);
        
    }
    ####################################
    # {}- idvalue - ...
    #   \
    #     $filter - {$filter}value - idvalue - \ref on idvalue->corpus
    ####################################
    return $hash;
}

1;
