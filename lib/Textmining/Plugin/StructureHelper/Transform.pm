#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Transform;
# ABSTRACT: a really awesome library

=head1 SYNOPSIS

...

=method get_doc()

This method open xmlfile and return xml DOM-structure.

=method get_xsl()

This method open xslfile and return xsl-style.

=method doctohtml()

This method transform xml document to html (for static html).

=method nodestohtml()

This method transform nodes to html.
Is using L<"doctohtml">.

=method xml_doc_pages()

This method transform pages to html.
Is using L<"get_doc"> and L<"nodestohtml">.

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Transform>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;
use XML::LibXSLT;

$XML::LibXML::skipXMLDeclaration = 1;

sub init {
    my ($self, $app) = (@_);

    my $home        = $app->home;
    $self->{log}    = $app->log;
    $self->{xslt}   = {};
    bless $self->{xslt}, "XML::LibXSLT::StylesheetWrapper";
    return $self;
}

sub get_doc ($$) {
    my $self    = shift;
    my $xmlfile = shift;

    my $doc  = XML::LibXML->load_xml(location => $xmlfile);
    return $doc;
}

sub get_xsl ($$) {
    my $self    = shift;
    my $xslfile = shift;

    my $style;
    eval{ $style = XML::LibXML->load_xml(location => $xslfile, , no_cdata => 1); };

    if ($self->isa( "HASH" ) ) {
        my $xslt        = XML::LibXSLT->new();
        $self->{xslt}   = $xslt->parse_stylesheet($style);
    }
    return $style;
}

sub doctohtml ($$) {
    my $self    = shift;
    my $doc     = shift;

    $doc = XML::LibXML->load_xml(string => $doc)
            unless ref $doc eq 'XML::LibXML::Document';

    my $results;
    eval { $results = $self->{xslt}->transform($doc) };

    return $results;
}

# TODO Test for nodestohtml
sub nodestohtml ($$) {
    my $self = shift;
    my $nodes = shift;

    my @results;
    for my $node (@{$nodes}) {
        my $result_html;
        eval { $result_html = $self->doctohtml($node->toString)->toString };
        push @results, $result_html;
    }
    return  wantarray ? @results : \@results;
}

#use Data::Printer;
sub update_xml_tag_img ($$$) {
    my $self    = shift;
    my $course_path = shift;
    my $page_node = shift;

    for my $img_element ($page_node->findnodes('//img')) {
       #p $img_element;
       my $src_attr    = $img_element->getAttribute('src');
       #p $src_attr;
       next unless ( $src_attr );
       next if ($src_attr =~ qr/^https?:\/\//);
       my $new_src_attr = "$course_path";
       #use Data::Printer;
       #p $new_src_attr;
       foreach (split('/', $src_attr)) {
           $new_src_attr = join('/', $new_src_attr, $_) unless ($_ =~ qr/^\.\./);
       }
       $img_element->setAttribute('src', $new_src_attr);
       #p $img_element->toString();
    }
    return $page_node;
}

sub get_library_node ($$$$) {
    my $self            = shift;
    my $module_doc      = shift;
    my $library_dir     = shift;
    my $library_files   = shift;

    my @library_content;
    push (@library_content, $_->textContent)
           foreach ($module_doc->findnodes('/course/module/meta/libraries/library'));

    my $new_libraries = XML::LibXML::Element->new( "libraries" );

    foreach (@{$library_files}) {
        $new_libraries->appendTextChild('library', join('/', $library_dir, $_) )
                if ($_ ~~ @library_content);
    }
    return $new_libraries;
}

# TODO Test for xml_doc_pages
sub xml_doc_pages ($$$$) {
    my $self            = shift;
    my $module_path     = shift;
    my $library_dir     = shift;
    my $library_files   = shift;
    my $module_doc      = $self->get_doc($module_path);

    my $new_libraries = $self->get_library_node($module_doc, $library_dir, $library_files);

    my @pages;
    for my $page ($module_doc->findnodes('/course/module/chapter/page')){
        $page->appendChild($new_libraries->cloneNode(1))
                if ($page->exists('//bib') and @{$library_files});
        push @pages, $page;
    }
    return wantarray ? @pages : \@pages;
}

1;
