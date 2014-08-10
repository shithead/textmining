package Textmining;
use Mojo::Base 'Mojolicious';

#use Textmining::Plugin::StructureHelper;

# TODO Fehlerbehandlung implementieren
# This method will run once at server start
sub startup {
    my $self = shift;


    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');
    # Add namspace for new plugins
    #  StructureHelper
    #  TransformHelper
    push @{$self->plugins->namespaces}, 'Textmining::Plugin';
    $self->plugin('StructureHelper');

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('example#welcome');


  # Admin route to controller
  $r->get('/admin')->to('admin#overview');
  $r->post('/admin')->to('admin#overview');

  # Course route to controller
  $r->get('/course')->to('course#overview');
}

1;
