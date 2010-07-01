#!/usr/bin/perl

use strict;
use warnings;
use Image::Magick;
use Getopt::Std;
use File::Find;
sub verbose;

#little test script to learn Image::Magick
#transform all tifs in a directory to jpg according MIMO requirements

#input dir via cl
#output dir via cl

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
	print "Error: Specify input directory!\n";
	exit 0;
}

if ( !-e $ARGV[0] ) {
	print "Error: Specified input directory does not exist!\n";
	exit 0;
}

if ( !-d $ARGV[0] ) {
	print "Error: Specified input file is no directory!\n";
	exit 0;
}

if ( !$ARGV[1] ) {
	print "Error: Specify output directory!\n";
	exit 0;
}

verbose "INPUT DIR $ARGV[0] (recursive)\n";
verbose "OUTPUT DIR $ARGV[1]\n";

#
#
#

find( \&each_file, $ARGV[0] );

#
# MAIN: VARIOUS IMAGE MANIPULATIONS
#

exit;

#
# SUBS
#

sub each_file {

	# work only on tif extensions
	if ( $_ =~ /\.tif$|\.tiff$/i ) {
		verbose "Found image: $_\n";
		my $output = $_;
		$output =~ s/\.tif$|\.tiff$/.jpg/i;
		$output = "$ARGV[1]/$output";
		verbose "\t-->  $output\n";

		#1 LOAD IMAGE
		my $p = new Image::Magick;
		$p->Read($File::Find::name);

		#2 RESIZE IMAGE if necessary
		$p->main::Resize;

		#3 NORMALIZE
		$p->Normalize( channel => 'All' );    #Tonwertspreizugn

		#4 MORE CONTRAST
		$p->Contrast( sharpen => 'True' );

	  #autogamma and autolevel seem not to be implemented in perl at first sight
	  #$p->Modulate(channel=>'all');

		#write file
		$p->main::Write("$output");

	}
}

sub Resize {
	my $p = shift;
	my ( $width, $height ) = $p->Get( 'width', 'height' );
	verbose "\tHeight:$height\n";
	verbose "\tWidth:$width\n";
	if ( $height >= 800 or $width >= 800 ) {

		#resize only if image bigger than 800 px in any direction
		#		$p->AdaptiveResize( geometry => '800x800', blur => '-20' );
		$p->AdaptiveResize( geometry => '800x800' );
		return $p;
	}
	else {
		print "\tWarning: Image is smaller than 800px on both sides. Keep original size\n";
	}

	#alternative way of resizing
	#$p->Sample(geometry=>'800x800');

}

sub verbose {
	my $message = shift;
	if ( $main::opts{v} ) {
		print "$message";
	}
}

sub Write {
	my $p      = shift;
	my $output = shift;
	print "GET HERE with $output\n";
	if ( -e $output ) {
		print "\tWarning: File exists. Will be overwritten!\n";
	}
	$p->Write($output);
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

