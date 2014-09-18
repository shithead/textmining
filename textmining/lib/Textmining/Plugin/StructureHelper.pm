#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper;
# ABSTRACT: a really awesome library

=head1 SYNOPSIS

=method _exists_check()

This method check the exist of a file.
Returned 1 if a file is not exists.

=method _tree()

This method build a directory tree in a hash.
A leaf value end with undef.

=method hash_to_json()

This method return C<Mojo::JSON> from a perl hash.

=method json_to_hash()

This method return a perl hash from a C<Mojo::JSON>.

=method update_data_struct()

This method update the structure of the 'data' directory.

=method get_data_struct()

This method return the structure of the 'data' directory.

=method get_data_course()

This method return the structure of the specified course.

=method get_data_modul()

This method return the moduls files and directory
in a structure of the specified course.
Is using L<"update_data_struct">.

=method get_data_library()

This method returned the libraries files and directory
in a structure of the specified course.
Is using L<"update_data_struct">.

=method init_public_course()

This method initialing the public directory of the specified course
with the informations from the modul by 
L<Textmining::StructureHelper::Transform/"get_meta_struct">.

Is using L<Textmining::StructureHelper::Transform/"xml_doc_pages">,
L<"rm_public_path">, L<"create_public_path">,
L<"create_public_chapter">, L<"save_public_struct"> , L<"update_public_struct">.

=method create_public_chapter()

This method initialing the public chapter directories of the specified course.
Is using L<"create_public_path">.

=method rm_public_path()

This method remove the public directory of the specified course.

=method create_public_path()

This method create path of the specified directory in 'public/course' directory.

=method get_public_modul()

This method return all module informaitions from a course hash.

=method get_public_struct()

This method return a meta struct in the specified 'public/course' directory.
Is using L<"load_public_struct">.

=method update_public_struct()

This method return the structure of the specified 'public/course' directory.
Is using L<"save_public_struct">.

=method save_public_struct()

This method save the specified meta struct in path.
Is using L<"hash_to_json">.

=method load_public_struct()

This method load the specified meta struct in path.
Is using L<"json_to_hash">.

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Transform>
* L<Textmining::Plugin::StructureHelper>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Asset::File;
use Mojo::JSON;
use Mojo::Util qw(encode decode camelize);

use Textmining::Plugin::StructureHelper::Transform;
use File::Path qw(remove_tree make_path);
use File::Basename;

use feature 'say';

sub register {
  my ($self, $app) = @_;
    $app->helper(struct => sub {
            state $struct = $self->_constructor;
        });
}

sub _constructor {
    my $self = shift;
    $self->{_data_struct} = {};
    $self->{_public_struct} = {};
    $self->{transform} = Textmining::Plugin::StructureHelper::Transform->new();
    # XXX config sinvoll
    $self->{_path} = {
        data => 'data',
        public => 'public/course'
    };
    return $self
}

sub new {
    my $class = shift;

    my $self  = {};
    bless $self, $class;
    $self->_constructor;
    return $self;
}

#{{{ utils

sub _exists_check ($$) {
    #my $self    = shift if __PACKAGE__ eq "Textmining::Plugin::StructureHelper" ;
    my $object  = shift;
    if (-e $object) {
        return 0;
    }
    return 1;
}

sub _tree ($$) {
    my $cwd = shift || '.';
    my $max_deep = shift || scalar 5;

    return undef if ($max_deep <= 0 || not defined $cwd);
    my $hash = {};
    unless ( -d $cwd ) {
        $hash = undef;
    } else {
        opendir(DIR, $cwd);
        my @files = readdir(DIR);
        closedir(DIR);

        for my $file (values @files) {
            # ignore . and ..
            unless ($file =~ m/(^\.+)/) {
                # build course tree
                my $nxt_wd = join '/', $cwd, $file;
                $hash->{$file} = &_tree($nxt_wd, $max_deep--);
            }
        }
    }
    return $hash;
}

sub hash_to_json ($$) {
    my $self                = shift;
    my $meta_struct         = shift;
    my $json                = Mojo::JSON->new;
    my $json_bytes          = decode('UTF-8', $json->encode($meta_struct));
    my $err                 = $json->error;
    if (defined $err) {
        say "Error json encode: $err";
        # TODO Errorlog
    }
    return $json_bytes;
}

sub json_to_hash ($$) {
    my $self                = shift;
    my $json_bytes          = shift;
    my $json                = Mojo::JSON->new;
    my $meta_struct         = $json->decode($json_bytes);
    my $err                 = $json->error;
    if (defined $err) {
        say "Error json decode: $err";
        # TODO Errorlog
    }
    return $meta_struct;
}

#}}}

# {{{ data directory
sub update_data_struct ($) {
    my $self = shift;
    my $data = $self->{_path}->{data};
    my @coursestruct = qw(modul library corpus);

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
        }
    }

    for my $course (keys $hash) {
        for (values @coursestruct) {
            my $cwd = join('/', $data, $course, $_);
            if ( $_ =~ 'corpus') {
                $hash->{$course}->{$_} = &_tree($cwd, 10);
            } else {
                opendir(DIR, $cwd);
                my @files = readdir(DIR);
                closedir(DIR);

                for my $file (values @files) {
                    # ignore .+ and grep files with xml-Suffix
                    if ($file =~ qr/(^[^\.]+.*\.xml$)/ ) {
                        unshift @{$hash->{$course}->{$_}}, $file;
                    }
                }
            }
        }
    }
    $self->{_data_struct} = $hash;
}

sub get_data_struct ($) {
    my $self = shift;
    return $self->{_data_struct};
}

sub get_data_course ($) {
    my $self = shift;

    my @course_list;
    foreach (keys $self->{_data_struct}) {
        push @course_list, $_;
    }

    return wantarray ? @course_list : \@course_list;
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
        say "course $course not in \'" . join(',', @courses_keys) . "\'";
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

sub get_data_corpus ($$) {
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

    my $corpora = {
        path    => join('/', $self->{_path}->{data}, $course, 'corpus'),
        files   => $self->{_data_struct}->{$course}->{corpus}
    };

    return $corpora;
}
# }}}

# {{{ public directory

# TODO Test for init_public_course($self, $course)
sub init_public_course ($$) {
    my ($self, $course) = @_;

    my $path = {
        src     => join('/', $self->{_path}->{data}  , $course),
        dest    => join('/', $self->{_path}->{public}, $course),
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
    # -> create_modul_chapter
    # -> create_chapter_pages
    # update every sub modul with $page_meta_list see bottom of fnct
    my @chapter_dirs    = $self->create_public_chapter(
                $course,
                $course_meta_struct
            );

    my @pages;
    for my $filename (@{$path->{modul}->{files}}) {
        push (@pages, $self->{transform}->xml_doc_pages(
                join('/', $path->{modul}->{path}, $filename),
                $path->{library}->{path}, @{$path->{library}->{files}}
                ));
    }

    # sub create_chapter_pages ($path, @pages, @chapter_dirs)
    # {
    my $prev_page = undef;
    my @page_meta_list;
    for my $chapter (@chapter_dirs){
        for my $pagenr (1..$chapter->{pagecnt}) {
            my $page    = join('/', $self->{_path}->{public}, $chapter->{dir},
                    "$pagenr.html");
            open my $FD, ">:encoding(UTF-8)", $page;
            print $FD shift @pages;
            close $FD;
            push @page_meta_list, $page;
        }
    }
    # return wantarray ? @page_meta_list : \@page_meta_list;
    # }
    $course_meta_struct->{sub}->[0]->{pages} = \@page_meta_list;

    my $course_meta_path    = join('/', $path->{dest}, "meta.json" );
    $self->save_public_struct($course_meta_path, $course_meta_struct);

    # }}
    $self->update_public_struct;
}

# TODO Test for create_public_chapter($self, $course, $course_meta_struct)
sub create_public_chapter ($$$) {
    my $self    = shift;
    my ($course, $course_meta_struct) = @_;

    # TODO directory is knowing, change *_dir so
    # that $course variable no more required
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
    return wantarray ? @chapter_dirs : \@chapter_dirs;
}

sub rm_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->{_path}->{public}, $suffix);
    remove_tree($dir, {error => \my $err});

    # TODO Errorlog
    if (@{$err}) {
        say "Error: remove_tree $err->[0]";
    }
}

sub create_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->{_path}->{public}, $suffix);
    make_path($dir, {error => \my $err});

    # TODO Errorlog
    if (@{$err}) {
        say "Error: make_path $err->[0]";
    }
}

# TODO Test for update_public_struct($self)
sub update_public_struct ($) {
    my $self = shift;
    my $public_dir = $self->{_path}->{public};

    # get content of public/course directory
    opendir(DIR, $public_dir);
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
            opendir(DIR, join ('/', $public_dir, $name));
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
    my $meta_path    = join('/', $self->{_path}->{public}, "meta.json" );
    $self->save_public_struct($meta_path, $hash);
}

# TODO Test for get_public_struct($self, $dir)
sub get_public_struct ($$) {
    my $self    = shift;
    my $dir     = shift || undef;

    my $meta_path;
    if (defined $dir) {
        $meta_path    = join('/', $self->{_path}->{public}, $dir,"meta.json" );
    } else {
        $meta_path    = join('/', $self->{_path}->{public}, "meta.json" );
    }

    my $meta_struct  = $self->load_public_struct($meta_path);
    return $meta_struct ? $meta_struct : $self->{_public_struct};
}

# TODO Test for get_public_page_path($self, $meta_struct, $modul)
sub get_public_page_path ($$$) {
    my $self = shift;
    my $meta_struct = shift;
    my $modul = shift;

    return undef unless defined $meta_struct->{sub};
    for my $m (values $meta_struct->{sub}) {
        return wantarray ? @{$m->{pages}} : $m->{pages} if $m->{meta}->{title} eq $modul;
    }
}

# TODO Test for get_public_navbar($self, $meta_struct, $modul)
sub get_public_navbar ($$$) {
    my $self = shift;
    my $meta_struct = shift;
    my $modul = shift;

    return undef unless defined $meta_struct->{sub};
    for my $m (values $meta_struct->{sub}) {
        if ($m->{meta}->{title} eq $modul) {
            return undef unless defined $m->{sub};
            my @navbar;
            my $pagecnt = 0;
            for my $c (values $m->{sub}) {
                push @navbar, { camelize($c->{id}) => $pagecnt} ;
                $pagecnt = $pagecnt  + $c->{pagecnt};
            }
            return wantarray ? @navbar : \@navbar;
        }
    }
}

# TODO Test for get_public_modul($self)
sub get_public_modul ($) {
    my $self = shift;

    my $hash_list;
    foreach (keys $self->{_public_struct}) {
        @{$hash_list->{$_}} = @{$self->{_public_struct}->{$_}};
    }

    return $hash_list;
}

# TODO Test for save_public_struct($self, $location, $meta_struct)
sub save_public_struct ($$$) {
    my $self = shift;
    my ($location, $meta_struct) = @_;

    my $json_bytes          = $self->hash_to_json($meta_struct);
    
    open  my $FH , ">:encoding(UTF-8)", $location;
    print $FH $json_bytes;
    close $FH;
}

# TODO Test for load_public_struct($self, $location)
sub load_public_struct ($$) {
    my $self        = shift;
    my $location    = shift;
    my $file        = Mojo::Asset::File->new( path => $location);
    my $meta_struct = $self->json_to_hash($file->get_chunk(0));
    return $meta_struct;
}

# }}}

1;
