package Zonestat::Gather;

use 5.008008;
use strict;
use warnings;

use base 'Zonestat::Common';

use Carp;

our $VERSION = '0.02';
our $debug   = 0;
STDOUT->autoflush(1) if $debug;

=head1

sub enqueue_domainset {
    my $self = shift;
    my $ds   = shift;
    my $name = shift || strftime('%g%m%d %H:%M', localtime());

    my $run = $ds->add_to_testruns({ name => $name });
    my $dbh = $self->dbh;

   # We use a direct DBI call here, since not having to bring the data up from
   # the database and then back into it again speeds things up by several orders
   # of magnitude.
    $dbh->do(
        'INSERT INTO queue (domain, priority, source_id, source_data)
         SELECT domains.domain, 4, ?, ? FROM domains, domain_set_glue
         WHERE domain_set_glue.set_id = ? AND domains.id = domain_set_glue.domain_id',
        undef,
        $self->source_id,
        $run->id,
        $ds->id
    );
}

sub rescan_unknown_servers {
    my $self = shift;
    my $db = $self->dbx('Webserver')->search({ type => 'Unknown' });

  DOMAIN:
    while (my $row = $db->next) {
        my $str = $row->raw_type;
        foreach my $r (keys %server_regexps) {
            if ($str =~ $r) {
                print "Updating to "
                  . $server_regexps{$r} . ": "
                  . $row->raw_response . "\n"
                  if $debug;
                $row->update(
                    {
                        type    => $server_regexps{$r},
                        version => $1
                    }
                );
            }
        }
    }
}

sub kaminsky_check {
    my $self = shift;
    my $addr = shift;

    # https://www.dns-oarc.net/oarc/services/porttest
    my $res = Net::DNS::Resolver->new(
        nameservers => [$addr],
        recurse     => 1,
    );
    my $p = $res->query('porttest.dns-oarc.net', 'IN', 'TXT', $addr);

    if (defined($p) and $p->header->ancount > 0) {
        my $r = (grep { $_->type eq 'TXT' } $p->answer)[0];
        if ($r) {
            my ($verdict) = $r->txtdata =~ m/ is ([A-Z]+):/;
            $verdict ||= 'UNKNOWN';
            return $verdict;
        }
    }

    return "UNKNOWN";
}

=cut

1;
__END__

=head1 NAME

Zonestat::Gather - gather and store statistics

=head1 SYNOPSIS

  use Zonestat;
  
  my $gather = Zonestat->new->gather;

=head1 DESCRIPTION

=head2 Methods

=over 4

=item ->enqueue_domainset($domainset, [$name])

Put all domains in the given domainset object on the gathering queue and
create a new testrun object for it. If a second argument is given, it will be
used as the name of the testrun. If no name is given, a name based on the
current time will be generated.

=item ->get_server_data($trid, $domainname)

Given the ID number of a testrun object and the name of a domain, gather all
data for that domain and store in the database associated with the given
testrun.

=item ->rescan_unknown_servers()

Walk through the list of all Webserver objects with type 'Unknown' and reapply
the list of server type regexps. To be used when the list of regexps has been
extended.

=head1 SEE ALSO

L<Zonestat>.

=head1 AUTHOR

Calle Dybedahl, E<lt>calle@init.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Calle Dybedahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
