package Textmining::Admin;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
  my $self = shift;

  # Render template "admin/overview.html.ep" with table
  my @courses = qw(Textmining foo);
  $self->render(courses => \@courses);
}

1;
