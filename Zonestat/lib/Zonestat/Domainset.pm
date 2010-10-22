package Zonestat::Domainset;

use strict;
use warnings;

use base 'Zonestat::Common';

use Digest::SHA1 qw[sha1_hex];
use Try::Tiny;

use Data::Dumper;

sub new {
    my $class  = shift;
    my $parent = shift;
    my $self   = $class->SUPER::new($parent);
    $self->{name} = shift;

    return $self;
}

sub name { return $_[0]->{name} }

sub db {
    my $self = shift;
    my $name = shift || 'zonestat-dset';

    return $self->SUPER::db($name);
}

sub id {
    my $self   = shift;
    my $domain = shift;

    return sha1_hex($self->name . $domain);
}

sub add {
    my $self    = shift;
    my @domains = @_;
    my $name    = $self->name;

    $self->db->bulkStore(
        [
            map {
                $self->db->newDoc($self->id($_), undef,
                    { domain => $_, set => $name })
              } @domains
        ]
    );

    return $self;
}

sub remove {
    my $self   = shift;
    my $domain = shift;

    my $doc = $self->db->newDoc($self->id($domain), undef);
    try {
        $doc->retrieve;
        $doc->delete;
    };

    return $self;
}

sub all {
    my $self = shift;
    my $ddoc = $self->db->newDesignDoc('_design/util');

    $ddoc->retrieve;
    return
      map { $_->{value} }
      @{ $ddoc->queryView('set', key => $self->name)->{rows} };
}

sub clear {
    my $self = shift;

    foreach my $domain ($self->all) {
        my $doc = $self->db->newDoc($self->id($domain));
        $doc->retrieve;
        $doc->delete;
    }

    return $self;
}

sub enqueue {
    my $self    = shift;
    my $testrun = $self->run_id;

    my $trdoc = $self->db('zonestat-testrun')->newDoc($testrun, undef,
        { domainset => $self->name, queued_at => time(), testrun => "" . $testrun });
    $trdoc->create;

    $self->parent->gather->put_in_queue(
        map { { domain => $_, priority => 5, source_data => $testrun, } }
          $self->all);

    return $testrun;
}

1;