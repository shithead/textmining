#!/usr/bin/env perl

package Textmining::Admin;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
    my $self = shift;
    # render template "admin/overview.html.ep" with available courses
    $self->struct->update_data_struct() if ( $self->param('update') );
    my @courses = $self->struct->get_data_course();
    $self->render(courses => \@courses);
}

sub update {
    my $self = shift;
    # render template "admin/overview.html.ep" with available courses
    $self->struct->update_data_struct();
    $self->redirect_to('/admin');
}

sub open {
    my $self = shift;

    my $course = $self->stash('course');
    if ($course) {
        $self->struct->init_public_course($course);
    }
    $self->redirect_to('/admin');
}

sub course {
    my $self = shift;

    my $course = $self->stash('course');
    my $type = $self->stash('type');

    if ($type =~ m/free/) {
        $self->struct->get_modules_data($course);
    }
    $self->redirect_to('/admin');
}

1;
