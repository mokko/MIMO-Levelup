#Version:0.3 -11/26/07
#        0.1 -11/00/07 not yet tested in real life circumstances
use lib "D:/perl/lib";
use lib "D:/perl/site/lib";
use strict;
use warnings;
use Getopt::Std;
use XML::LibXML;
use File::Copy;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Encode 'from_to', 'decode', 'encode';
binmode( STDOUT, ":encoding(cp437)" ) if $^O eq 'MSWin32';

my $schemaFile = "museumdat-v1.0.xsd";

############################
# 1. COMMNAND LINE OPTIONS #
############################
my %opts;
getopts( 'i:ho:Ovz:', \%opts );

if ( $opts{h} ) {
	system "perldoc \"$0\"";
	exit 0;
}

unless ( $opts{i} ) {
	die "Error: Input file not specified!\n";
}

unless ( -f $opts{i} ) {
	die
"Error:  Parameter for input file (-i) does not point to file ($opts{i}) !\n";
}

unless ( $opts{o} ) {
	warn "Warning: No Output File is specified, assume o.xml!\n";
	$opts{o} = "o.xml";
}

if ( $opts{z} ) {
	print "Resources are copied to ZIP file!\n";
	if ( $opts{z} eq '' ) {
		warn "Warning: No ZIP File is specified, assume o.zip!\n";
		$opts{z} = "zip.xml";
	}
}

##################################################
# 2. Read mdat file, parse, rewrite linkResource #
#    and write back to file                      #
##################################################

#Read and parse Museumdat XML
my $parser = XML::LibXML->new();
my $tree   = $parser->parse_file( $opts{i} );
my $root   = $tree->getDocumentElement;

#DEBUG Encoding
#print "Encoding:" . $tree->encoding() . "\n";
#print "ActualEncoding:" . $tree->actualEncoding() . "\n";

my $i = 0;    # counter für museumdat Datensätze

my $zip = Archive::Zip->new();

foreach my $record ( $root->findnodes('museumdat:museumdat') ) {

#Quick and dirty
# ich nehme an, dass nur ein resourceID und ein Linkresource pro Sammlungsobjekt existiert!
	my @ids   = $record->getElementsByTagName('museumdat:resourceID');
	my @paths = $record->getElementsByTagName('museumdat:linkResource');

	#	print "count record$i\n";
	#	print "idsLength:". length(@ids)."\n";
	#	print "pathsLength:". length(@paths)."\n";

	my $path;    # path of resource as read from museumdat
	my $id;      # id corresponding to path

	if ( $ids[0] && $paths[0] ) {
		$id   = $ids[0]->getFirstChild->getData;
		$path = $paths[0]->getFirstChild->getData;
	}

	#Irrationality rules!
	from_to( $path, "ISO 8859-15", "ISO 8859-15", 3 );

	#	print "Encoding: Path" . $record->encoding() . "\n";
	#	print "ActualEncoding: Path" . $record->actualEncoding() . "\n";

	if ( $path && $id ) {
		my @suffix = split( /\./, $path );
		my $suffix = $suffix[-1];

		# this determination of suffixes is quite weak!
		#		print "Suffix:$suffix\n";
		my $newname = "$id.$suffix";

		print '.';

		#print "$path -------------------> $newname\n\n";    #LONG DEBUG

		unless ( $opts{O} ) {
			if ( $opts{z} ) {

				# Add a file from disk
				#addFile( $fileName [, $newName ] )
				my $file_member = $zip->addFile( $path, $newname )
				  or die "Problem with adding file to zip!($path)\n";
			}
			else {
				copy( $path, "$newname" )
				  or die "Error: Could not copy file $! !";
			}
		}
		foreach my $imagelink (
			$record->findnodes(
'museumdat:administrativeMetadata/museumdat:resourceWrap/museumdat:resourceSet/museumdat:linkResource'
			)
		  )
		{

			#tested only with one imagelink per resourceSet!
			my $newTextNode = $tree->createTextNode($newname);
			my $childnode   = $imagelink->firstChild;
			$imagelink->replaceChild( $newTextNode, $childnode );
		}
	}
	$i++;
}    # end of record-loop

# writte the new XML
$root = $tree->toFile( $opts{o}, 0 );

unless ( $opts{O} ) {

	# write ZIP to file
	print "About to write ZIP\n";
	if ( $opts{z} ) {
		unless ( $zip->writeToFileNamed( $opts{z} ) == AZ_OK ) {
			die 'ERROR: writing zip';
		}
	}
}
##########################
# 3. VALIDATE RESULT XML #
# only if -v option      #
##########################
if ( $opts{v} ) {
	print "About to validate new museumdat file!\n";
	print "schema found\n" if ( -e $schemaFile );
	my $xmlschema = XML::LibXML::Schema->new( location => $schemaFile );

	#$xmlschema->validate($tree);

	eval { $xmlschema->validate($tree); };
	if ($@) {
		print "Warning: Does NOT validate\n";
	}
	else {
		print "does validate\n";
	}

}

__END__


=head1 NAME

cpMdatResources - copy rename and adopt linkResources mentioned in a museumdat document  

=head1 DESCRIPTION

This little script 

 1. expects a museumdat for input (-i FILE), 
 
 2. looks up local paths for museumdat:linkResource, 
 
 3. copies these resource to the local directory (pwd) 
 
 4. using their identifier (museumdat:resourceID) in the filesystem as a new filename.
 
 5. Furthermore, it adopts the path in museumdat:linkResource accordingly (i.e. to the new name)
 
 6. and it writes the updated XML to specified file (-o FILENAME) or "o.xml" if nothing is specified.

=head1 COMMAND LINE OPTIONS

=head2 -i FILE       		

expects input museumdat file name 

=head2 -h    

displays this help

=head2 -o FILE				

expects the name of the outputfile. If nothing specified then "o.xml" is assumed.

=head2 -O 

turns off the copying or zipping and just changes the museumdat file. 


=head2 -v 

Validate document against schema file. Reports yes or no. For error messages use separate script.


=head1 DEPENDENCIES
$0 requires libxml. 

If you use ActiveState Perl it should be easiest to get it by installing it from
ppm install http://theoryx5.uwinnipeg.ca/ppmpackages/XML-libXML.ppd

=head1 AUTHOR

Maurice Mengel <m.mengel@smb.spk-berlin.de> for ethnoArc (www.ethnoArc.org) 

=head1 COPYRIGHT

Copyright 2007 Maurice Mengel

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

