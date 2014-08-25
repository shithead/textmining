package Textmining::Modul;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util 'camelize';
use Mojo::Asset::File;
use Mojo::ByteStream;

# This action will render a template
sub modul {
  my $self = shift;

  my $course = $self->param('course');
  my $modul = $self->param('modul');
  my $pagenr = $self->param('page') or 0;
  # Render template "modul/modul.html.ep"
  # TODO create in StrureHelper.pm : 
  # * get_public_page_path($meta_struct, $modul)
  my $course_meta_struct  = $self->struct->get_public_struct($course);
  my @page_path = &_get_public_page_path($course_meta_struct, $modul);
  my @navbar = &_get_public_navbar($course_meta_struct, $modul);

  # TODO error message
  $self->redirect_to('/course') unless (@page_path);
  # TODO
  # a job for Mojo::Content
  $pagenr = 0 if ($pagenr >= (@page_path - 1));
  $pagenr = @page_path - $pagenr - 2 if ($pagenr < 0);

  my $file      = Mojo::Asset::File->new( path => $page_path[$pagenr]);
  my $stream    = Mojo::ByteStream->new($file->slurp)->decode('UTF-8');

  my $progress = ($pagenr / @page_path) * 100;
  $self->render(
      course        =>  $course,
      modul         =>  $modul,
      navbar        =>  \@navbar,
      page          =>  $stream,
      pagenr        =>  $pagenr,
      progress      =>  $progress
  );
}

sub _get_public_page_path ($$$) {
    #my $self = shift;
    my $meta_struct = shift;
    my $modul = shift;

    return undef unless defined $meta_struct->{sub};
    for my $m (values $meta_struct->{sub}) {
        return @{$m->{pages}} if $m->{meta}->{title} eq $modul;
    }
}
sub _get_public_navbar ($$$) {
    #my $self = shift;
    my $meta_struct = shift;
    my $modul = shift;

    p $meta_struct;
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
            return @navbar;
        }
    }
}
1;
