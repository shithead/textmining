#!/usr/bin/env perl

package Textmining;
use Mojo::Base 'Mojolicious';

# TODO Fehlerbehandlung implementieren
# This method will run once at server start
sub startup {
    my $self = shift;


    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');
    # Add namspace for new plugins
    #  StructureHelper
    push @{$self->plugins->namespaces}, 'Textmining::Plugin';
    $self->plugin('StructureHelper');

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('example#welcome');


    # Admin route to controller
    # Admin section
    # Local logic shared only by routes in this group
    my $admin = $r->under( '/admin' => sub {
            #   my $c = shift;
            #   return 1 if $c->req->headers->header('X-Awesome');
            #   $c->render(text => "You're not awesome enough.");
            #   return undef;
            return 1;
        });

    # GET /admin?update=1
    $admin->get()->to('admin#overview');
    # POST /admin/course?course="foo"&type="bar"
    $admin->post('/course')->to('admin#course');
    # POST /admin/open?course="foo"
    $admin->post('/open')->to('admin#open');


    # Course route to controller
    # Course section
    my $course = $r->under( '/course' => sub {
            #   my $c = shift;
            #   return 1 if $c->req->headers->header('X-Awesome');
            #   $c->render(text => "You're not awesome enough.");
            #   return undef;
            return 1;
        });

    # Course route to controller
    $course->get()->to('course#overview');

    # Modul route to controller
    # GET /course/modul?course="foo"&modul="bar"&page=<nr>
    $course->get('/modul')->to('modul#modul');
    # TODO websocket
}

1;
