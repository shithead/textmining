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
use Mojo::Asset::File;
use Mojo::JSON;

use Textmining::Plugin::StructureHelper::Transform;
use File::Path qw(remove_tree make_path);

use feature 'say';
use Data::Printer;

sub register {
  my ($self, $app) = @_;
    $self->{_data_struct} = {};
    $self->{_public_struct} = {};
    $self->{transform} = Textmining::Plugin::StructureHelper::Transform->new();
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
sub _exists_check ($$) {
    my $self    = shift;
    my $object  = shift;
    if (-e $object) {
        return 0;
    }
    return 1;
}

# {{{ data directory
# TODO Test
sub update_data_struct ($) {
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
            my @files = readdir(DIR);
            closedir(DIR);

            for my $file (values @files) {
            # ignore .+ and grep files with xml-Suffix
                if ($file =~ qr/(^[^\.]+.*\.xml$)/)  {
                    unshift @{$hash->{$course}->{$_}}, $file;
                }
            }
        }
    }
    $self->{_data_struct} = $hash;
}

# TODO Test
sub get_data_struct ($) {
    my $self = shift;
    return $self->{_data_struct};
}

# TODO Test
sub get_data_course ($) {
    my $self = shift;

    my @course_list;
    foreach (keys $self->{_data_struct}) {
        push @course_list, $_;
    }

    return @course_list;
}

sub get_data_modul ($$) {
    my $self = shift;
    my $course = shift;

    unless (keys $self->{_data_struct}) {
        $self->update_data_struct();
        # TODO test of $course exist in _data_struct
    }

    my @courses_keys = (keys $self->{_data_struct});
    unless (  $course ~~ @courses_keys ) {
        #TODO Errorlog
        say "course $course not in \'@courses_keys\'";
        return undef;
    }

    my $modules = {
        path    => join('/', $self->{_path}->{data}, $course, 'modul'),
        files   => \@{$self->{_data_struct}->{$course}->{modul}}
    };

    return $modules;
}

sub get_data_library ($$) {
    my $self = shift;
    my $course = shift;

    unless (keys $self->{_data_struct}) {
        $self->update_data_struct();
        # TODO test of $course exist in _data_struct
    }

    my @courses_keys = (keys $self->{_data_struct});
    unless (  $course ~~ @courses_keys ) {
        #TODO Errorlog
        say "course $course not in \'@courses_keys\'";
        return undef;
    }

    my $libraries = {
        path    => join('/', $self->{_path}->{data}, $course, 'library'),
        files   => \@{$self->{_data_struct}->{$course}->{library} }
    };

    return $libraries;
}

# }}}

# {{{ public directory

# TODO Test
sub init_pubilc_course ($$) {
    my ($self, $course) = @_;

    my $path = {
        src     => join('/', $self->{_path}->{data}    , $course),
        dest    => join('/', $self->{_path}->{course}  , $course),
        modul   => $self->get_data_modul($course),
        library => $self->get_data_library($course)
    };
    my $course_meta_struct;
    $course_meta_struct = $self->{transform}->get_meta_struct(
        $path->{modul}->{path},
        @{$path->{modul}->{files}}
    );


    unless (&_exists_check($path->{dest})) {
        $self->rm_public_path($course);
    }
    if (&_exists_check($path->{dest})) {
        $self->create_public_path($course);
    }

    # XXX hash_to_json ($course_meta_struct)
    my $json                = Mojo::JSON->new;
    my $json_bytes          = $json->encode($course_meta_struct);
    # XXX perheps backuping $course_meta_struct
    undef $course_meta_struct;
    my $err;
    $err                    = $json->error;
    say $err ?  "Error: $err" : 
            "encode course_meta_struct for meta.json Successed";
    # TODO Errorlog
    # return $json_bytes


    my $course_meta_path    = join('/', $path->{dest}, "meta.json" );
    # XXX save_public_meta_struct ($course, $course_meta_struct)
    my $file                = Mojo::Asset::File->new;
    # TODO errorlog default maxsize 128KB for a chunk
    $file->add_chunk($json_bytes);
    undef $json_bytes;
    $file->move_to($course_meta_path);

    # XXX load_public_meta_struct ($course)
    $file                   = $file->path($course_meta_path);
    # TODO Charset problem
    $course_meta_struct     = $json->decode($file->get_chunk(0));
    $err                    = $json->error;
    say $err ?  "Error: $err" : "decode meta.json Successed";
    # return $course_meta_struct

    # XXX create_public_chapter ($course, $course_meta_struct)
    # directory is clear change *_dir so that $course variable no more required
    my @chapter_dirs;
    for my $modulcnt (0 .. $#{$course_meta_struct->{sub}}) {
        my $modul_dir = join('/',
            $course,
            $course_meta_struct->{sub}->[$modulcnt]->{meta}->{title}
        );
        for my $chaptcnt (0 .. $#{$course_meta_struct->{sub}->[$modulcnt]->{sub}}) {
            my $chapter_dir = join('/',
                $modul_dir,
                $chaptcnt . "_" .
                $course_meta_struct->{sub}->[$modulcnt]->{sub}->[$chaptcnt]->{id}
            );
            $self->create_public_path($chapter_dir);
            my $tmp = {
                dir     => $chapter_dir,
                pagecnt => $course_meta_struct->{sub}->[$modulcnt]->{sub}
                    ->[$chaptcnt]->{pagecnt}
                };
            push @chapter_dirs, $tmp;
        }
    }
    # return @chapter_dirs;

    my @pages;

    # TODO filter right library file for modul
    for my $filename (@{$path->{modul}->{files}}) {
        push (@pages, $self->{transform}->xml_pages(
            join('/', $path->{modul}->{path}, $filename),
            join('/', $path->{library}->{path}, $path->{library}->{files}->[0])

        ));
    }
    for my $chapter (@chapter_dirs){
        for my $pagenr (1..$chapter->{pagecnt}) {
            my $page    = join('/', $self->{_path}->{course}, $chapter->{dir},
                    "$pagenr.html");
            open my $FD, ">:encoding(UTF-8)", $page;
            print $FD shift @pages;
            close $FD;
        }
    }
}

# TODO Test
sub rm_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->{_path}->{course}, $suffix);
    remove_tree($dir, {error => \my $err});

    # TODO Errorlog
    say $err ? "Error: remove_tree $err" : "remove_tree Successed";
}

# TODO Test
sub create_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->{_path}->{course}, $suffix);
    make_path($dir, {error => \my $err});

    # TODO Errorlog
    say $err ? "Error: make_path $err" : "make_path Successed";
}

# TODO Test
sub update_public_struct ($) {
    my $self = shift;
    # XXX config sinvoll
    my $course_dir = $self->{_path}->{course};

    # get content of public/course directory
    opendir(DIR, $course_dir);
    my @course = readdir(DIR);
    closedir(DIR);

    my $hash = {} ;

    # work with content of public/course directory
    for my $name (values @course) {
        # ignore . and ..
        unless ($name =~ m/(^\.+)/)  {
            # build course tree
            $hash->{$name} = {};
        };
        # get content of public/course/name directory
        opendir(DIR, join ('/', $course_dir, $name));
        my @moduls = readdir(DIR);
        closedir(DIR);

        for my $modul (values @moduls) {
            # ignore .+ and grep files with xml-Suffix
            if ($modul =~ qr/(^[^\.]+.*\.xml$)/)  {
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
sub get_public_struct ($) {
    my $self = shift;
    return $self->{_public_struct};
}

# TODO Test
sub get_public_module ($) {
    my $self = shift;

    my $hash_list;
    foreach (keys $self->{_public_struct}) {
        @{$hash_list->{$_}} = @{$self->{_public_struct}->{$_}};
    }

    return $hash_list;
}

# }}}

1;
