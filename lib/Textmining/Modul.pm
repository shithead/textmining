package Textmining::Modul;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util 'camelize';
use Mojo::Asset::File;
use Mojo::ByteStream;

# This action will render a template
sub module {
    my $self    = shift;
    my $course  = $self->param('course');
    my $module   = $self->param('module');
    my $pagenr  = $self->param('page') || scalar 0;

    my $course_meta_struct  = $self->struct->load_struct(
            $self->struct->get_public_path($course));

    my $page_path   = $self->struct->get_public_page_path($course_meta_struct, $module);
    my @navbar      = $self->struct->get_public_navbar($course_meta_struct, $module);

    # TODO error message
    unless ($page_path || @navbar) {
        print STDERR "page_path or navbar empty\n";
        $self->redirect_to('/course') ;
    }
    # TODO
    # a job for Mojo::Content ? 
    $pagenr = 0 if ($pagenr >= (@{$page_path} - 1));
    $pagenr = @{$page_path} - $pagenr - 2 if ($pagenr < 0);

    my $file      = Mojo::Asset::File->new( path => $page_path->[$pagenr]);
    my $stream    = Mojo::ByteStream->new($file->slurp)->decode('UTF-8');

    # Render template "module/module.html.ep"
    $self->render(
        course        =>  $course,
        module         =>  $module,
        navbar        =>  \@navbar,
        page          =>  $stream,
        pagenr        =>  $pagenr,
        page_path     =>  $page_path,
        meta          =>  $course_meta_struct->{$module}->{meta}
    );
}
1;
