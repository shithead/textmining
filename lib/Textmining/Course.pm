#!/usr/bin/env perl

package Textmining::Course;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
  my $self = shift;

  # Render template "course/overview.html.ep" with table
  my $hash = $self->struct->get_public_struct();
  my $meta_hash = undef;
  if ($hash) {
      foreach (keys $hash) {
          my $course_hash = $self->struct->get_public_struct($_);
          $meta_hash->{$_} = $course_hash->{meta}
                if (defined $course_hash and keys $course_hash);
      }
  }
  $self->render(table => $hash, meta => $meta_hash);
}
1;
