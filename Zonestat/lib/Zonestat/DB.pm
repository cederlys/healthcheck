package Zonestat::DB;

use strict;
use utf8;
use warnings;

use base 'Zonestat::Common';
use Carp;

sub new {
    my $class  = shift;
    my $parent = shift;
    my $self   = $class->SUPER::new( $parent );
    $self->{name} = shift;

    $self->initialize;

    return $self;
}

sub name {
    my $self = shift;

    return $self->{name};
}

sub db {
    my $self = shift;
    my $name = shift || $self->name;

    return $self->SUPER::db( $name );
}

sub initialize {
    my $self  = shift;
    my $ddocs = $self->db->listDesignDocs;

    foreach my $ddoc ( @{$ddocs} ) {
        $ddoc->retrieve;
        my $docname = $ddoc->id;
        $docname =~ s|_design/||;
        foreach my $view ( $ddoc->listViews ) {
            $self->{ $docname . '_' . $view } = sub {
                return $ddoc->queryView( $view, @_ );
              }
        }
    }

    return;
}

our $AUTOLOAD;

## no critic (Subroutines::RequireArgUnpacking)
sub AUTOLOAD {
    my $self = shift;
    my $view = $AUTOLOAD;

    $view =~ s|^.*:([^:]+)$|$1|;
    if ( $view eq 'DESTROY' ) {
        return;
    }
    elsif ( $self->{$view} ) {

        # Do the call here instead of defining the called method, since we want the
        # methods to act like they're specific to the object.
        return $self->{$view}->( @_ );
    }
    else {
        croak "No such view: $view";
    }
}

1;
