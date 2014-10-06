#!/usr/bin/env perl -w

package Textmining::Plugin::StructureHelper::Corpus::Count;
# ABSTRACT: Count.pm - Count the frequency of Ngrams in text

=head1 SYNOPSIS

...

=method get_freq_combo()

This method create the frequency combinations to be computed.

=method get_combo()

This method get the combination

=method get_permu()

This method get permutations

=method process_token()

This method process tokens.

=method vrtToken()

This method

=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Corpus::Count>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Math::Combinatorics;

our $comb_idx = 0;
our %ngram_freq;
our %frequencies;
our $window_idx = 0;
our @window = ();

sub init ($$) {
    my ($self, $app)  = @_;
    $self->{log}    =   $app->log;
    $self->{freq_combo}  = ();
    return $self;
}

sub clearup ($) {
    $comb_idx = 0;
    undef %ngram_freq;
    undef %frequencies;
    $window_idx = 0;
    @window = ();
}

sub calc_freq_combo ($$) {
    my $self    = shift;
    my $ngram   = shift;    # count of n

    $comb_idx = 0;
    my @freq_combo;
    $freq_combo[0][0] = $ngram;
    $freq_combo[0][$_ + 1] = $_ foreach (0..$ngram - 1);
    $comb_idx++;

    &_create_combination(\@freq_combo, $ngram, 0, $_) foreach (1..$ngram - 1);
    $self->{freq_combo} = \@freq_combo;
    return wantarray ? @freq_combo : \@freq_combo;
}

sub _create_combination ($$$$$) {
    my $freq_combo  = shift;
    my $ngram   = shift;    # count of n
    my $level   = shift;
    my $size    = shift;
    my $stack   = shift || ();

    if ($level == $size) {
        @{$freq_combo->[$comb_idx]}[0] = $size;

        @{$freq_combo->[$comb_idx]}[$_] = @{$stack}[$_ - 1]
                foreach (1..$size);
        $comb_idx++;
    } else {
        my $start = $level ? @{$stack}[$level - 1] + 1 : 0;

        foreach ($start..$ngram - 1) {
            @{$stack}[$level] = $_;
            $freq_combo = &_create_combination($freq_combo, $ngram, $level + 1, $size, $stack);
        }
    }
    return $freq_combo;
}

sub get_freq_combo ($$) {
    my $self    =   shift;
    my $ngram   =   shift;

    $self->calc_freq_combo($ngram) if (defined $ngram);
    return wantarray ? @{$self->{freq_combo}} : $self->{freq_combo};
}

sub get_permu ($$$) {
    my $self    = shift;
    my $total_len = shift;
    my $len_req = shift;

    my @permute;
    my $combinat = Math::Combinatorics->new(data => [0..$total_len - 1], count => $len_req);

    my @total_combo;
    push @total_combo, join(',', @_) while (@_ = $combinat->next_permutation);

    my %combo;
    foreach (@total_combo) {
       my @tmp = split(',', $_);
       while( @tmp > $len_req) {
        pop @tmp;
       }
       $combo{join(',', @tmp)} = undef;
    }

    foreach (sort keys %combo) {
        my @tmp = (split(',', $_));
        my $ok = 1;
        if ($len_req > 1) {
            foreach (0..$len_req - 2) {
                if ($tmp[$_] > $tmp[$_ + 1]) {
                    $ok = 0;
                    last;
                }
            }
        }
        push @permute, (@tmp) if ($ok);
    }

    return wantarray ? @permute : \@permute;
}

sub get_ngram_freq ($$$$$$) {
    my $self        = shift;
    my $permutations = shift;
    my $freq_comb   = shift;
    my $token       = shift;
    my $window_size = shift;
    my $ngram       = shift || scalar '2';

    unless ($permutations =~ /ARRAY/) {
        $self->{log}->error('process_token: $permutations must be a reference of ARRAY');
        return undef;
    }
    $token =~ s/\s//g;
    if ($ngram > 1) {
        $window[$window_idx] = $token;
        if ( $window_idx < $ngram - 1 ) {
            $window_idx++;
            return;
        }

        my $perm_idx = 0;
        while ($perm_idx <= @{$permutations} - 1 ) {
            my $ngram_str = "";
            my $ok_flag = 1;
            for ( 0..$ngram - 2 ) {
                if ( @{$permutations}[$perm_idx] < $window_idx ) {
                    $ngram_str .= $window[@{$permutations}[$perm_idx]] . "<>";
                } else { $ok_flag = 0; }
                $perm_idx++;
            }
            if (!$ok_flag) { next; }

            $ngram_str .= "$window[$window_idx]<>";

            $ngram_freq{$ngram_str}++;

            my @words = split /<>/, $ngram_str;
            foreach (0..$comb_idx - 1) {
                my $freq_str = "";
                my $j = $_;
                $freq_str .= "$words[$freq_comb->[$j]->[$_]]<>"
                        foreach (1..$freq_comb->[$j]->[0]);

                $freq_str .= $j;
                $frequencies{$freq_str}++;
            }
        }

        if ( $window_idx < $window_size - 1 ) { $window_idx++; }
        else { shift @window; }

    } else { # if $ngram <= 1
        my $ngram_str = $token . "<>";
        $ngram_freq{$ngram_str}++;
        my $freq_str = $token . "<>0";
        $frequencies{$freq_str}++;
    }
    return %ngram_freq;
}

sub sort_ngram_freq ($$$) {
    my $self = shift;
    my $ngram_freq = shift;
    my $freq_combo = shift;

    my $output = (keys $ngram_freq) . "\n";
    for (sort { $ngram_freq->{$b} <=> $ngram_freq->{$a} } keys $ngram_freq) {
        my @words = split /<>/;

        $output .= "$_"; 

        foreach ( 0..$comb_idx - 1) {
            my $j = $_;
            my $temp_str = "";
            $temp_str .= "$words[@{$freq_combo->[$j]}[$_]]<>" 
                    foreach (1..@{$freq_combo->[$j]}[0]);
            $temp_str .= $j;
            $output .= "$frequencies{$temp_str} ";
        }
        $output .= "\n";
    }
    return $output;
}

sub vrt_token($) {
    my $self    = shift;

    my $token = { wortform => "^(.+?)\t", 
                  pos      => "\t(.+?)\t",
                  lemma    => "\t([^\t]+)\$" 
                };
    return $token;
}

1;
