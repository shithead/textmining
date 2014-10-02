#!/usr/bin/env perl

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

=cut


use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;
use File::Basename;

sub new {
    my $class = shift;

    my $self  = {};
    bless $self, $class;
    return $self;
}

sub get_body ($$$) {
    my $self    = shift;
    my $corpus_doc = shift;
    my $xpath   = shift or scalar "/"; # set another node or the current one

    my $last_node = fileparse($xpath);
    my $body = undef;
    if ($corpus_doc->exists($xpath)) {
        $body = $corpus_doc->findnodes($xpath)->get_node(1)->toString();
        chomp $body;
        $body =~ s/<$last_node>//;
        $body =~ s/<\/$last_node>//;
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
        type    => 'corpus',
        id      => "",
        author  => "",
        year    => "",
        party   => ""
    };
    if ($corpus_doc->exists($xpath)) {
        my $meta = $corpus_doc->find($xpath)->get_node(1);
        $hash->{id}         = $meta->getAttribute('id');
        $hash->{author}     = $meta->getAttribute('author');
        $hash->{party}      = $meta->getAttribute('party');
        $hash->{year}       = $meta->getAttribute('year');
    }
    return $hash;
}

;1
