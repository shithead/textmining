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

#{{{ utils
# TODO Test
sub _exists_check ($$) {
    #my $self    = shift if __PACKAGE__ eq "Textmining::Plugin::StructureHelper" ;
    my $object  = shift;
    if (-e $object) {
        return 0;
    }
    return 1;
}

sub hash_to_json ($$) {
    my $self                = shift;
    my $meta_struct         = shift;
    my $json                = Mojo::JSON->new;
    my $json_bytes          = $json->encode($meta_struct);
    my $err                 = $json->error;
    say $err ?  "Error: $err" : 
            "encode meta_struct for meta.json Successed";
    # TODO Errorlog
    return $json_bytes;
}

sub json_to_hash ($$) {
    my $self                = shift;
    my $json_bytes          = shift;
    my $json                = Mojo::JSON->new;
    my $meta_struct         = $json->decode($json_bytes);
    my $err                 = $json->error;
    say $err ?  "Error json decode: $err" : 
            "decode meta.json Successed";
    # TODO Errorlog
    return $meta_struct;
}

#}}}

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
sub init_public_course ($$) {
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

    # {{ TODO build a stack of 
    # create_public_modul 
    # -> create_chapter_modul 
    # -> create_public_pages
    # update every sub modul with $page_meta_list see bootom of fnct
    my @chapter_dirs    = $self->create_public_chapter(
                $course,
                $course_meta_struct
            );

    my @pages;

    # TODO filter right library file for modul
    for my $filename (@{$path->{modul}->{files}}) {
        push (@pages, $self->{transform}->xml_pages(
            join('/', $path->{modul}->{path}, $filename),
            join('/', $path->{library}->{path}, $path->{library}->{files}->[0])

        ));
    }
    # create_public_pages ($path, @pages, @chapter_dirs)
    my $prev_page = undef;
    my @page_meta_list;
    for my $chapter (@chapter_dirs){
        for my $pagenr (1..$chapter->{pagecnt}) {
            my $page    = join('/', $self->{_path}->{course}, $chapter->{dir},
                    "$pagenr.html");
            open my $FD, ">:encoding(UTF-8)", $page;
            print $FD shift @pages;
            close $FD;
            push @page_meta_list, $page;
        }
    }
    #p @page_meta_list;
    $course_meta_struct->{sub}->[0]->{sub} = \@page_meta_list;

    my $course_meta_path    = join('/', $path->{dest}, "meta.json" );
    $self->save_public_struct ($course_meta_path, $course_meta_struct);

    # }}
    $self->update_public_struct;
}

sub create_public_chapter ($$$) {
    my $self    = shift;
    my ($course, $course_meta_struct) = @_;
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
    return @chapter_dirs;
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
        unless ($name =~ m/(^\.+)|(.*\.json$)/)  {
            # build course tree
            $hash->{$name} = [];
            # get content of public/course/name directory
            opendir(DIR, join ('/', $course_dir, $name));
            my @moduls = readdir(DIR);
            closedir(DIR);

            for my $modul (values @moduls) {
                # ignore .+
                unless ($modul =~ m/(^\.+)|(.*\.json$)/)  {
                    # build modul tree
                    push @{$hash->{$name}}, $modul;
                };
            };
        };
    };

    $self->{_public_struct} = $hash;
    my $meta_path    = join('/', $self->{_path}->{course}, "meta.json" );
    $self->save_public_struct($meta_path, $hash);
}

# TODO Test
# TODO $dir should be undefbut not.
sub get_public_struct ($$) {
    my $self    = shift;
    my $dir     = shift or undef;

    my $meta_path;
    if (defined $dir) {
        $meta_path    = join('/', $self->{_path}->{course}, $dir,"meta.json" );
    } else {
        $meta_path    = join('/', $self->{_path}->{course}, "meta.json" );
    }

    my $meta_struct  = $self->load_public_struct($meta_path);
    p $meta_struct;
    return $meta_struct ? $meta_struct : $self->{_public_struct};
}

# TODO Test
sub get_public_modul ($) {
    my $self = shift;

    my $hash_list;
    foreach (keys $self->{_public_struct}) {
        @{$hash_list->{$_}} = @{$self->{_public_struct}->{$_}};
    }

    return $hash_list;
}

sub save_public_struct ($$$) {
    my $self = shift;
    my ($location, $meta_struct) = @_;
    my $file                = Mojo::Asset::File->new;
    my $json_bytes          = $self->hash_to_json($meta_struct);
    # TODO errorlog default maxsize 128KB for a chunk
    $file->add_chunk($json_bytes);
    $file->move_to($location);
}

sub load_public_struct ($$) {
    my $self        = shift;
    my $location    = shift;
    my $file        = Mojo::Asset::File->new( path => $location);
    # TODO Charset problem
    my $meta_struct = $self->json_to_hash($file->get_chunk(0));
    return $meta_struct;
}

# }}}

1;
