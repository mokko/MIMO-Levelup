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
my $my_home = '/cygdrive/c/cygwin/home/maurice/projects/Own/MIMO-Levelup';
my $xsl='C:\cygwin\home\maurice\projects\Own\MIMO-Levelup\lib\Lvl2-Updater.xslt2.xsl';

my $tmp_dir = dir( $my_home, 'lib', 'temp' );
if ( !-d $tmp_dir ) {
	mkdir $tmp_dir or error "Can't make temp dir!";
}

my $tmp_file=file( $tmp_dir, 'mpxjoiner.tmp' );

=head1 DESCRIPTION

joinmpx.pl -v A.mpx B.mpx AB.mpx 

We don't do validation at the moment!

=cut

#basic input sanity
error "Need a file for a join" if ( !$ARGV[0] );
error "1st file not found" if ( !-e $ARGV[0] );
error "Location of 1st file found, but not a file"
  if ( -e $ARGV[0] && !-f $ARGV[0] );
error "Need 2nd file for a join" if ( !$ARGV[1] );
error "Second file not found" if ( !-e $ARGV[1] );
error "Location of 2nd file found, but not a file"
  if ( -e $ARGV[1] && !-f $ARGV[1] );
error "Need destination for joined mpx file" if ( !$ARGV[2] );

#could warn if output overwritten
#or something is joined with itself which should be harmless


copy( $ARGV[1], $tmp_file)
  or die "can't copy 2nd file to tmp location";

#could output the path of used transformation in verbose
#todo: could use File::ShareDir

# 1) copy B.mpx to fixed location, e.g. temp/join.mpx
# 2) execute saxon
# 3) write result to new file

my $cmd = "$java -Xmx512m ";
$cmd .= "-jar '$saxon_location' ";
$cmd .= "-s:$ARGV[0] ";
$cmd .= "-xsl:'$xsl' ";          #needs win path
$cmd .= "-o:$ARGV[2]";               #does NOT need win path

verbose $cmd;
system($cmd);

# 4) remove the temp file
unlink $tmp_file  or warn "Can't delete tmp file";



sub error {
	my $msg = shift || '';
	print 'Error: ' . $msg . "!\n";
	exit 1;    #assuming that is an error code
}

sub verbose {
	my $msg = shift | '';
	if ( $opts{v} ) {
		print "$msg\n";
	}
}
