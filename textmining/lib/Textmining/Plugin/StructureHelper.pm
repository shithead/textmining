#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper;
# ABSTRACT: a really awesome library

=head1 SYNOPSIS

...

=method get_data_struct()

This method

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Transform>
* L<Textmining::Plugin::StructureHelper>

=cut

use Mojo::Base qw(Mojolicious::Plugin);
use Mojolicious::Command;

use File::Path qw(remove_tree make_path);

use Data::Printer;

sub register {
  my ($self, $app) = @_;
    $self->{_data_struct} = {};
    $self->{_public_struct} = {};
    # XXX config sinvoll
    $self->{_path} = {
        data => 'data',
        course => 'public/course'
    };
    $app->helper(struct => sub {
            state $struct = $self
        });
}

# TODO Test
sub get_data_struct {
    my $self = shift;
    return $self->{_data_struct};
}

# TODO Test
sub get_public_struct {
    my $self = shift;
    return $self->{_public_struct};
}

# TODO Test
sub _exists_check {
    my $self    = shift;
    my $object  = shift;
    if (-e $object) {
        return 0;
    }
    return 1;
}

# TODO Test
sub init_course_dir {
    my ($self, $course) = @_;

#    mkdir($course) or return 1 if (&_exists_check($course));
#
#    my $moduldir = join('/',$course, $modul);
#    mkdir($moduldir) or return 1 if (&_exists_check($moduldir));

    #foreach my $chapt (values @chapter) {
    #    my $chaptdir = join('/',$moduldir, $chapt);
    #    mkdir($chaptdir) or return 1 if (&_exists_check($chaptdir));
    #}
    return 0;
}

# TODO Test
sub rm_course_tree {
    my $self = shift;
    my $course = shift;
    remove_tree($course, {error => \my $err})
}

# TODO Test
sub update_data_struct {
    my $self = shift;
    my $data = $self->{_path}->{data};
    my @coursestruct = qw(modul library);

    # content of data directory
    opendir(DIR, $data);
    my @file = readdir(DIR);
    closedir(DIR);

    my $hash = {} ;
    for my $course (values @file) {
        # ignore . and ..
        unless ($course =~ m/(^\.+)/) {
            # build course tree
            $hash->{$course} = {};
            for (values @coursestruct) {
                $hash->{$course}->{$_} = [];
            }
        };
    };

    for my $course (keys $hash) {
        for (values @coursestruct) {
            opendir(DIR, join('/', $data, $course, $_));
            my @file = readdir(DIR);
            closedir(DIR);
            for my $xml (values @file) {
            # ignore .+ and non xml-Suffix
                unless ($xml =~ m/(^\.+|[^xml]$)/)  {
                    unshift @{$hash->{$course}->{$_}}, $xml;
                }
            }
        }
    }
    $self->{_data_struct} = $hash;
}

# TODO Test
sub update_public_struct {
    my $self = shift;
    # XXX config sinvoll
    my $course_dir = $self->{_path}->{course};

    # content of public/course directory
    opendir(DIR, $course_dir);
    my @course = readdir(DIR);
    closedir(DIR);

    my $hash = {} ;

    # content of public/course directory
    for my $name (values @course) {
        # ignore . and ..
        unless ($name =~ m/(^\.+)/)  {
            # build course tree
            $hash->{$name} = {};
        };
        # content of public/course/name directory
        opendir(DIR, join ('/', $course_dir, $name));
        my @moduls = readdir(DIR);
        closedir(DIR);

        for my $modul (values @moduls) {
            # ignore .+ and non xml-Suffix
            unless ($modul =~ m/(^\.+||[^xml]$)/)  {
                # build modul tree
                $hash->{$name}->{$modul} = {};
            };
            # content of public/course/name/modul directory
            opendir(DIR, join ('/', $course_dir, $name, $modul));
            my @chapters = readdir(DIR);
            closedir(DIR);

            for my $chapter (values @chapters) {
                # ignore . and ..
                unless ($chapter =~ m/(^\.+)/)  {
                    opendir(DIR, join ('/', $course_dir, $name, $modul, $chapter));
                    # content of public/course/name/modul/chapter directory
                    @{$hash->{$name}->{$modul}->{$chapter}} = readdir(DIR);
                    closedir(DIR);
                };
            };
        };
    };

    $self->{_public_struct} = $hash;
}

# TODO Test
sub get_courses_data {
    my $self = shift;

    my @course_list;
    foreach (keys $self->{_data_struct}) {
        push @course_list, $_;
    }
    return @course_list;
}

sub get_modules_data {
    my $self = shift;
    my $course = shift;
    use Data::Printer;
    my $modules = {
        path    => join('/', $self->{_path}->{data}, $course, 'modul'),
        files   => \@{$self->{_data_struct}->{$course}->{modul}}
    };
    return $modules;
}

sub get_libraries_data {
    my $self = shift;
    my $course = shift;
    use Data::Printer;
    my $libraries = { files => @{$self->{_data_struct}->{$course}->{libary} } };
    return $libraries;
}

# TODO Test
sub get_courses_modules_public {
    my $self = shift;

    my $hash_list;
    foreach (keys $self->{_public_struct}) {
        @{$hash_list->{$_}} = @{$self->{_public_struct}->{$_}};
    }
    return $hash_list;
}

1;
