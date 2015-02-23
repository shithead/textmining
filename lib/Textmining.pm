#!/usr/bin/env perl

package Textmining;
use Mojo::Base 'Mojolicious';
use Mojo::JSON qw(decode_json encode_json);
use File::Glob ':globally';
use Data::Printer;

# This method will run once at server start
sub startup {
    my $self = shift;


    # Configuration file loadable
    $self->plugin('Config');

    $self->mode($self->config->{mode});
    $self->home->parse($self->config->{home});
    $self->log->path($self->config->{log}->{path});
    $self->log->level($self->config->{log}->{level});
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

    $r->any("not_found")->to("course#overview");

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

    # GET /admin
    $admin->get()->to('admin#overview');
    # GET /admin/update
    $admin->get('/update')->to('admin#update');
    # GET /admin/course/:course/:type
    #$admin->post('/course/:course/:type')->to('admin#course');
    # GET /admin/open/:course
    $admin->get('/open/:course')->to('admin#open');


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
    # GET /course/module?course="foo"&module="bar"&page=<nr>
    $course->get('/module/:course/:module')->to('module#module');
    $course->any('/module/ws')->name('modulews')->to('module#ws');
    $course->get('/corpus/:course/:corpus')->to('course#corpus');
    $r->get('/json/:query' => sub {
            my $c = shift;
            my ($query);
            my $req = {};
            my $res = {};
            my @filtered_src;

            $req->{query}  = $c->stash('query');
            if ($req->{query}) {
                my @sources = glob("./{public}/{course}/*/*");
                p @sources;
                foreach (@sources) {
                    if ($_ =~ m/$req->{query}/) {
                       push @filtered_src, $_;
                    }
                }
                $res->{sources} =  \@sources;
                #<$self->config->{path}->{data}/*/$req->{query}>;
            }

            $c->render(json =>$res);
        });
}

1;
