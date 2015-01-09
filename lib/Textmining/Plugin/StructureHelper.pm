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

=method get_data_module()

This method return the modules files and directory
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
with the informations from the module by
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

=method get_public_module()

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
* L<Textmining::Plugin::CorpusHelper>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Asset::File;
use Mojo::JSON;
use Mojo::Util qw(encode decode camelize);

use Textmining::Plugin::StructureHelper::Transform;
use Textmining::Plugin::StructureHelper::Course;
use Textmining::Plugin::CorpusHelper;

use Storable qw(store_fd fd_retrieve);
use File::Path qw(remove_tree make_path);
use File::Copy::Recursive qw(dircopy);
use File::Basename;

use feature 'say';
our @coursestruct = qw(module library corpus);

sub register {
    my ($self, $app) = @_;
    $app->helper(struct => sub {
            state $struct   = $self->new->init($app);
        });
}

sub init ($$) {
    my ($self, $app) = @_;
    $self->{log}    = $app->log;
    $self->{home}   = $app->home;
    $self->{_path}  = $app->config->{path};
    unless (defined $self->{_path}->{xsl}){
        $self->{_path}->{xsl}->{module}  = $self->{home}->to_string . '/templates/res/xsl/page.xsl';
        $self->{_path}->{xsl}->{library} = $self->{home}->to_string . '/templates/res/xsl/page-library.xsl';
    } else {
        unless (defined $self->{_path}->{xsl}->{module}){
            $self->{_path}->{xsl}->{module} = $self->{home}->to_string . '/templates/res/xsl/page.xsl';
        } else {
            $self->{_path}->{xsl}->{module} = join("/", $self->{home}->to_string, $self->{_path}->{xsl}->{module})
                    unless ($self->{_path}->{xsl}->{module} =~ "$self->{home}->to_string");
        }
        unless (defined $self->{_path}->{xsl}->{library}){
            $self->{_path}->{xsl}->{library} = $self->{home}->to_string . '/templates/res/xsl/page.xsl';
        } else {
            $self->{_path}->{xsl}->{library} = join("/", $self->{home}->to_string, $self->{_path}->{xsl}->{library})
                    unless ($self->{_path}->{xsl}->{library} =~ "$self->{home}->to_string");
        }
    }
    $self->{_data_struct} = $self->load_struct($self->get_data_path()) || {};
    $self->{_public_struct} = $self->load_struct($self->get_public_path()) || {};

    $self->{transform} = Textmining::Plugin::StructureHelper::Transform->new->init($app);
    $self->{course} = Textmining::Plugin::StructureHelper::Course->new->init($app);
    $self->{corpus} = Textmining::Plugin::CorpusHelper->new->init($app);
    return $self;
}

#{{{ utils

sub _exists_check ($$) {
    #my $self    = shift if __PACKAGE__ =~ qr/Textmining::Plugin::StructureHelper/ ;
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

sub _search_tree($$) {
    my $tree    = shift;
    my $pattern = shift;

    if (defined $tree) {
        for my $node (sort keys %{$tree}) {
            return $pattern if ($node eq $pattern);
            my $next_tree = $tree->{$node};
            my $result = &_search_tree($next_tree, $pattern);
            if (defined $result) {
               return join( '/', $node, $result);
            }
        }
    }
    return undef;
}

sub _get_files ($) {
    my $dir = shift;
    opendir(DIR, $dir);
    my @files = readdir(DIR);
    closedir(DIR);

    my @o_files;
    for my $file (values @files) {
        # ignore .
        if ($file =~ qr/(^[^\.])/
                and not -d join('/', $dir, $file)) {
            push @o_files, $file;
        }
    }
    return @o_files;
}

#TODO Test for _store
sub _store($$) {
    my $data        =   shift;
    my $location    =   shift;

    open  my $FH , ">", $location || return undef;
    store_fd \$data, $FH;
    close $FH;
}

#TODO Test for _retrieve
sub _retrieve($) {
    my $location    = shift;

    open  my $FH , "<", $location || return undef;
    my $data = fd_retrieve($FH);
    close $FH;
    return ${$data};
}

sub hash_to_json ($$) {
    my $self                = shift;
    my $meta_struct         = shift;
    my $json                = Mojo::JSON->new;
    my $json_bytes          = $json->encode($meta_struct);
    my $err                 = $json->error;
    if (defined $err) {
        $self->{log}->error("json encode: $err");
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
        $self->{log}->error("json decode: $err");
    }
    return $meta_struct;
}

sub save_struct ($$$) {
    my $self = shift;
    my ($location, $meta_struct) = @_;

    $location = join('/', $location, ".meta");

    my $json_bytes = $self->hash_to_json($meta_struct);

    unless (defined &_store($json_bytes, $location)){
        $self->{log}->error("file $location not opened");
        return undef;
    }
}

sub load_struct ($$) {
    my $self        = shift;
    my $location    = shift || scalar $self->get_public_path();

    $location       = join('/', $location, ".meta");
    if (&_exists_check($location)) {
        $self->{log}->warn("file $location not exists");
        return undef;
    }

    my $meta_struct = $self->json_to_hash(&_retrieve($location));
    return $meta_struct;
}

#}}}

# {{{ data directory

sub get_data_path ($$) {
    my $self = shift;
    my $course  =   shift || undef;

    return join('/', $self->get_data_path(), $course) if (defined $course);
    return $self->{_path}->{data};
}

sub update_data_struct ($) {
    my $self = shift;

    my $data = $self->get_data_path();

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

    for my $course (keys %{$hash}) {
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
    $self->save_struct($data, $hash);
}

sub get_data_struct ($) {
    my $self = shift;

    $self->{_data_struct} = $self->load_struct($self->get_data_path)
            unless (keys %{$self->{_data_struct}});
    $self->{_data_struct} = {} unless defined $self->{_data_struct};
    return $self->{_data_struct};
}

sub get_data_course ($) {
    my $self = shift;

    my @course_list;
    foreach (keys %{$self->get_data_struct()}) {
        push @course_list, $_;
    }

    return wantarray ? @course_list : \@course_list;
}

sub get_data_module ($$) {
    my $self = shift;
    my $course = shift;

    my @courses_keys = (keys %{$self->get_data_struct()});
    unless ( $course ~~ @courses_keys ) {
        if (defined $self->{log}) {
            $self->{log}->error("module: course $course not in \'" . join(',', @courses_keys) . "\'");
        } else {
            print STDERR "module: course $course not in \'@courses_keys\'";
        }
        return undef;
    }

    my $modules = {
        path    => join('/', $self->get_data_path, $course, 'module'),
        files   => \@{$self->get_data_struct()->{$course}->{module}}
    };

    return $modules;
}

sub get_data_library ($$) {
    my $self = shift;
    my $course = shift;

    my @courses_keys = (keys %{$self->get_data_struct()});
    unless ( $course ~~ @courses_keys ) {
        if (defined $self->{log}) {
            $self->{log}->error("library: course $course not in \'@courses_keys\'");
        } else {
            print STDERR "library: course $course not in \'@courses_keys\'";
        }
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

    my @courses_keys = (keys %{$self->get_data_struct()});
    unless ( $course ~~ @courses_keys ) {
        if (defined $self->{log}) {
            $self->{log}->error("corpus: course $course not in \'@courses_keys\'");
        } else {
            print STDERR "corpus: course $course not in \'@courses_keys\'";
        }
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
    my $course  =   shift || undef;

    return join('/', $self->get_public_path(), $course) if (defined $course);
    return $self->{_path}->{public};
}

sub init_public_course ($$) {
    my ($self, $course) = @_;

    my $dest    = $self->get_public_path($course);
    my $module  = $self->get_data_module($course);
    my $library = $self->get_data_library($course);
    my $corpus  = $self->get_data_corpus($course);
    my $resource = join('/', $self->get_data_path($course), 'res');

    unless (&_exists_check($dest)) {
        $self->rm_public_path($course);
        #say "rm public directory of $course";
    }
    if (&_exists_check($dest)) {
        $self->create_public_path("$course/$_")
                foreach (@coursestruct);
        #say "create public directory of $course";
    }

    my $course_meta_struct;
    if (@{$module->{files}}) {
        $course_meta_struct = $self->{course}->get_course_struct(
            join('/', $module->{path}, @{$module->{files}}[0])
        );
    } else {
        $self->{log}->error('init_public_course: no module file');
        return undef;
    }
    # TODO change parameter for the output of
    # $self->get_data_module($course)
    for my $module_file (values @{$module->{files}}) {
        # module nodes
        my $module_struct    = $self->{course}->get_module_struct(
                join('/', $module->{path}, $module_file) );

        my $module_dir = join('/',
            $course, 'module',
            $module_struct->{meta}->{title}
        );

        # copy extra resourcen
        unless (&_exists_check($resource)) {
            dircopy($resource, join('/', $dest, 'res')) or
                    $self->{log}->error("resourcen directory $resource could not be recursive  copy") ;
        } else {
            $self->{log}->debug("resource directory $resource not exists");
        }
        # {{ TODO build a stack of
        # create_public_modul
        # -> create_pages
        # update every sub module with $page_meta_list see bottom of fnct
        my @chapter_dirs    = $self->create_public_chapter(
                $module_dir,
                $module_struct
            );

        my @page_docs = $self->{transform}->xml_doc_pages(
                join('/', $module->{path}, $module_file),
                $library->{path},
                $library->{files}
            );

        # XML::LibXML is running over the hole doc
        $page_docs[0] = $self->{transform}->update_xml_tag_img(
                    join('/', $course, "res"),
                    $page_docs[0]
                );

        my $module_pages;

        $self->{transform}->get_xsl($self->{_path}->{xsl}->{module});
        $module_pages->{$module_file} = $self->{transform}->nodestohtml(\@page_docs);
                #use Data::Printer;
                #p $module_pages;
                #p @chapter_dirs;
        $module_struct->{pages} = $self->create_public_pages(
                        $module_pages,
                        \@chapter_dirs
                    );

        $self->create_public_library(
                $library->{path},
                $library->{files},
                $course
            );

        #p $module_struct;
        #if (defined $module_struct->{meta}->{corpora} and 0)  {
        #    my $corpora_data = $self->create_public_corpus(
        #        $corpus->{path},
        #        $corpus->{files},
        #        $module_struct->{meta}->{corpora}
        #    );
        #    #save corpora_data
        #    #p $course_meta_struct;
        #    #p $module_struct;
        #    #p $corpora_data;

        #    for my $filename (keys $corpora_data) {
        #        my $location = join '/', $dest, 'corpus', $filename;
        #        &_store($corpora_data->{$filename}, $location);
        #        $module_struct->{meta}->{corpora}->{$filename}->{public} = $location;
        #    }
        #}

        $course_meta_struct->{$module_struct->{meta}->{title}} = $module_struct;
    }
    $self->save_struct($dest, $course_meta_struct);

    # }}
    $self->update_public_struct();
    return $course_meta_struct;
}

sub create_public_chapter ($$$) {
    my $self    = shift;
    my $module_dir  = shift;
    my $module_meta_struct = shift;

    my @chapter_dirs;
    for my $chaptcnt (0 .. $#{$module_meta_struct->{sub}}) {
        my $chapter_dir = join('/',
            $module_dir,
            $chaptcnt . "_" .
            $module_meta_struct->{sub}->[$chaptcnt]->{id}
        );
        $self->create_public_path($chapter_dir);
        my $tmp = {
            dir     => $chapter_dir,
            pagecnt => $module_meta_struct->{sub}->[$chaptcnt]->{pagecnt}
        };
        push @chapter_dirs, $tmp;
    }
    return wantarray ? @chapter_dirs : \@chapter_dirs;
}

sub create_public_pages ($$$) {
    my $self = shift;
    my $module_pages = shift;
    my $chapter_dirs = shift;

    my @page_meta_list;
    my $prev_page = undef;
    for my $module_key (keys %{$module_pages}) {
        my $pages;
        push @{$pages->{$module_key}}, $_ foreach (@{$module_pages->{$module_key}});
        for my $chapter (values @{$chapter_dirs}){
            for my $pagenr (1..$chapter->{pagecnt}) {
                my $page    = join(
                    '/',
                    $self->get_public_path(),
                    $chapter->{dir},
                    "$pagenr.html");

                #say $page;
                open FH, ">:encoding(UTF-8)", $page
                    or $self->{log}->error("init_public_course: open UTF-8 encode file failed")
                    and return undef;
                print FH shift @{$pages->{$module_key}};
                close FH;
                push @page_meta_list, $page;
            }
        }
    }
    return wantarray ? @page_meta_list : \@page_meta_list;
}

sub create_public_corpus ($$$) {
    my $self    = shift;
    my $dir     = shift; # basedir
    my $files   = shift; # like a tree
    my $corpora = shift;

    my $corpora_data_struct;
    for my $corpus_id (sort keys @{$corpora}) {
        my $corpus = $corpora->{$corpus_id}->{src};
        next if (&_exists_check(join('/', $dir, $corpus)));
        my $corpus_file = &_search_tree($files, $corpus);
        next unless (defined $corpus_file);
        my @corpus_files;
        # is regulary file?
        if (-f join('/', $dir, $corpus_file) ){
            push @corpus_files, $corpus_file;
        } else { # or a directory
            my @files = &_get_files(join('/', $dir, $corpus_file));
            # XXX warn message no corpus found
            next unless @files;
            push @corpus_files, join('/', $corpus_file, $_ ) foreach (@files);
        }
        my $filter = $corpora->{$corpus_id}->{parts};
        $filter = [split ',', $filter] if (defined $filter);

        my $type = $corpora->{$corpus_id}->{type};
        if ($type =~ qr/collocation/) {
            $type = $self->{corpus}->collocation;
        } elsif ($type =~ qr/keywords/) {
            $type = $self->{corpus}->keywords;
        } else {
            # XXX warning that vo valid type found use
            # collocation or keywords
            #
            # try to find out which could be
            if (defined $filter) {
                # XXX info message to use for type keywords
                $type = $self->{corpus}->keywords;
            } else {
                # XXX info message to use for type collocation
                $type = $self->{corpus}->collocation;
            }
        }

        my $corpus_data = $self->{corpus}->get_corpus(
                $dir, \@corpus_files, $filter, $type
                );

        $corpus_data = $self->{corpus}->compare_corpus($corpus_data)
                if ($type == $self->{corpus}->keywords);
        $corpus_data = $self->{corpus}->collocation_corpus($corpus_data, $type)
                if ($type == $self->{corpus}->collocation);
        for my $id (keys %{$corpus_data->{id}}) {
            $corpora_data_struct->{$corpus_id}->{id}->{$id} = $corpus_data->{id}->{$id};
        }

        if ($type == $self->{corpus}->keywords) {
            for my $part (values @{$filter}) {
                    $corpora_data_struct->{$corpus_id}->{$part}->{$_} =
                            $corpus_data->{$part}->{$_} foreach (keys %{$corpus_data->{$part}});
            }
        }
    }

    return $corpora_data_struct;
}

sub create_public_library {
    my $self     =   shift;
    my $data_dir =   shift;
    my $data_files = shift;
    my $course   =   shift;

    my $public_dest = join '/', $self->get_public_path($course), 'library';

    my @html_files;
    foreach (values @{$data_files}) {
        my $data_src = join '/', $data_dir, $_;
        my $doc = $self->{transform}->get_doc($data_src);
        my $style = $self->{transform}->get_xsl($self->{_path}->{xsl}->{library});
        my $html_string = $self->{transform}->doctohtml($doc);
        my $html_file = $_;
        $html_file =~ s/\.xml$/.html/;
        my $html_file_path = join('/', $public_dest, $html_file);
        open FH, ">:encoding(UTF-8)", $html_file_path
            or $self->{log}->error("create_public_library: open UTF-8 encode file failed")
            and return undef;
        push @html_files, $html_file_path;
        print FH $html_string;
        close FH;
    }
    return wantarray ? @html_files : \@html_files;
}

sub rm_public_path ($$) {
    my ($self, $suffix) = @_;

    my $dir          = join('/', $self->get_public_path, $suffix);
    remove_tree($dir, {error => \my $err});

    if (@{$err}) {
        $self->{log}->error("remove_tree $err->[0]");
    }
    return $dir;
}

sub create_public_path ($$) {
    my ($self, $path) = @_;

    my $dir          = join('/', $self->get_public_path, $path);
    make_path($dir, {error => \my $err});

    if (@{$err}) {
        $self->{log}->error("make_path $err->[0]");
    }
    return $dir;
}

sub update_public_struct ($) {
    my $self = shift;

    my $hash = {} ;
    $hash = &_tree($self->get_public_path());

    $self->{_public_struct} = undef;
    $self->{_public_struct} = $hash;
    $self->save_struct($self->get_public_path(), $hash);
}

sub get_public_struct ($$) {
    my $self    = shift;
    my $course  = shift || undef;

    return $self->load_struct($self->get_public_path($course)) if (defined $course);
    $self->update_public_struct() unless (keys %{$self->{_public_struct}});
    return $self->{_public_struct};
}

sub get_public_course_struct ($$) {
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

    return $course_meta_struct->{$modul} ?
             $course_meta_struct->{$modul}->{pages} : undef;
}

sub get_public_navbar ($$$) {
    my $self            = shift;
    my $course_meta_struct = shift || return undef;
    my $modul           = shift || return undef;

    return undef unless (defined $course_meta_struct->{$modul});
    my $m = $course_meta_struct->{$modul};
    return undef unless (defined $m->{sub});
    my @navbar;
    my $pagecnt = 0;
    for my $c (values @{$m->{sub}}) {
        push @navbar, { camelize($c->{id}) => $pagecnt };
        $pagecnt = $pagecnt + $c->{pagecnt};
    }
    return wantarray ? @navbar : \@navbar;
}
# }}}

1;
