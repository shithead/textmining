#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Course;
# ABSTRACT: Course library

=head1 SYNOPSIS

...

=method get_node_metastruct()

This method return metastructure from specified node meta-tag.

=method get_course_struct()

This method return metastructure from xml-file.
Is using L<"get_doc">, L<"get_node_metastruct">, L<"get_module_struct">

=method get_module_struct()

This method return metastructure from module-tag.
Is using L<"get_node_metastruct">.

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Course>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use XML::LibXML;

sub init {
    my ($self, $app)  = @_;
    $self->{log} = $app->log;
    #$self->log->debug('call new Textmining::Plugin::StructureHelper::Course');
    return $self;
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
            my $content = $_->textContent;
            next if ($content =~ m/^\.xml$/);
            $content =~ s/\.xml$/.html/;
            push @{$hash->{meta}->{libraries}}, $content;
        }
        for ($meta->findnodes('corpora/corpus')) {
            my $text = $_->textContent;
            $text =~ qr/([\w+\.?]+)/;
            $text = $1;
            $hash->{meta}->{corpora}->{$_->getAttribute("id")} = {
                parts   => $_->getAttribute("parts"),
                src     => $text, 
                type    => $_->getAttribute("type")
            };
        }
    }
    return $hash;
}

sub get_course_struct ($$$) {
    my $self        = shift;
    my $module_path = shift;

    my $module_doc       = Textmining::Plugin::StructureHelper::Transform->get_doc($module_path);
    my $course_struct   = $self->get_node_metastruct($module_doc, '/course');
    $course_struct->{type} = 'course';

    return $course_struct;
}

sub get_module_struct ($$) {
    my $self    = shift;
    my $module_path = shift;

    my $doc = Textmining::Plugin::StructureHelper::Transform->get_doc($module_path);
    # modul nodes
    my $module_struct;
    for my $modul ($doc->findnodes('/course/module')) {
        $module_struct =  $self->get_node_metastruct($doc, '/course/module');
        $module_struct->{type} = 'module';

        # chapter nodes
        for my $chapter ($modul->findnodes('chapter')) {
            my $chapter_struct = {
                id          => $chapter->getAttribute('id'),
                head        => "",
                type        => "",
                pagecnt     => 0,
                type        => $chapter->getAttribute('type')
            };

            # page nodes
            my $pagecnt = 0;
            for my $page ($chapter->findnodes('page')) {
                $chapter_struct->{head} = $page->findvalue('h1')
                        if ($page->exists('h1')) ;
                $pagecnt++;
            }
            $chapter_struct->{pagecnt} = $pagecnt;
            push @{$module_struct->{sub}}, $chapter_struct;
        }
    }
    return $module_struct;
}

1;
