package Textmining::Course;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
  my $self = shift;

  # Render template "course/overview.html.ep" with table
  my $hash->{Textming} = "Kollokation";
  $hash->{foo} = "bar";
  $self->render(table => $hash);
}

1;
