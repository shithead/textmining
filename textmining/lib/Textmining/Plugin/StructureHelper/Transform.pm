#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Transform;
# ABSTRACT: a really awesome library

=head1 SYNOPSIS

...

=method get_xml()

This method open xmlfile and return xml-structure.

=method get_xsl()

This method open xslfile and return xsl-style.

=method xmltohash()

This method transform xml to perlhash (for dynamic html).

=method xmltohtml()

This method transform xml to html (for static html).

=head1 SEE ALSO

=for :list
* L<Your::Module>
* L<Your::Package>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json);
use XML::LibXML;
use XML::LibXSLT;
use XML::Hash::LX ':inject';
use XML::Parser;

use Data::Printer;

$XML::LibXML::skipXMLDeclaration = 1;

sub Callback { print "$_\n"};
sub new {
    my $class = shift;

    my $self  = {};
    bless $self, $class;
    my $xslt        = XML::LibXSLT->new();
    $xslt->debug_callback( \&Callback );
    my $xsl     = $self->get_xsl('templates/res/page.xsl');
    my $stylesheet  = $xslt->parse_stylesheet($xsl);
    $self->{xslt}=$stylesheet;
    return $self;
}

sub get_xml {
    my $self    = shift;
    my $xmlfile = shift;

    my $source  = XML::LibXML->load_xml(location => $xmlfile);
    return $source;
}

sub get_xsl {
    my $self    = shift;
    my $xslfile = shift;

    my $style;
    eval{ $style = XML::LibXML->load_xml(location => $xslfile, , no_cdata => 1); };
    return $style;

}
sub xmltohash {
    my $self    = shift;
    my $xml     = shift;

    my $doc;
    eval{ $doc = XML::LibXML->new->parse_string($xml); };
    my $hash    = $doc->toHash(order => 1);

    return $hash;
}

sub xmltohtml {
    my $self    = shift;
    my $xml     = shift;

    $xml = XML::LibXML->load_xml(string => $xml)
            unless ref $xml eq 'XML::LibXML::Document';

    my $results;
    eval { $results = $self->{xslt}->transform($xml) };

    return $results;
}

sub nodestohtml {
    my $self = shift;
    my @nodes = @_;

    my @results;
    for my $node (@nodes) {
        eval { push @results, $self->xmltohtml($node->toString)->toString};
    }
    return @results;
}

sub get_meta_struct {
    my $self = shift;
    my $node = shift;
    my $meta_xpath = shift;

    $meta_xpath = join "/", $meta_xpath , "meta";
    my $hash = {
        sub     => [],
        meta    => {
            authors => [],
            date    => "",
            title   => "",
            version => ""
        }
    };
    if ($node->exists($meta_xpath)) {
        my $meta = $node->find($meta_xpath)->get_node(1);
        $hash->{meta}->{date}      = $meta->findvalue('date');
        $hash->{meta}->{title}     = $meta->findvalue('title');
        $hash->{meta}->{version}   = $meta->findvalue('version');
        for ($meta->findnodes('authors/author')) {
            push @{$hash->{meta}->{authors}}, $_->textContent;
        }
    }
    return $hash;
}

sub xml_struct {
    my $self    = shift;
    my $modul_path = shift;

    my $xml     = $self->get_xml($modul_path);
    my $course  = $self->get_meta_struct($xml, '/course');

    # modul nodes
    #
    for my $module ($xml->findnodes('/course/module')) {
        my $modul =  $self->get_meta_struct($xml, '/course/module');

        # chapter nodes
        for my $chapter ($module->findnodes('chapter')) {
            my $attr = $chapter->getAttributeHash;
            my $chapts = {
                id          => $attr->{id},
                head        => "",
                type        => "",
                pagescnt    => 0,
                type        => $attr->{type}
            };

            # page nodes
            my $pagesnr = 0;
            for my $page ($chapter->findnodes('page')) {
                $chapts->{head} = $page->findvalue('h1') if ($page->exists('h1')) ;
                $pagesnr++;
            }
            $chapts->{pagescnt} = $pagesnr;
            push @{$modul->{sub}}, $chapts;
        }
        push @{$course->{sub}}, $modul;
    }
    return $course;
}

sub xml_pages {
    my $self    = shift;
    my $modul_path = shift;

    my $xml     = $self->get_xml($modul_path);

    my @pages;
    # page nodes
    #
    for my $page ($xml->findnodes('/course/module/capter/page')) {
        push @pages, $page;
    }
    @pages = $self->nodestohtml(@pages);
    return @pages;
}


1;
