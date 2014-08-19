package Textmining::Course;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
  my $self = shift;

  # Render template "course/overview.html.ep" with table
  #$self->struct->update_public_struct;
  my $hash = $self->struct->get_public_struct;
  $self->render(table => $hash);
}

1;
