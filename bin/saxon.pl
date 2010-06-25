#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
sub debug;

getopts( 'dht', \%main::opts );
help() if $main::opts{h};

die "Error: need exactly three cli options"
  unless ( $ARGV[0] && $ARGV[1] && $ARGV[2] );

die "Source does not exist"     unless -f $ARGV[0];
die "Stylesheet does not exist" unless -f $ARGV[1];
warn "Warning: Output exists already, will be overwritten" if -f $ARGV[2];

#debug  "Source:$ARGV[0]";
#debug  "XSL:$ARGV[1]";
#debug  "OUTPUT:$ARGV[2]";
$ARGV[1] = `cygpath -wa $ARGV[1]`;

#$ARGV[2]=`cygpath -wa $ARGV[2]`;
$ARGV[1] =~ s/\s+$//;
debug "XSL:$ARGV[1]";

#
#configure this script here
#
my $cmd = 'java -Xmx256m ';
$cmd .= "-jar 'C:\\Program Files\\saxon\\saxonhe9-2-0-6j\\saxon9he.jar' ";
$cmd .= "-t  " if $main::opts{t};
$cmd .= "-s:$ARGV[0] ";
$cmd .= "-xsl:'$ARGV[1]' ";    #needs win path
$cmd .= "-o:$ARGV[2]";

debug "DEBUG:$cmd";
system($cmd);

if ( $? == -1 ) {
	die "Error: failed to execute system: $!\n";
}
elsif ( $? & 127 ) {
	printf "saxon died with signal %d, %s coredump\n", ( $? & 127 ),
	  ( $? & 128 ) ? 'with' : 'without';
}
else {
	printf "saxon exited with value %d\n", $? >> 8;
}

exit;

sub debug {
	my $message = shift;
	if ( $main::opts{d} ) {
		die "DEBUG without message" unless $message;
		print "$message\n";
	}
}

sub help {
#	print "Usage: saxon.pl some-source.xml some-xsl.xsl some-output.xml\n";

	system ("perldoc $0");
	exit 0;
}

=head1 NAME

saxon.pl - execute saxon somewhat easily from under cygwin

=head1 USAGE

saxon.pl [-t|-v] sourcefile.xml transformation.xsl output.xml

saxon.pl -h

=head1 DESCRIPTION

Execute saxon command line from under perl

=head1 COMMAND LINE OPTIONS

-d output debug info while executing

-h display this help

-t saxon's -t function (display time info)

=head1 BACKGROUND

Saxon is great, but it is not particularly easy to use it form perl at the moment. Cygwin is great, but to execute java per command line from under cygwin requires windows paths. This script is a simplistic quick fix to this problem.

