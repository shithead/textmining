#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR;
# ABSTRACT: a wrapper library from Text::NSP::Measures::2D::MI::ll

=head1 SYNOPSIS

=method register()

This method is need to register this plugin in mojo.


=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR>
* L<Textmining::Plugin::StructureHelper::Corpus>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Text::NSP::Measures::2D::MI::ll;

sub calculate ($%) {
    my $self    = shift;
    my %values  = @_;

    return calculateStatistic(%values);
}

sub getName ($) {
    my $self    = shift;
    return getStatisticName;
}

sub getErrCode ($) {
    my $self    = shift;
    return getErrorCode;
}

sub getErrMesg ($) {
    my $self    = shift;
    return getErrorMessage;
}

sub initialize ($) {
    my $self    = shift;
    return initializeStatistic();
}
1;
