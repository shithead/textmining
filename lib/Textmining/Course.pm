#!/usr/bin/env perl

package Textmining::Course;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
  my $self = shift;

  # Render template "course/overview.html.ep" with table
  my $hash = $self->struct->get_public_struct();
  my $meta_hash;
  $meta_hash->{$_} = $self->struct->get_public_struct($_)->{meta}
        foreach (keys $hash);
  $self->render(table => $hash, meta => $meta_hash );
}
1;
