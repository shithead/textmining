#!/usr/bin/env perl

package Textmining::Plugin::StructureHelper::Corpus::Statistic;
# ABSTRACT: Statistic library for Corpus measuring.

=head1 SYNOPSIS

=method register()

This method is need to register this plugin in mojo.


=head1 SEE ALSO

=for :list
* L<Textmining::Plugin::StructureHelper::Corpus::Statistic>
* L<Textmining::Plugin::StructureHelper::Corpus::Count>
* L<Textmining::Plugin::StructureHelper::Corpus::Statistic::CHI2>
* L<Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Textmining::Plugin::StructureHelper::Corpus::Count;
use Textmining::Plugin::StructureHelper::Corpus::Statistic::CHI2;
use Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR;

sub init ($$)  {
    my ($self, $app)    = @_;
    $self->{log}        = $app->log;
    return $self;
}

sub statistic ($$$) {
    my $self        = shift;
    my $stat_id     = shift;
    my $ngrams_str  = shift || undef;

    unless (defined $ngrams_str) {
        $self->{log}->error("statistic: undefind source string.");
        return undef;
    }

    my $stat;
    if ($stat_id =~ qr/llr/) {
        $stat = Textmining::Plugin::StructureHelper::Corpus::Statistic::LLR->new
    } elsif ($stat_id =~ qr/chi2/) {
        $stat = Textmining::Plugin::StructureHelper::Corpus::Statistic::CHI2->new;
    } else { 
        $self->{log}->error("statistic: no valid statistic: $stat_id");
        return undef;
    }

    my $result = {};
    my @ngrams = split "\n", $ngrams_str;
    my $total_ngram = shift @ngrams;

    $result->{$stat_id} = {};
    $stat->initialize();

    my $total_ngram_counter = 0;

    my @n = $self->get_freq_idx(2);

    foreach (@ngrams) {
        chomp;
        last if ($_ eq "");

        my $ngram       = $_;
        my @tokens      = split /<>/, $ngram;
        my @numbers     = split / /, pop @tokens;

        my %values = (
            n11 =>  $numbers[$n[1][1]],  
            n1p =>  $numbers[$n[1][0]],  
            np1 =>  $numbers[$n[0][1]],  
            npp =>  $total_ngram
        );

        $total_ngram_counter += $numbers[$n[1][1]];

        my $stat_value = $stat->calculate(%values);

        # XXX Maybe the my fnct return 1 ???
        if( ( my $error_code = $stat->getErrCode() ) ) {  
            # error!
            if ($error_code =~ /^1/) {  
                my $error_mesg = $stat->getErrMesg();  
                $self->{log}->error("statistic: Error code: $error_code\t$error_mesg");  
                return undef;
            }  
            # warning!
            if ($error_code =~ /^2/) {  
                my $error_mesg = $stat->getErrMesg();  
                $self->{log}->warn("statistic: Error code: $error_code\t$error_mesg");  
                $self->{log}->warn("statistic: Skipping ngram $ngram");  
                next; # if warning, dont save the statistic value just computed  
            }  
        }  
        my $stat_score = sprintf '%.4f', $stat_value;  
        # perl hashes sorted "automagisch" by default
        $result->{$stat_id}->{$stat_score}
                ->{join(' ', @numbers)}->{join('<>', @tokens)} = undef; 
    }

    $self->{log}->error('statistic: statistic calculation failed')
            if ($total_ngram != $total_ngram_counter);

    return $result;
}

sub get_freq_idx ($$) {
    my $self    =   shift;
    my $ngram   =   shift;    # count of n

    my @freq_comb   = 
            Textmining::Plugin::StructureHelper::Corpus::Count->new
            ->calc_freq_combo($ngram);
    
    my @n;
    # XXX Maybe need the combo_index too
    foreach (0..$#freq_comb) {
        my $str = join (" ", @{$freq_comb[$_]}[1..$freq_comb[$_][0]]);  
        if ($str eq "0 1")  { $n[1][1] = $_; }  
        elsif ($str eq "0") { $n[0][1] = $_; }  
        elsif ($str eq "1") { $n[1][0] = $_; }  
    }

    return wantarray ? @n : \@n;
}

sub compare ($$$) {
    my $self     = shift;
    my $ngrams   = shift;  #array ref compare this 2 elements
    my $min_freq = shift || scalar 5;

    my @n;
    my %ngram_list;
    for (my $j = 0; $j < 2; $j++) {
        my $counter = 0;
        for ( sort keys $ngrams->[$j] ) {
            my $string = $_;
            my $v = $ngrams->[$j]->{$_};
            $n[$j] += $v;
            if ($v >= $min_freq) {
                $ngram_list{$string}->[$j] += $v;
            }

            $counter++;
        }
        $counter = 0;
    }

    my @ngram_key = (keys %ngram_list);

    my $lists = { chi2 => {}, llr => {} };

	for (my $i = 0; $i < @ngram_key; $i++) {
		$ngram_list{$ngram_key[$i]}->[0] = 0 unless ($ngram_list{$ngram_key[$i]}->[0]);
		$ngram_list{$ngram_key[$i]}->[1] = 0 unless ($ngram_list{$ngram_key[$i]}->[1]);
		
		my $kt_a = $ngram_list{$ngram_key[$i]}->[0];
		my $kt_b = $ngram_list{$ngram_key[$i]}->[1];
		my $kt_c = $n[0] - $kt_a;
		my $kt_d = $n[1] - $kt_b;
		
        my $llr = 2 * ($kt_a* log($kt_a) + $kt_b* log($kt_b) + $kt_c* log($kt_c) + $kt_d* log($kt_d) 
            - ($kt_a+$kt_b)* log($kt_a+$kt_b)-($kt_a+$kt_c)* log($kt_a+$kt_c)
            - ($kt_b+$kt_d)* log($kt_b+$kt_d)-($kt_c+$kt_d)* log($kt_c+$kt_d)
            + ($kt_a+$kt_b+$kt_c+$kt_d)* log($kt_a+$kt_b+$kt_c+$kt_d));
		
		$llr = sprintf("%.4f", $llr);
		
		# chi berechnen:
		my $kt_aE = ($kt_a + $kt_c)*($kt_a + $kt_b)/($kt_a + $kt_b + $kt_c + $kt_d);
		my $kt_bE = ($kt_b + $kt_d)*($kt_a + $kt_b)/($kt_a + $kt_b + $kt_c + $kt_d);
		my $kt_cE = ($kt_a + $kt_c)*($kt_b + $kt_d)/($kt_a + $kt_b + $kt_c + $kt_d);
		my $kt_dE = ($kt_b + $kt_d)*($kt_c + $kt_d)/($kt_a + $kt_b + $kt_c + $kt_d);
		
		my $chi = calcChi($kt_a, $kt_aE);
		$chi += calcChi($kt_b, $kt_bE);
		$chi += calcChi($kt_c, $kt_cE);
		$chi += calcChi($kt_d, $kt_dE);
		
		$chi = sprintf("%.4f", $chi);
		
		# chi/llr minus setzen, wenn K2 > K1 und von User gewuenscht
		if ( ($ngram_list{$ngram_key[$i]}->[0]/$n[0])
                    < ($ngram_list{$ngram_key[$i]}->[1]/$n[1])) {	
			$llr = (-1) * $llr;
			$chi = (-1) * $chi;
		}
        $lists->{'llr'}->{$llr}->{$ngram_key[$i]} =
               [ values $ngram_list{$ngram_key[$i]}];
        $lists->{'chi2'}->{$chi}->{$ngram_key[$i]} =
               [ values $ngram_list{$ngram_key[$i]}];
	}
 
    return $lists;
}

sub calcChi {
	my $o = shift;
	my $e = shift;
	
	if (($o-$e)>0) {
		return pow($o-$e-0.5)/$e;
	} else {
		return pow($o-$e+0.5)/$e;
	}
}

sub pow {
	my $v = shift;
	return ($v*$v);
}

1;
