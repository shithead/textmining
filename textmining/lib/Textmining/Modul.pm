package Textmining::Modul;
use Mojo::Base 'Mojolicious::Controller';

use Data::Printer;
# This action will render a template
sub modul {
  my $self = shift;

  my $course = $self->param('course');
  my $modul = $self->param('modul');
  # Render template "modul/modul.html.ep"
  # TODO create in StrureHelper.pm : 
  # * get_public_page_path($meta_struct, $modul)
  my $course_meta_struct  = $self->struct->get_public_struct($course);
  p $course_meta_struct;
  my @page_path = &_get_public_page_path($course_meta_struct, $modul);
  p @page_path;
  # TODO io loop iterationdurc @page_path for modul_content previous and next
  $self->render(title => $modul, modul_page => "bar", previous => undef, next => undef);
}

sub _get_public_page_path ($$$) {
    #my $self = shift;
    my $meta_struct = shift;
    my $modul = shift;

    for my $m (values $meta_struct->{sub}) {
        return @{$m->{sub}} if $m->{meta}->{title} eq $modul;
    }
}
1;
