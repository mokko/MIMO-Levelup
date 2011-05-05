#!/usr/bin/perl

#this shall become a utility that creates mpx mume records from
#files. The records are faked or virtual since they have not been entered
#in M+. The purpose is to save time entering the data. In general data
#that is entered manually can be better, so this is considered only a preliminary
#hack.

#1)read in config file
#2)scan a directories specifid in config for media files
#  do not check if files describe instruments etc. Everything that
#  the is recognized by the dir-parser is considered
#2.1)probably config also specifies which way the directories are read
#3) parse most recent mpx file
#4) try to match ident nr from dir_parser and from mpx
#   exclude media that cannot be identified
#   I probably want to log this
#5) test if media from dir is already indexed in mume records
#   do this by comparing file path as identity check
#   do not engage in more complex identity checks

#package link::mume;
#mpx_mume_fimporter
use utf8;
use strict;
use warnings;
use File::Copy;
use File::Find;
use Getopt::Std;
use XML::LibXML;
use XML::LibXML::XPathContext;

#pre-declare
sub findByCriterion;

###OLD NOTES

#the idea is to scan directories for media and add appropriate metadata to a
#mpx file
#this is rather complex operation

#1) The identNr of the related sammlungsobject needs to be part of the filename.
#   I need to parse filenames for ident.Nr.
#   Act only on files where a identNr can be identified
#2) Parse mpx file
#2.1) Only act if identNr from filename is found in mpx file
#2.2) Check if that file is already entered
#     by comparing full path from mpx and from file
#3) Create and add a fake multimedia record in the mpx file
#3.1) How to make a fake mulId? mpx-lvl2 specifies that mulId has to be an integer,
##    so I will make it a super huge integer: 100.000.000
##    how can i make sure that I don't create the same index twice?
##    I have to have some kind of memory. Maybe I keep all the fake
##    records and check against them
#4) Add a reference to this mume-record in sammlungsobjekt.

#use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

#
#1 CONFIG
#
my %config = (
	mpx_fn       => "/home/Mengel/M+Export/MIMO/4-lvl2/2join.lvl2.mpx",
	index_offset => "100000000",
	1            => {
		parser => 'parse_78',
		path   => '/cygdrive/M/MuseumPlus/Produktiv/Multimedia/EM/'
		  . 'Medienarchiv/Produktiv/VII_78',
		constant_fields => {

			#exact list of constant fields is not fixed and can vary
			multimediaAnfertDat     => "2010",
			multimediaFarbe         => "farbig",
			multimediaPerkor        => "Rainer Hatoum",
			multimediaTyp           => "Digitale Aufnahme",
			multimediaUrhebFotograf => "Andrea Blumtritt",
		},
		2 => {
			parser => 'parse_rainer',
			path   => '/cygdrive/M/MuseumPlus/Produktiv/Multimedia/EM/'
			  . 'Medienarchiv/Produktiv/VII_78',
			constant_fields => {

				#exact list of constant fields is not fixed and can vary
				multimediaAnfertDat     => "2010",
				multimediaFarbe         => "farbig",
				multimediaPerkor        => "Rainer Hatoum",
				multimediaTyp           => "Digitale Aufnahme",
				multimediaUrhebFotograf => "Andrea Blumtritt",
			},
		},
	}
);

#
# 2) SCAN DIRS (TODO)
#

my $file_map_path = simulate_dir_scan();
my %file_map_path = %$file_map_path;

#convert the other way around
#this doesn't work. Since each identNr can have several paths
#maybe it is better to search for it when I need it.
my %file_map_identNr;
my @file_map;
foreach my $path ( keys %file_map_path ) {
	my $identNr = $file_map_path{$path};
	push (@file_map, $identNr);
	$file_map_identNr{$identNr} = $path;
}

#my %file_map;    #
#foreach ( 1 .. 2 ) {

#	print "Call $config{$_}{parser}($config{$_}{path})\n";
#	no strict;

#call the sub mentioned in config{$_}{parser}
#	my $file_map_ref = $config{$_}{parser}( $config{$_}{path} );
#	use strict;

#	%file_map = %$file_map_ref;

#	foreach my $record ( $root->findnodes('mpx:museumPlusExport') ) {
#   mpx:museumPlusExport/mpx:sammlungsobjekt/mpx:identNr
#	}
#	my @identNr;

#debugging
#	my $identNr = "IV Ca 32015";

#	foreach my $path ( keys %file_map ) {
#		my $identNr = $file_map{$path};

#		foreach my $link (
#path2 probably doesn't work: mpx:museumPlusExport/[mpx:identNr eq '$identNr' ]
#		@identNr=$record->findnodes(	"mpx:museumPlusExport/[mpx:identNr eq '$identNr' ]"
#			) ;
#		}
#	}
#}

#
# 3) PARSE MPX
#

die "Cannot find mpx file" unless ( -f $config{mpx_fn} );

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_file( $config{mpx_fn} );
my $xpc    = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs( 'mpx', 'http://www.mpx.org/mpx' );

#my $root = $doc->getDocumentElement;

#
# 3.1) check if identNr from file corresponds with mpx-db
#

#print $xpc->findvalue("/mpx:museumPlusExport/mpx:sammlungsobjekt/IdentNr" );



my @nodes =
  $xpc->main::findByCriterion( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
	'identNr', @file_map );

foreach (@nodes) {
	print "DD: " . $_->string_value() . "\n";
}

exit;

foreach
  my $node ( $xpc->findnodes("/mpx:museumPlusExport/mpx:sammlungsobjekt") )
{

	#works
	my @identNr_mpx = $node->getElementsByTagName('identNr');
	foreach my $identNr_mpx (@identNr_mpx) {

		#		print "D:".$identNr_mpx->string_value()."\n";
		identNr_base( $identNr_mpx->string_value() );

		#print ".";
		my $match;
		my $objId;
		my $identNr;
		foreach my $path ( keys %file_map_path ) {
			my $identNr_dir = $file_map_path{$path};
			if ( $identNr_dir =~ /$identNr_mpx/ ) {
				$identNr = $identNr_dir;
				print "\n\tExact Match:$identNr_dir\n";
				$match = $path;
				$objId = $node->find('@objId');
				print "objId: $objId\n";
			}
			elsif ( identNr_base( $identNr_mpx->string_value() ) eq
				identNr_base($identNr_dir) )
			{
				$identNr = identNr_base($identNr_dir);
				print "\n\tBase Match:$identNr_dir\n";
				$match = $path;
				$objId = $node->find('@objId');
				print "objId: $objId\n";
			}
		}

		if ($match) {

			#if you get here it means you passed the first test:
			#scan_dir and mpx have a common identNr and you are parsing the
			#corresponding sammlungsobjekt

  # 2nd test: check if dir path already in mume-record
  # /mpx:museumPlusExport/mpx:multimediaobjekt[mpx:verknüpftesObjekt eq $objId]
  # i.e. look through dir paths and compare them with mume-path
  # if they correspond it means that dir-object was already entered in the db
  # and that means we don't have to generate a fake mume record
  # should I apply the 2nd check to everything or only to stuff that passes
  # the first check? Only to what passes the first check since if I cannot
  # associate a dir object with a sammlungsobjekt it is worthless.
  # I will later need the objId of the sammlungsobjejt, so while I am at it,
  # I should save it

			print "test multimediapfad\n";

			foreach my $node (
				$xpc->findnodes("/mpx:museumPlusExport/mpx:multimediaobjekt") )
			{
				my $linkedObj =
				  $node->getElementsByTagName('verknüpftesObjekt');

			  #there can be several verknüpftesObjekt for each multimediaobjekt
			  #print "node:".$node->string_value()."\n";
				if ( $linkedObj =~ /^$objId$/ ) {
					print "TT:$objId\n";
					my $pfad =
					  $node->getElementsByTagName('multimediaPfadangabe');
					my $erweiterung =
					  $node->getElementsByTagName('multimediaErweiterung');
					my $name =
					  $node->getElementsByTagName('multimediaDateiname');
					if ( $pfad && $erweiterung && $name ) {
						my $full_path = "$pfad\\$name.$erweiterung";
						print "\tmpx mume path:\n\t$full_path\n";
						print "\tdir path:\n\t$file_map_identNr{$identNr}\n";
						if ( $full_path eq $file_map_identNr{$identNr} ) {
							print "path equal\n";

							#this means that there is already a mpx-mume record
							#which describes this resource
							#stop here
						}
						else {
							print "path NOT equal\n";

						#means I cannot find a mpx-mume record and will fake one
						}
					}
				}
			}
		}
	}
}

#		foreach (@test_nodes) {
#		print $_->textContent;
#		}
#
#		print $node->nodeName;

#		print "$mpxIdentNr\n";
#		if ( $myIdentNr =~ /^identNr$/ ) {
#		}

#
# Second step: test if file is already described im mume record
# (identical paths)
#

# get objId:
# objId: /mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr eq 'FileIdentNr']/@objId
# get ALL linked multimediaObjekt if one or more exist:
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']
# get corresponding path
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaPfadangabe
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaDateiname
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaErweiterung
# $multimediaPfadangabe.'\'.$multimediaDateiname.$multimediaErweiterung
# this is windows path. I have to transform it to cygwin

#print "\t\t$myIdentNr--$identNr!\n";

sub identNr_base {

	#return only three parts of a identNr
	#e.g VII c 1234 a
	my $input = shift;    #\s([a-z])\s(\d+)\s

	$input =~
/([I|II|III|IV|V|VI|VII|VIII])\s+(\w{1,2}|\w{1,2} [nNlLsS]{3}|[nNlLsS]{3})\s+(\d+)/;

	if ( $1 && $2 && $3 ) {
		my $new = "$1 $2 $3";

		#print "in:$input --> base:$new\n";
		return $new;
	}
	else {
		return "";

		#warn "Couldn't identify base for '$input'";
	}

	#how to return error code?
}

sub parse_78 {
	my $dir = shift;
	%main::file_map = ();
	my %file_map;

	#identNr is not necessarily unique
	#path has to be unique
	#	%file_map{$fullpath}=$identNr

	sub wanted {

		#act only on sample mp3 files
		if ( $_ =~ /sample\.mp3/i ) {

			#VII_78_1234_a
			$_ =~ /^(\w+)_(\d+)/;
			die "Cannot identify $_" unless $1 && $2;
			my $identNr = "$1 $2";
			print "$File::Find::name\n";
			print "\t--> $identNr\n";
			$main::file_map{$File::Find::name}{$identNr};
		}
	}
	if ( -d $dir ) {
		find( \&wanted, $dir );
	}
	else {
		die "dir $dir not found";
	}
	%file_map = %main::file_map;
	return \%file_map;
}

sub simulate_dir_scan {
	my %file_map = ();

	#	%file_map{$fullpath}=$identNr
	%file_map = (
'M:\MuseumPlus\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I A 720.jpg'
		  => "I A 720",
'M:\MuseumPlus\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I D 24055.jpg'
		  => "I D 24055",
'M:\Testpath\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I D 24055.jpg'
		  => "I D 24055",
	);

	return \%file_map;
}

sub parse_rainer {

}

sub findByCriterion {

#usage: @nodes=$xpc->findByCriterion ('/mpx:museumPlusExport/mpx:sammlungsobjekt/','@objId','search_pattern1', 'search_pattern2);
	my $doc    = shift;
	my $xpath1 = shift;
	my $xpath2 = shift;
	my @search = @_;
	my @result_nodes;

	foreach my $node ( $doc->findnodes($xpath1) ) {
		my @sub_nodes = $node->getElementsByTagName($xpath2);
		foreach (@sub_nodes) {
			my $string = $_->string_value();

			#print "D:$string\n";
			foreach my $search_pattern (@search) {
				if ( $string eq $search_pattern ) {

					#print "D:$string\n";
					push( @result_nodes, $node );
				}
			}
		}
	}

	return @result_nodes;

}

#<multimediaobjekt mulId="46">
#<bearbDatum>17.01.2005 14:42:55</bearbDatum>
#-->create automatically from current date (now)
#<multimediaAnfertDat>2003</multimediaAnfertDat>
#fill in if known
#<multimediaDateiname>IV Ca 41136 -A</multimediaDateiname>
#preserve original
#<multimediaErweiterung>jpg</multimediaErweiterung>
#preserve original
#<multimediaFarbe>farbig</multimediaFarbe>
#fill in automatically
#<multimediaFunktion>Repro Digitalisat</multimediaFunktion>
#fill in automatically
#<multimediaInhaltAnsicht>Vorderseite</multimediaInhaltAnsicht>
#not really necessary
#<multimediaPersonenKörperschaft>Andrea Blumtritt</multimediaPersonenKörperschaft>
#<multimediaPfadangabe>M:\MuseumPlus\Produktiv\Multimedia\EM\Amerikanische Archäologie\Fotos</multimediaPfadangabe>
#<multimediaTyp>Digitale Aufnahme</multimediaTyp>
#<multimediaUrhebFotograf>Andrea Blumtritt</multimediaUrhebFotograf>
#<verknüpftesObjekt>102876</verknüpftesObjekt>
#</multimediaobjekt>
