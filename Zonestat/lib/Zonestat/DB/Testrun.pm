package Zonestat::DB::Testrun;

use strict;
use utf8;
use warnings;

use base 'Zonestat::DB::Common';

use POSIX qw[strftime];

sub fetch {
    my $self = shift;

    my $doc = $self->db( 'zonestat-testrun' )->newDoc( $self->{id} );
    $doc->retrieve;

    $self->{doc} = $doc;

    return $self;
}

sub tests {
    my ($self, $startdomain, $reverse, $count) = @_;
    $startdomain ||= '';
    $count ||= 26;
    
    my $res = $self->dbproxy('zonestat')
        ->test_run(
            startkey => [0+$self->id, $startdomain],
            include_docs => 'true',
            limit => $count,
            descending => $reverse,
        );
    
    return [grep {$_->{testrun} == $self->id} map {$_->{doc}} @{$res->{rows}}];
}

sub domainset {
    my $self = shift;

    return $self->data->{domainset};
}

sub name {
    my $self   = shift;
    my $dset   = $self->domainset;
    my $time_t = $self->data->{queued_at};

    return $dset . ' ' . strftime( '%Y-%m-%d %H:%M', localtime( $time_t ) );
}

sub test_count {
    my $self = shift;

    my $dbp = $self->dbproxy( 'zonestat' );
    my $res = $dbp->test_count( group => 1, key => $self->data->{testrun} );

    if ( $res->{rows}[0] ) {
        return $res->{rows}[0]{value};
    }
    else {
        return 0;
    }
}

1;
