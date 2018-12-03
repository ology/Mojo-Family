package WS::Model::Chat;

use strict;
use warnings;

use DateTime;
use Encoding::FixLatin qw( fix_latin );
use IO::All -utf8;

sub new { bless {}, shift }

sub lines {
    my ( $self, $file, $show ) = @_;

    # Set the number of chat lines to show
    $show ||= 100;

    my @content;

    if ( -e $file ) {
        my $counter = 0;

        my $io = io($file);
        $io->backwards;

        while( defined( my $line = $io->getline ) ) {
            last if ++$counter > $show;

            $line = fix_latin($line);

            my ( $who, $when, $what ) = ( $line =~ /^(\w+) ([T \d:-]+): (.*)$/ );

            my $formatted = sprintf '<b>%s</b> <span class="smallstamp">%s:</span> %s',
                $who, $when, $what;

            push @content, $formatted;
        }
    }

    return \@content;
}

sub format {
    my ( $self, $who, $tz, $text ) = @_;

    $text = fix_latin($text);

    # Trim the text
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    $text =~ s/\n/<br>/g;

    my $now = DateTime->now( time_zone => $tz )->ymd
        . ' ' . DateTime->now( time_zone => $tz )->hms;

    return sprintf '<b>%s</b> <span class="smallstamp">%s:</span> %s',
        $who, $now, $text;
}

1;
