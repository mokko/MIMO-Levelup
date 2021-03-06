#!/usr/bin/perl
#NAME: joinmpx.pl
#ABSTRACT: join 2 mpx files
use strict;
use warnings;
use Getopt::Std;
use File::Copy;
use Path::Class;

sub verbose;
sub error;
our %opts;
getopts( 'v', \%opts );

#TODO: should be in configuration file
my $saxon_location = 'C:\cygwin\home\maurice\usr\levelup\lib\saxon9he.jar';
my $java           = '/cygdrive/C/Program\ Files/Java/jre7/bin/java.exe';

#my $my_home = '/cygdrive/c/cygwin/home/maurice/projects/Own/MIMO-Levelup';
my $fixxsl =
  'C:\cygwin\home\maurice\projects\Own\MIMO-Levelup\lib\mpx-fix.xsl';
my $sortxsl =
  'C:\cygwin\home\maurice\projects\Own\MIMO-Levelup\lib\mpx-sort.xsl';

=head1 DESCRIPTION

fixmpx.pl -v A.mpx     #creates A.fix_sort.mpx 

We don't do validation at the moment!

=cut

#basic input sanity
error "Need a file to fix" if ( !$ARGV[0] );
error "file not found" if ( !-e $ARGV[0] );
error "Location of 1st file found, but not a file"
  if ( -e $ARGV[0] && !-f $ARGV[0] );

my $output = $ARGV[0];
$output =~ s/\.\w+$//;
$output =~ s/\.fix$//;
$output .= '.fix_sort.mpx';

verbose "will write to $output";

#could warn if output overwritten
#or something is joined with itself which should be harmless

#could output the path of used transformation in verbose
#todo: could use File::ShareDir

# 1) copy B.mpx to fixed location, e.g. temp/join.mpx
# 2) execute saxon
# 3) write result to new file

my $cmd = "$java -Xmx512m ";
$cmd .= "-jar '$saxon_location' ";
$cmd .= "-s:$ARGV[0] ";
$cmd .= "-xsl:'$fixxsl' ";           #needs win path
$cmd .= "-o:$output";               #does NOT need win path

verbose $cmd;
system($cmd);

$cmd = "$java -Xmx512m ";
$cmd .= "-jar '$saxon_location' ";
$cmd .= "-s:$output ";
$cmd .= "-xsl:'$sortxsl' ";           #needs win path
$cmd .= "-o:$output";               #does NOT need win path

verbose $cmd;
system($cmd);


sub error {
	my $msg = shift || '';
	print 'Error: ' . $msg . "!\n";
	exit 1;                          #assuming that is an error code
}

sub verbose {
	my $msg = shift | '';
	if ( $opts{v} ) {
		print "$msg\n";
	}
}
