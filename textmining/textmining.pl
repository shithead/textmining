#!/usr/bin/env perl
use Mojolicious::Lite;
use XML::XSLT;
use Data::Printer;

use lib 'lib';
use Login;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

# Helper to lazy initialize and store our model object
helper users => sub { state $users = Login->new };

# /admin/?user=sri&pass=secr3t
any '/admin/' => sub {
    my $self = shift;

    # Query parameters
    my $user = $self->param('user') || '';
    my $pass = $self->param('pass') || '';

    # Check password
    return $self->render(text => "Welcome $user.")
    if $self->users->check($user, $pass);

    # Failed
    $self->render(text => 'Wrong username or password.');
};

get '/data/' => sub {
    my $self = shift;
    my $xslfilename = './res/elearningtextmining.xsl';
    my $xmlfilename = './data/e-Learning-Kurs_Text_Mining/kollokationen.xml';
    my $htmlfilename = 'testhtml.html';

    my $xslt = XML::XSLT->new ( $xslfilename, warnings => 1);
    $xslt->transform ($xmlfilename);
    open (my $htmlfile, '>', './public/' . $htmlfilename) or die $!;
    print $htmlfile  "<!doctype html>" . $xslt->toString;
    open my $xmlfile , "<", $xmlfilename or die $!;
    print $xslt->serve <$xmlfile;
    close $htmlfile;

    $self->render_static($htmlfilename);

    $xslt->dispose();

};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
