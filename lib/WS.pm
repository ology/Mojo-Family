package WS;

use strict;
use warnings;

sub new { bless {}, shift }

sub defang {
    my ($self, $arg) = @_;

    if ( ref($arg) eq 'HASH' ) {
        for ( keys %$arg ) {
            $arg->{$_} = _defang($arg->{$_});
        }
    }
    elsif ( ref($arg) eq 'ARRAY' ) {
        for ( @$arg ) {
            $_ = _defang($_);
        }
    }
    else {
        $arg = _defang($arg);
    }

    return $arg;
}

sub _defang {
    my ($string) = @_;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
}

1;
