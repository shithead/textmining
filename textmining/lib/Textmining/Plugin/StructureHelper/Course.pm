#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Course;
# ABSTRACT: Course library

=head1 SYNOPSIS

...

=method get_node_metastruct()

This method return metastructure from specified node meta-tag.

=method get_course_struct()

This method return metastructure from xml-file.
Is using L<"get_doc">, L<"get_node_metastruct">, L<"get_modul_struct">

=method get_modul_struct()

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
sub get_course_struct ($$$) {
    my $self            = shift;
    my $modul_dir       = shift;
    my $modul_files     = shift;

    my $modul_path      = join '/', $modul_dir, @{$modul_files}[0];

    my $modul_doc       = Textmining::Plugin::StructureHelper::Transform->get_doc($modul_path);
    my $course_struct   = $self->get_node_metastruct($modul_doc, '/course');
    $course_struct->{type} = 'course';

    undef $modul_path;
    # modul nodes
    for (values @{$modul_files}) {
        $modul_path         = join '/', $modul_dir, $_;
        my $modul_struct    = $self->get_modul_struct($modul_doc);
        push @{$course_struct->{sub}}, $modul_struct;
    }
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
