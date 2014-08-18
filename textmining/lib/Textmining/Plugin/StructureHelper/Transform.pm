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

use Data::Printer;

$XML::LibXML::skipXMLDeclaration = 1;

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

sub xml_pages ($$$) {
    my $self    = shift;
    my $modul_path = shift;
    my $library_path  = shift;

    my $xml     = $self->get_xml($modul_path);

    my @pages;
    # page nodes
    #
    for my $page ($xml->findnodes('/course/module/chapter/page')) {
        push @pages, $page;
    }
    @pages = $self->nodestohtml(@pages);
    return @pages;
}

sub get_node_metastruct ($$$) {
    my $self = shift;
    my $node = shift;
    my $meta_xpath = shift;

    $meta_xpath = join "/", $meta_xpath , "meta";
    my $hash = {
        sub     => [],
        type    => '',
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
        for ($meta->findnodes('libraries/library')) {
            push @{$hash->{meta}->{libraries}}, $_->textContent;
        }
    }
    return $hash;
}

sub get_meta_struct ($$@) {
    my $self            = shift;
    my $modul_dir       = shift;
    my @modul_files     = @_;
   
    my $modul_path      = join '/', $modul_dir, $modul_files[0];

    my $xml             = $self->get_xml($modul_path);
    my $course_struct   = $self->get_course_struct($xml);

    undef $modul_path;
    # modul nodes
    for (values @modul_files) {
        my $modul_path      = join '/', $modul_dir, $_;
        my $modul_struct    = $self->get_modul_struct($xml);
        push @{$course_struct->{sub}}, $modul_struct;
    }
    return $course_struct;
}

sub get_course_struct ($$) {
    my $self    = shift;
    my $xml     = shift;

    my $course_struct  = $self->get_node_metastruct($xml, '/course');
    $course_struct->{type} = 'course';

    return $course_struct;
}

sub get_modul_struct ($$) {
    my $self    = shift;
    my $xml     = shift;

    # modul nodes
    my $modul_struct;
    for my $modul ($xml->findnodes('/course/module')) {
        $modul_struct =  $self->get_node_metastruct($xml, '/course/module');
        $modul_struct->{type} = 'modul';

        # chapter nodes
        for my $chapter ($modul->findnodes('chapter')) {
            my $attr = $chapter->getAttributeHash;
            my $chapter_struct = {
                id          => $attr->{id},
                head        => "",
                type        => "",
                pagecnt    => 0,
                type        => $attr->{type}
            };

            # page nodes
            my $pagecnt = 0;
            for my $page ($chapter->findnodes('page')) {
                $chapter_struct->{head} = $page->findvalue('h1') if ($page->exists('h1')) ;
                $pagecnt++;
            }
            $chapter_struct->{pagecnt} = $pagecnt;
            push @{$modul_struct->{sub}}, $chapter_struct;
        }
    }
    return $modul_struct;
}


1;
