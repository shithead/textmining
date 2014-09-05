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

=method get_node_metastruct()

This method return metastructure from specified node meta-tag.

=method get_meta_struct()

This method return metastructure from xml-file.
Is using L<"get_doc">, L<"get_course_struct">, L<"get_modul_struct">

=method get_course_struct()

This method return metastructure from course-tag.
Is using L<"get_node_metastruct">.

=method get_modul_struct()

This method return metastructure from module-tag.
Is using L<"get_node_metastruct">.

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Transform>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;
use XML::LibXSLT;

$XML::LibXML::skipXMLDeclaration = 1;

# TODO test
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

# TODO test
sub get_doc ($$) {
    my $self    = shift;
    my $xmlfile = shift;

    my $source  = XML::LibXML->load_xml(location => $xmlfile);
    return $source;
}

# TODO test
sub get_xsl ($$) {
    my $self    = shift;
    my $xslfile = shift;

    my $style;
    eval{ $style = XML::LibXML->load_xml(location => $xslfile, , no_cdata => 1); };
    return $style;

}

# TODO test
sub doctohtml ($$) {
    my $self    = shift;
    my $doc     = shift;

    $doc = XML::LibXML->load_xml(string => $doc)
            unless ref $doc eq 'XML::LibXML::Document';

    my $results;
    eval { $results = $self->{xslt}->transform($doc) };

    return $results;
}

# TODO test
sub nodestohtml ($@) {
    my $self = shift;
    my @nodes = @_;

    my @results;
    for my $node (@nodes) {
        my $result_html = $self->doctohtml($node->toString)->toString;
        push @results, $result_html;
    }
    return  wantarray ? @results : \@results;
}

# TODO test
sub xml_doc_pages ($$$@) {
    my $self            = shift;
    my $modul_path      = shift;
    my $library_path    = shift;
    my @library_files   = @_;
    my $modul_doc       = $self->get_doc($modul_path);

    # sub get_library_node ($self, $modul_doc, $library_path, @library_files)
    my @library_content;
    push (@library_content, $_->textContent)
           foreach ($modul_doc->findnodes('/course/module/meta/libraries/library'));

    my $new_libraries = XML::LibXML::Element->new( "libraries" );

    for (@library_files) {
        $new_libraries->appendTextChild('library', join('/', $library_path, $_) ) 
                if ($_ ~~ @library_content);
    }
    # return $new_libraries;

    my @pages;
    for my $page ($modul_doc->findnodes('/course/module/chapter/page')){
       $page->appendChild($new_libraries) if ($page->exists('//bib'));
        push @pages, $self->nodestohtml($page);
    }
    return wantarray ? @pages : \@pages;
}

# TODO test
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

# TODO test
sub get_meta_struct ($$@) {
    my $self            = shift;
    my $modul_dir       = shift;
    my @modul_files     = @_;
   
    my $modul_path      = join '/', $modul_dir, $modul_files[0];

    my $modul_doc             = $self->get_doc($modul_path);
    my $course_struct   = $self->get_course_struct($modul_doc);

    undef $modul_path;
    # modul nodes
    for (values @modul_files) {
        my $modul_path      = join '/', $modul_dir, $_;
        my $modul_struct    = $self->get_modul_struct($modul_doc);
        push @{$course_struct->{sub}}, $modul_struct;
    }
    return $course_struct;
}

# TODO test
sub get_course_struct ($$) {
    my $self    = shift;
    my $doc     = shift;

    my $course_struct  = $self->get_node_metastruct($doc, '/course');
    $course_struct->{type} = 'course';

    return $course_struct;
}

# TODO test
sub get_modul_struct ($$) {
    my $self    = shift;
    my $doc     = shift;

    # modul nodes
    my $modul_struct;
    for my $modul ($doc->findnodes('/course/module')) {
        $modul_struct =  $self->get_node_metastruct($doc, '/course/module');
        $modul_struct->{type} = 'modul';

        # chapter nodes
        for my $chapter ($modul->findnodes('chapter')) {
            my $attr = $chapter->getAttributeHash;
            my $chapter_struct = {
                id          => $attr->{id},
                head        => "",
                type        => "",
                pagecnt     => 0,
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
