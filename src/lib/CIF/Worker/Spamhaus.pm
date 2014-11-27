package CIF::Worker::Spamhaus;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Net::Abuse::Utils::Spamhaus qw(check_ip check_fqdn);

use constant {
    CONFIDENCE  => 95,
};

use Mouse;
use CIF qw/is_fqdn is_ip is_ip_private $Logger/;

with 'CIF::WorkerFqdn';

sub understands {
    my $self = shift;
    my $args = shift;
    
    warn Dumper($args);
    
    return if($args->{'provider'} && $args->{'povider'} eq 'spamhaus.org');

    return unless(is_fqdn($args->{'observable'}) || is_ip($args->{'observable'}));
    return 1;
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $obs = $data->{'observable'};
    my (@array,$ret);
    
    if(is_ip($obs)){
        $ret = check_ip($obs,2);
    } else {
        # is fqdn
        $ret = check_fqdn($obs,2);
    }
    
    return unless($ret);
    
    foreach my $rr (@$ret){
        next if(is_ip_private($obs));
        push(@array, {
            observable  => $obs,
            portlist    => $data->{'portlist'},
            protocol    => $data->{'protocol'},
            tags        => $rr->{'assessment'},
            description => $rr->{'description'},
            tlp         => $data->{'tlp'} || CIF::TLP_DEFAULT,
            group       => $data->{'group'} || CIF::GROUP_DEFAULT,
            provider    => 'spamhaus.org',
            confidence  => CONFIDENCE,
            application => $data->{'application'},
            altid       => $rr->{'id'},
            altid_tlp   => 'green',
            related     => $data->{'id'},
        });
    }
    return \@array;
}   

__PACKAGE__->meta->make_immutable();

1;