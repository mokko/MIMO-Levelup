#!/usr/bin/perl

use strict;
use warnings;
use Image::Magick;
use Getopt::Std;
sub verbose;

#little test script to learn Image::Magick
#transform one image (presumably a tif) specified on command line
#to a jpg which conforms to MIMO requirements (also from cl)

#MIMO jpg requirements
#longest side not bigger than 800px
#smaller files remain as they are a warning is created
#sharpen
#brighten

#options with options (dash)
getopts( 'hv', \%main::opts );

if ( $main::opts{h} ) {
	system "perldoc \"$0\"";
	exit 0;
}

#
#some sanity checks on cl input
#

if ( !$ARGV[0] ) {
	print "Error: Specify input file!\n";
	exit 0;
}

if ( !-e $ARGV[0] && -d $ARGV[0] ) {
	print "Error: Specified input file does not exist!\n";
	exit 0;
}

if ( !$ARGV[1] ) {
	print "Error: Specify output file!\n";
	exit 0;
}

if ( -e $ARGV[1] ) {
	print "Warning: Output file exists already. Will be overwritten!\n";
}

verbose "DEBUG: INPUT $ARGV[0]\n";
verbose "DEBUG: OUTPUT $ARGV[1]\n";

#
# MAIN: VARIOUS IMAGE MANIPULATIONS
#

#1 LOAD IMAGE

my $p = new Image::Magick;
$p->Read( $ARGV[0] );    #or die "Error: Cannot load input file ($ARGV[0])";

#2 RESIZE IMAGE if necessary
$p->main::Resize;

#3 NORMALIZE

$p->Normalize( channel => 'All' );    #Tonwertspreizugn

#4 MORE CONTRAST
$p->Contrast( sharpen => 'True' );

#autogamma and autolevel seem not to be implemented in perl at first sight
#$p->Modulate(channel=>'all');


#
# SAVE AND QUIT
#

#write file
$p->Write( $ARGV[1] );    #or die "Error: Cannot write input file";

exit;

#
# SUBS
#

sub verbose {
	my $message = shift;
	if ( $main::opts{v} ) {
		print "$message";
	}
}

sub Resize {
	my $p = shift;
	my ( $width, $height ) = $p->Get( 'width', 'height' );
	verbose "Height:$height\n";
	verbose "Width:$width\n";
	if ( $height >= 800 or $width >= 800 ) {

		#resize only if image bigger than 800 px in any direction
#		$p->AdaptiveResize( geometry => '800x800', blur => '-20' );
		$p->AdaptiveResize( geometry => '800x800');
		return $p;
	} else {
		print "Warning: Image is smaller than 800px on both sides\n";
	}

#alternative way of resizing
#$p->Sample(geometry=>'800x800');


}

=head1 NAME

test2jpg.pl - Convert one image to jpg which is formated according MIMO jpg specifaction.

=head1 USAGE

test2jpg.pl [-v] INPUT OUTPUT
test2jpg.pl -h help text (this text)

=head1 DESCRIPTION

A little script to test Image::Magick. Converts one image file to a jpg according
to MIMO specification (see below).

-v verbose

=head1 SPECIFICATION

Perform a resize. Not bigger than 800 px on longest side. If original image is smaller
print a warning.

Sharpen

Normalize


=cut

