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

=method save_struct()

This method save the specified meta struct in path.
Is using L<"hash_to_json">.

=method load_struct()

This method load public or specified course meta struct.
Is using L<"json_to_hash">.

=method get_data_path()

This method return the relative path to 'data' directory.

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

=method get_public_path()

This method return the relative path to 'public' directory.

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
Is using L<"load_struct">.

=method update_public_struct()

This method return the structure of the specified 'public/course' directory.
Is using L<"save_struct">.

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
use Textmining::Plugin::StructureHelper::Course;
use File::Path qw(remove_tree make_path);
use File::Basename;

use feature 'say';
our @coursestruct = qw(modul library corpus);

sub register {
  my ($self, $app) = @_;
    $app->helper(struct => sub {
            state $struct = $self->_constructor;
        });
}

sub _constructor {
    my $self = shift;
    # XXX config sinvoll
    $self->{_path} = {
        data => 'data',
        public => 'public/course'
    };
    $self->{_data_struct} = $self->load_struct($self->get_data_path) || {};
    $self->{_public_struct} = $self->load_struct($self->get_public_path) || {};
    $self->{transform} = Textmining::Plugin::StructureHelper::Transform->new();
    $self->{course} = Textmining::Plugin::StructureHelper::Course->new(); 
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
    my $cwd         = shift || scalar '.';
    my $max_deep    = shift || scalar 5;

    return undef if ($max_deep <= 0 || not defined $cwd);
    my $hash = {};
    unless ( -d $cwd ) {
        return undef;
    } else {
        opendir(DIR, $cwd);
        my @files = readdir(DIR);
        closedir(DIR);

        for my $file (values @files) {
            # ignore . and ..
            unless ($file =~ m/(^\.+)/) {
                # build course tree
                my $nxt_wd = join '/', $cwd, $file;
                $hash->{$file} = &_tree($nxt_wd, $max_deep - 1);
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

sub save_struct ($$$) {
    my $self = shift;
    my ($location, $meta_struct) = @_;

    $location = join('/', $location, ".meta.json");

    my $json_bytes = $self->hash_to_json($meta_struct);

    open  my $FH , ">:encoding(UTF-8)", $location;
    print $FH $json_bytes;
    close $FH;
}

sub load_struct ($$) {
    my $self        = shift;
    my $location    = shift || scalar $self->get_public_path;

    $location       = join('/', $location, ".meta.json");
    return {} if (&_exists_check($location));

    my $file        = Mojo::Asset::File->new( path => $location);
    my $meta_struct = $self->json_to_hash($file->get_chunk(0));
    return $meta_struct;
}

#}}}

# {{{ data directory

sub get_data_path ($) {
    my $self = shift;
    return $self->{_path}->{data};
}

sub update_data_struct ($) {
    my $self = shift;
    my $data = $self->get_data_path;

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
    $self->save_struct($self->get_data_path, $hash);
}

sub get_data_struct ($) {
    my $self = shift;


    $self->update_data_struct() unless (keys $self->{_data_struct});
    return $self->{_data_struct};
}

sub get_data_course ($) {
    my $self = shift;

    my @course_list;
    foreach (keys $self->get_data_struct()) {
        push @course_list, $_;
    }

    return wantarray ? @course_list : \@course_list;
}

sub get_data_modul ($$) {
    my $self = shift;
    my $course = shift;

    my @courses_keys = (keys $self->get_data_struct());
    unless (  $course ~~ @courses_keys ) {
        #TODO Errorlog
        say "course $course not in \'" . join(',', @courses_keys) . "\'";
        return undef;
    }

    my $modules = {
        path    => join('/', $self->get_data_path, $course, 'modul'),
        files   => \@{$self->get_data_struct()->{$course}->{modul}}
    };

    return $modules;
}

sub get_data_library ($$) {
    my $self = shift;
    my $course = shift;

    my @courses_keys = (keys $self->get_data_struct());
    unless (  $course ~~ @courses_keys ) {
        #TODO Errorlog
        say "course $course not in \'@courses_keys\'";
        return undef;
    }

    my $libraries = {
        path    => join('/', $self->get_data_path, $course, 'library'),
        files   => \@{$self->get_data_struct()->{$course}->{library} }
    };

    return $libraries;
}

sub get_data_corpus ($$) {
    my $self = shift;
    my $course = shift;

    my @courses_keys = (keys $self->get_data_struct());
    unless (  $course ~~ @courses_keys ) {
        #TODO Errorlog
        say "course $course not in \'@courses_keys\'";
        return undef;
    }

    my $corpora = {
        path    => join('/', $self->get_data_path, $course, 'corpus'),
        files   => $self->get_data_struct()->{$course}->{corpus}
    };

    return $corpora;
}
# }}}

# {{{ public directory

sub get_public_path ($) {
    my $self = shift;
    return $self->{_path}->{public};
}

sub init_public_course ($$) {
    my ($self, $course) = @_;

    my $path = {
        src     => join('/', $self->get_data_path  , $course),
        dest    => join('/', $self->get_public_path, $course),
        modul   => $self->get_data_modul($course),
        library => $self->get_data_library($course)
    };

    my $course_meta_struct;
    # TODO change parameter for the output of 
    # $self->get_data_modul($course)
    $course_meta_struct = $self->{course}->get_course_struct(
        $path->{modul}->{path},
        $path->{modul}->{files}
    );


    unless (&_exists_check($path->{dest})) {
        $self->rm_public_path($course);
        #say "rm public directory of $course";
    }
    if (&_exists_check($path->{dest})) {
        $self->create_public_path("$course/$_")
                foreach (@coursestruct);
                #say "create public directory of $course";
    }

    # {{ TODO build a stack of 
    # create_public_modul 
    # -> create_pages
    # update every sub modul with $page_meta_list see bottom of fnct
    my @chapter_dirs    = $self->create_public_chapter(
                $course,
                $course_meta_struct
            );


    my $modul_pages;
    foreach (@{$path->{modul}->{files}}) {
        $modul_pages->{$_} = $self->{transform}->xml_doc_pages(
            join('/', $path->{modul}->{path}, $_),
            $path->{library}->{path},
            $path->{library}->{files}
        );
    }

    my @page_meta_list;
    # sub create_pages ($path, $modul_pages, @chapter_dirs)
    # {
    #my @page_meta_list;
    my $prev_page = undef;
    for my $modul_key (keys $modul_pages) {
        for my $chapter (@chapter_dirs){
            for my $pagenr (1..$chapter->{pagecnt}) {
                my $page    = join(
                            '/',
                            $self->get_public_path,
                            $chapter->{dir},
                            "$pagenr.html");

                open FH, ">:encoding(UTF-8)",
                        $page or say "open UTF-8 encode file failed";
                print FH shift @{$modul_pages->{$modul_key}};
                close FH;
                push @page_meta_list, $page;
            }
        }
    }
    # return wantarray ? @page_meta_list : \@page_meta_list;
    # }

    $course_meta_struct->{sub}->[0]->{pages} = \@page_meta_list;

    my $course_meta_path    = join('/', $path->{dest});
    $self->save_struct($course_meta_path, $course_meta_struct);

    # }}
    $self->update_public_struct();
}

sub create_public_chapter ($$$) {
    my $self    = shift;
    my ($course, $course_meta_struct) = @_;

    # TODO directory is knowing, change *_dir so
    # that $course variable is no more required
    my @chapter_dirs;
    for my $modulcnt (0 .. $#{$course_meta_struct->{sub}}) {
        my $modul_dir = join('/',
            $course, 'modul',
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

    my $dir          = join('/', $self->get_public_path, $suffix);
    remove_tree($dir, {error => \my $err});

    # TODO Errorlog
    if (@{$err}) {
        say "Error: remove_tree $err->[0]";
    }
}

sub create_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->get_public_path, $suffix);
    make_path($dir, {error => \my $err});

    # TODO Errorlog
    if (@{$err}) {
        say "Error: make_path $err->[0]";
    }
}

sub update_public_struct ($) {
    my $self = shift;
    my $hash = {} ;

    $hash = &_tree($self->get_public_path);

    undef $self->{_public_struct};
    $self->{_public_struct} = $hash;
    $self->save_struct($self->get_public_path, $hash);
}

sub get_public_struct ($) {
    my $self    = shift;

    $self->update_public_struct unless (keys $self->{_public_struct});
    return $self->{_public_struct};
}

sub get_public_modul_struct ($$) {
    my $self    = shift;
    my $course  = shift || return undef;

    return $self->get_public_struct()->{$course};
}

# }}}
# {{{ Web foo

sub get_public_page_path ($$$) {
    my $self    = shift;
    my $course_meta_struct
                = shift || return undef;
    my $modul   = shift || return undef;

    return undef unless defined $course_meta_struct->{sub};
    for my $m (values $course_meta_struct->{sub}) {
        return wantarray ? @{$m->{pages}} : $m->{pages}
                if $m->{meta}->{title} eq $modul;
    }
}

sub get_public_navbar ($$$) {
    my $self            = shift;
    my $course_meta_struct
                        = shift || return undef;
    my $modul           = shift || return undef;
    return undef unless defined $course_meta_struct->{sub};
    for my $m (values $course_meta_struct->{sub}) {
        if ($m->{meta}->{title} eq $modul) {
            return undef unless defined $m->{sub};
            my @navbar;
            my $pagecnt = 0;
            for my $c (values $m->{sub}) {
                push @navbar, { camelize($c->{id}) => $pagecnt };
                $pagecnt = $pagecnt + $c->{pagecnt};
            }
            return wantarray ? @navbar : \@navbar;
        }
    }
}
# }}}

1;
