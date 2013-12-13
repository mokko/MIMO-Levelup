#!/usr/bin/perl
# RTFTABLE2XML
# converts tables in an rtf file to xml
# see help section below

#
# HISTORY BUG FIX
#

#v13: adds another kind of newline /par and correct old /\r
#v12: adds Term:Activity
#v11: adds attribute exportdatum to sammlungsobjekt, personKoerperschaft etc. with
#creation date of rtf-file (for update purposes)
#v10: Fixed the charset problem that appeared with e with accent graph. If have
#to use cp1252 instead of iso-8859-2!
#v9: this version should avoid the backslash problem.


################
# PREPARATIONS #
################
use strict;
use warnings;
use encoding "UTF-8";
use Encode 'from_to';
use Getopt::Std;
use RTF::Lexer qw(:all);
use Term::Activity;
use Date::Manip;
use SOAP::DateTime;

use constant CWORD => 256;
use constant CSYMB => 257;
use constant CUNDF => 258;
use constant CPARM => 259;
use constant CNOPR => 260;
use constant PTEXT => 261;
use constant ENTER => 262;
use constant LEAVE => 263;
use constant DESTN => 264;
use constant ENHEX => 265;
use constant ENBIN => 266;
use constant WRHEX => 268;
use constant OKEOF => 300;
use constant UNEOF => 301;
use constant UNBRC => 302;

my %position = (
	CELL_NO    => 0,                     # number of current cell in a row
	CSYMB      => 0,                     # counter for unresolved CSYMBs
	DOCROOT    => 'museumPlusExport',    # default
	IN_CELL    => 0,                     # inside a cell or not
	INDEX      => 'kueId',               # use named field as index for ITEM tag
	IN_TABLE   => 0,                     # inside a table or not
	ITEM       => 'item',                # default for item tag
	ROW_NO     => 0,                     # number of rows inside a table
	UNICODE    => 0,                     # to jump over the hex after an unicode
	EXPORTDATE => ''
);

my $VERSION = 11;                        # see below

my $token;       # reference to an array
my $cell_buffer; # add up all cell content (text, char, symbols?)
my @headings;    # headings of rtf table corresponding with xml tag names
my %row_buffer;  # store the contents of a rtf row (corresponding to a xml item)
                 # before outputting


#
# COMMAND LINE PARAMS
#

my %opts;
getopts( 'd:ef:hi:I:lm:o:Sv:', \%opts );

verbose( "1st step: Processing command line parameters...\n\n", 2 );

if ( $opts{d} ) {

	#TODO Error checking
	$position{'doc_root'} = $opts{d};
}

if ( $opts{e} ) {
	verbose( "Print even empty tags (-e)!\n", 2 );
}

if ( $opts{h} ) {
	system "perldoc \"$0\"";
	exit 0;
}

unless ( $opts{f} ) {
	die "Error: input file not specified!\n";
}

if ( $opts{i} ) {

	#TODO Error checking
	$position{'ITEM'} = $opts{i};
}
else {
	verbose(
		'No record separator is specified (-i). Using default ('
		  . $position{'ITEM'} . ")!\n",
		2
	);
}

if ( $opts{I} ) {
	$position{'INDEX'} = $opts{I};
	verbose(
		"Using '$position{'INDEX'}' as index in <$position{'ITEM'}>(-I)!\n",
		2 );
}
else {
	verbose( "NOT using index in <$position{'ITEM'}> (-I)!\n", 2 );
}

if ( exists $opts{l} ) {
	verbose( "add attribute exportdatum\n", 2 );
}

# -m<apping> switch stuff
my %mapping;

#-m switch exists, but no file is specified
if ( exists( $opts{m} ) && not defined( $opts{m} ) ) {
	my $href = default_mapping();
	%mapping = %$href;
}

#-m switch exists, but no file is specified
if ( defined( $opts{m} ) && ( $opts{m} eq '' ) ) {
	my $href = default_mapping();
	%mapping = %$href;
}

if ( defined( $opts{m} ) && ( $opts{m} ne '' ) ) {

	#overwrite default mapping
	verbose( "Load config file for mapping ($opts{m})!\n", 2 );

	{

		package Settings;
		do $opts{m} or die "Error: Can't load mapping file!\n";
	}

	foreach my $key ( keys %Settings::mapping ) {
		my $value = $Settings::mapping{$key};
		verbose( "-$key --> $value\n", 2 );
	}
	%mapping = %Settings::mapping;
}

#end of -m param

unless ( $opts{o} ) {
	$opts{o} = "output.xml";
	verbose( "No output file is specified (-o). Default is used ($opts{o})!\n",
		2 );
}

if ( $opts{S} ) {
	verbose( "Sorting function DE-activated (-S)!\n", 2 );
}

if ( exists( $opts{v} ) && not defined( $opts{v} ) ) {
	$opts{v} = 1;
	verbose(
		"Verbose specified, but without level. "
		  . "Using default level:$opts{v}!\n",
		2
	);
}
if ( defined( $opts{v} ) && $opts{v} !~ /[1-6]/ ) {
	$opts{v} = 1;
	verbose(
		"No intelligable verbose level is specified (-v). "
		  . "Using default level:$opts{v}!\n",
		2
	);
}

#
# Prepare Input and Output File (handles)
#

verbose( "2st step: Prepare file handles and parser ...\n\n", 2 );
my $parser = RTF::Lexer->new( in => $opts{f} );

my $rw = open( OUT, "> :encoding(UTF-8)", $opts{o} )
  or die "Error opening output file: $!\n";

#open( DEBUG, "> :encoding(UTF-8)", "debug.txt" )
#  or die "Error opening DEBUG file: $!\n";

#
# Prepare Progress Bar
#
my $start_time = time;
my $ta         = new Term::Activity(
	{
		label => $opts{f},
		time  => $start_time
	}
);

#
# Prepare Time for @EXPORTDATE
#

$main::TZ = "CET"; #avoid annoying perl warning in a stupid way
$main::TZ = "CET";
my $mtime = ( stat $opts{f} )[9];
$mtime = ParseDateString("epoch $mtime");

$position{'EXPORTDATE'} = ConvertDate($mtime);    # now in XSD DateTime Format!

#################
# START PARSING #
#################

start_parsing( \%position, *OUT );

# this do-loop goes thru every token I get back from the lexer
do {
	$token = $parser->get_token();
	my ( $id, $string, $control ) = @$token;
	from_to( $string, "cp1252", "UTF-8" );

	#
	# CSYMB
	#
	if ( $id eq CSYMB ) {
		verbose( "CSYMB encountered:$string!\n", 6 );

		# i need this for the backslash in windows paths!
		# check if this also is needed for \par newlines
		# print STDERR "check for par:id:/$id/$string/\n";

		# I resolved rtf reference with star and the carriage return!
		$position{CSYMB}++ if ( $string !~ m/\r|\*/ );

		$string =~ s/\r/\n/;
		warn "Still \\r left\n" if ( $string =~ m/\r/ );
		$cell_buffer .= $string;

	}

	#
	# ENHEX
	#
	if ( $id eq ENHEX ) {
		if ( $position{UNICODE} == 1 ) {
			verbose(
				"ENHEX occured, but I skip it because right after unicode\n",
				3 );
			$position{UNICODE} = 0;
		}
		else {
			verbose(
				"ENHEX occured: $string (position:$position{'IN_CELL'})!!\n",
				3 );
			$position{CSYMB}--;    # resolved one CSYMB!

			if ( $position{IN_CELL} == 1 ) {

				#use charnames qw(:full);
				my $dec = hex($string);

				#my $octal=oct('0x'.$_[1]);
				#my $charname = charnames::viacode($octal);

				my $char = chr($dec);

	 #print STDERR "WARNING: Char: $dec -- $_[1] '$char' ($charname)\n";   #TODO

				$cell_buffer .= $char;
			}
		}
	}

	#
	# WRHEX
	#
	if ( $id eq WRHEX ) {
		warn "WRHEX occured: $string!\n";
	}

	if ( $id eq CUNDF ) {
		warn "CUNDF occured!";
	}

	#
	# PTEXT 261 --> Bit and pieces of text inside a cell
	#
	if ( $id eq PTEXT ) {
		$cell_buffer .= $string if ( $position{IN_CELL} == 1 );
	}

	#
	# CONTROL WORDS
	#

	if ( $id eq CWORD ) {

	  #
	  # CELL (CWORD256) --> End of cell
	  #
	  # \cell always terminates a cell, but
	  # \cell may also appear in \trowd context and not only to terminate a cell
	  # \cell may also end and start a new cell in some RTF
		if ( $string eq 'cell' ) {
			if ( $position{IN_CELL} gt 0 ) {
				cell_completed( \%position, $cell_buffer );
				$cell_buffer = "";
			}

			#update position
			$position{IN_CELL} = 0;
		}

		#
		# HICH (CWORD)
		#
		if ( $string eq 'hich' ) {
			warn "WARNING: \\hich cword occured! I did not test this script "
			  . "successfully with this control word!\n";
		}

		#
		# INTBL (CWORD) --> Enter (next) cell
		#
		if ( $string eq 'intbl' ) {
			$position{IN_CELL} = 1;
			$position{CELL_NO}++;

			verbose( "Enter cell $position{CELL_NO}!\n", 3 );
		}

		#
		# ROW (CWORD)
		#
		if ( $string eq 'row' ) {
			if ( $position{IN_TABLE} ) {
				$position{CELL_NO} = -1;    # don't know whhhyy...
				row_completed( \%position, \%row_buffer, \@headings );
				%row_buffer = ();           # this can be done better!
			}
		}

		#
		# TROWD(CWORD) --> Enter (next) table and row
		#
		if ( $string eq 'trowd' ) {
			unless ( $position{IN_TABLE} == 1 ) {

				# EVENT: Enter table!
				$position{IN_TABLE} = 1;
				verbose( "Enter table!\n", 3 );
			}

			# EVENT: Enter next row!
			$position{ROW_NO}++;
			verbose( "Enter row no $position{ROW_NO}!\n", 3 );
		}

		#
		# U control word for unicode
		#
		if ( $string eq 'u' ) {
			verbose( "WARNING: cword \\u occured:" . "$string$control-!\n", 2 );
			if ( $position{IN_CELL} == 1 ) {
				my $char = chr($control);
				$cell_buffer .= $char;
			}
		}    #eof cword u

		#
		# PAR control word for line break
		#
		if ( $string eq 'par' ) {
			if ( $position{IN_CELL} == 1 ) {
				verbose( "WARNING: cword \\par occured in a cell!\n", 6 );
				$cell_buffer .= "\n";
			}
		}

		#jump over the next hex 'cause our rtf has a unnecessary hex
		#following every unicode: e.g. \u32645\'3f
		$position{UNICODE} = 1;

	}    # eof whole cword section
} until $parser->is_stop_token($token);

stop_parsing( \%position, *OUT );
exit 0;
##################################
# EVALUTATE PARSING EVENTS       #
# and other subs (alphabetically)#
##################################

sub cell_completed {

	#this sub is called whenever a cell is completely read into the cell_buffer
	my ( $href_position, $complete_cell ) = @_;
	my %position = %$href_position;

	#	print DEBUG $complete_cell."\n";
	#	print STDERR $complete_cell."\n";
	verbose(
		"cell completed (row_no:$position{ROW_NO}"
		  . "; cell_no:$position{CELL_NO}:$complete_cell)!\n",
		4
	);

	if ( $position{ROW_NO} == 1 ) {

		#table headings
		#in case of -m switch, try to map it
		if ( exists $opts{m} ) {

			if ( exists $mapping{$complete_cell} ) {
				verbose(
					"Mapping from \"$complete_cell\" to ... "
					  . $mapping{$complete_cell} . "!\n",
					2
				);
				$complete_cell = $mapping{$complete_cell};
			}
			else {
				warn "WARNING: Mapping failed for '$complete_cell'\n";
			}
		}

		if ( $complete_cell =~ m/_|\s|\// ) {
			die "Error: Table headings include invalid xml tag name:"
			  . "$complete_cell!\n"
			  . "Tip: Map the table headings to proper xml tags (using -m FILE).\n";
		}
		if ( $complete_cell ne '' ) {
			push @headings, $complete_cell;
		}
	}
	else {

		# if not first row anymore, write current cell to row_buffer
		# the following line is sometimes problematic, because with certain
		# RTF that I do not know well, the headings do not work properly!
		# The script should not be so error prone
		if ( exists( $row_buffer{ @headings[ $position{CELL_NO} ] } ) ) {
			die "Error: Table headings in RTF input file are not unique!\n";

			# if not unique tests inside this script won't work. If
			# this is a problem, i could fallback to an approach that
			# takes the order of columns into account. It is really
			# any better?
		}
		$row_buffer{ @headings[ $position{CELL_NO} ] } = $complete_cell;
	}
}

sub default_mapping {

	#DEFAULT Mapping
	#   RTF  									=> xml
	my %mapping = (
		"Anzahl Teile"              => "anzahlTeile",
		"AndereNr"                  => "andereNr",
		"Bemerkung / Sammlung"      => "bemerkungSammlung",
		"Besetzung"                 => "besetzung",
		"Digitalisiert"             => "digitalisiert",
		"GeoBezug"                  => "geobezug",
		"Ident_ Nr_"                => "identNr",
		"Inhalt"                    => "inhalt",
		"Kategorie/ Genre"          => "kategorieGenre",
		"Kurze Beschreibung"        => "kurzeBeschreibung",
		"Lange Beschreibung"        => "langeBeschreibung",
		"Maßangaben"             => "maßangaben",
		"MatTech"                   => "materialTechnik",
		"multimediaMulId"           => "mulId",
		"Multimedia"                => "multimedia",
		"Musikgattung"              => "musikgattung",
		"Objektbezüge"           => "objektbezug",
		"Objekttyp"                 => "objekttyp",
		"Obj_ Id"                   => "objId",
		"PersonenKörperschaften" => "personKörperschaft",
		"Sachbegriff"               => "sachbegriff",
		"SystematikArt"             => "systematikArt",
		"Technische Bemerkung"      => "technischeBemerkung",
		"Text Original"             => "textOriginal",
		"Titel"                     => "titel",
		"Verwaltende Institution"   => "verwaltendeInstitution",
	);
	verbose( "Use default mapping!\n", 2 );
	return \%mapping;
}

sub print_XML_tag {
	my ( $tag, $value, $fh ) = @_;
	my $print = 0;

	#trim value
	#$value =~ s/^\s+//;
	#$value =~ s/\s+$//;

	#decide according to -e and emptyness of string if tag should be printed
	if ( $opts{e} ) {

		#print even if tag is empty
		$print = 1;
	}
	else {

		#print only if there is value
		$print = 1 if ($value);
	}

	#print or not to print
	if ( $print == 1 ) {
		print $fh "      <$tag><![CDATA[$value]]></$tag>\n";
	}
}

sub row_completed {

	# this sub is called when during parsing someone decides
	# that a row of a table is completed
	# it expects three params as input
	# as output it the delivers row_buffer to OUT in some kind of XML
	# and deletes the row_buffer
	# a single row in rtf is translated to an item element with many subelements
	# some command line options affect the behavior of this sub
	# -l prints exportdate per item, otherwise not printed
	# -S turns off alphabetical sorting of subelements
	my ( $href_position, $href_row_buffer, $href_headings ) = @_;
	my %position   = %$href_position;
	my %row_buffer = %$href_row_buffer;
	my @headings   = @$href_headings;

	if ( $position{ROW_NO} > 1 ) {

		#print row_buffer; if s flag is there, sort alphabetically,
		#if it's not there, sort according to values in @headings
		if ( $position{'INDEX'} ) {
			my $index = $position{'INDEX'};

			# Changed in early September 2007 from "die" to "warn"
			warn "Error: Problem with index ($index)!\n"
			  unless ( $row_buffer{$index} );
			if ( exists $opts{l} ) {

				#print "EXP:" . $position{'EXPORTDATE'};

				#print "2 mtime" . $mtime.":::". $mtimeXSD;

				print OUT
"   <$position{'ITEM'} exportdatum=\"$position{'EXPORTDATE'}\" $index=\"$row_buffer{$index}\">\n"
				  ;
			}
			else {
				print OUT
				  "   <$position{'ITEM'} $index=\"$row_buffer{$index}\">\n";
			}
			delete( $row_buffer{$index} );
		}
		else {
			print OUT "<$position{'ITEM'}>\n";

		}
		if ( $opts{S} ) {
			foreach my $key (@headings) {

				#print subelements
				print_XML_tag( $key, $row_buffer{$key}, *OUT );
			}
		}
		else {
			foreach my $key ( sort keys %row_buffer ) {

				#print subelements
				print_XML_tag( $key, $row_buffer{$key}, *OUT );
			}
		}
		print OUT "   </$position{'ITEM'}>\n";

		#		$progress->update(1);
		if ( exists( $opts{v} ) ) {
			print STDERR ".";
		}
		else {
			$ta->tick;
		}
	}
}

sub start_parsing {
	my ( $href_position, $fh ) = @_;
	my %position = %$href_position;

	verbose( "3st step: Start RTF parsing ...\n\n", 2 );
	print $fh '<?xml version="1.0" encoding="UTF-8"?>', "\n";

	print $fh '<', $position{DOCROOT}, ">\n";

}

sub stop_parsing {
	my ( $href_position, $fh ) = @_;
	my %position = %$href_position;

	print $fh "</$position{'DOCROOT'}>\n";
	close $fh;

	#close DEBUG;

	print STDERR "\n" if ( $opts{v} );
	verbose( "4th step: Stop RTF parsing...\n\n",                    2 );
	verbose( "All done! Total of $position{ROW_NO} item records!\n", 1 );
	verbose( "CSYMB unresolved: $position{'CSYMB'}\n",               2 );
}

sub verbose {
	my ( $msg, $msglevel ) = @_;
	if ( $opts{v} ) {
		print STDERR "-$msg" if ( $msglevel le $opts{v} );
	}
}

__END__


=head1 NAME

rtftable2xml - Convert a table within an rtf file to an xml file

=head1 DESCRIPTION

This little script expects a rtf file containing a table for input. It outputs
the contents of the table in XML. The table headings correspond to the table
headings (simply the cells in the first row). Alternatively, using the -m parameter
a mapping for the table headings can be specified that translates the table headings
to xml tags.

=head1 STABILITY

This script is tested only for the RTF that I currently work with. RTF produced
by other rtf writers is likely NOT to work correcty with this script!

=head1 ENCODINGS

This script expects the RTF file to have windows encoding for Western Europe
(ISO 8859-2) and outputs XML in UTF-8.

=head1 COMMAND LINE OPTIONS

=head2 -d DOCROOT

specify the root element of the xml document (default: museumPlusExport)

=head2 -e

Print out empty tags as well. Default behaviour is not to print out empty tags.

=head2 -f FILE

input RTF file name for the file containing the table

=head2 -h

displays this help

=head2 -i ITEM

tag name for the record separator in xml output; corresponds to a row in the rtf table (default: item)

=head2 -I INDEX

xml tag name (corresponding to rtf table heading) that should be used as an index. An index will
appear as an xml attribute in the record item.

=head2 -l

adds an attribute 'exportdatum' with the modification date (mtime) of the rtffile for each record (in item tag).

=head2 -o FILE

expects the name of the outputfile (default: output.xml)

=head2 -m FILE

Mapping file that associates the rtf table headings with corresponding xml tags.
If -m flag is not specified the script takes the rtf headings expecting that they
represent correct(!) xml tags.

If no filename is specified after m, the script takes the internal default mapping.
NB: You may have to write -m "" in the command line to achieve this effect!

If a filename is specified the script expects a config file containing the mapping.
See the default mapping for the format of the mapping file.

=head2 -S

Turn off the sorting function that sorts xml tags alphabetically (default: sort alphabetically).
(with flag).

=head2 -v LEVEL

verbose. You can specify a level of verbosity (1-6); the higher the level, the more messages, you
will get; default value is 1. It will be set automatically if you specify -v "" or similar.

=head1 OTHER STUFF

By the way: I changed from RTF::Tokenizer to RTF::Lexer to increase speed. Script runs now about 1000 times faster!

I compiled RTF::Lexer with strawberry perl and were able to use the same binary on ActiveState!

=head1 TODO

ESCAPING: HEX and unicode escaping implemented, but not tested very well!



=head1 AUTHOR

Maurice Mengel <m.mengel@smb.spk-berlin.de> for ethnoArc (www.ethnoArc.org)

=head1 COPYRIGHT

Copyright 2007, 2008 Maurice Mengel

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

This skript uses RTF::Lexer.

=cut

