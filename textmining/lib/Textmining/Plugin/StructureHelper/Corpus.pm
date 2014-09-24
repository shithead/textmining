#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Corpus;
# ABSTRACT: a really awesome library

=head1 SYNOPSIS

...

=method get_body()

This method

=method get_metastruct()

This method

=method get_word_freq()

This method

=method split_vrt()

This method

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Corpus>
* L<Textmining::Plugin::StructureHelper::Transform>

=cut


use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;
use Text::NSP;
#use Textmining::Plugin::StructureHelper::Transform;

# TODO test
sub new {
    my $class = shift;

    my $self  = {};
    bless $self, $class;
    $self->{transform} = Textmining::Plugin::StructureHelper::Transform->new();
    return $self;
}

# TODO Test
sub get_body ($$$) {
    my $self    = shift;
    my $corpus_doc = shift;
    my $xpath   = shift or scalar "."; # set another node or the current one

    my $body = undef;
    if ($corpus_doc->exists($xpath)) {
        $body = $corpus_doc->findnodes($xpath)->get_node(1)->to_String();
    }
    return $body;
}

# TODO Test
sub get_metastruct ($$$) {
    my $self    = shift;
    my $corpus_doc  = shift;
    my $xpath   = shift or scalar "."; # set another node or the current one

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

#TODO test
sub split_vrt($$) {
    my $self    = shift;
    my $corpus  = shift;

    my @corpus = split " ", $corpus;

    my @content;
    while (@corpus) {
        my ($one, $two, $three) = shift @corpus;
        $content[0] .= " $one"; 
        $content[1] .= " $two"; 
        $content[2] .= " $three"; 
    } 
    return wantarray ? @content : \@content;
}

;1
