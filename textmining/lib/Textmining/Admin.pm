package Textmining::Admin;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub overview {
    my $self = shift;
    # Render template "admin/overview.html.ep" with available courses
    my @courses = $self->struct->get_data_course();
    $self->render(courses => \@courses);
}

sub open {
    my $self = shift;

    my $course = $self->param('course');
    $self->struct->init_public_course($course);
    $self->redirect_to('/admin');
}

sub course {
    my $self = shift;

    my $course = $self->param('course');
    my $type = $self->param('type');

    if ($type =~ m/free/) {
        $self->struct->get_modules_data($course);
    }
    $self->redirect_to('/admin');
}

sub update {
    my $self = shift;

    $self->struct->update_data_struct();
    $self->redirect_to('/admin');
}
1;
