package Textmining::Modul;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util 'camelize';
use Mojo::Asset::File;
use Mojo::ByteStream;

# This action will render a template
sub modul {
    my $self = shift;
    my $course = $self->param('course');
    my $modul  = $self->param('modul');
    my $pagenr = $self->param('page') or 0;

    my $course_meta_struct  = $self->struct->get_public_struct($course);
    my @page_path   = $self->struct->get_public_page_path($course_meta_struct, $modul);
    my @navbar      = $self->struct->get_public_navbar($course_meta_struct, $modul);

    # TODO error message
    $self->redirect_to('/course') unless (@page_path);
    # TODO
    # a job for Mojo::Content ? 
    $pagenr = 0 if ($pagenr >= (@page_path - 1));
    $pagenr = @page_path - $pagenr - 2 if ($pagenr < 0);

    my $file      = Mojo::Asset::File->new( path => $page_path[$pagenr]);
    my $stream    = Mojo::ByteStream->new($file->slurp)->decode('UTF-8');

    # Render template "modul/modul.html.ep"
    $self->render(
        course        =>  $course,
        modul         =>  $modul,
        navbar        =>  \@navbar,
        page          =>  $stream,
        pagenr        =>  $pagenr,
        page_path     =>  \@page_path
    );
}
1;
