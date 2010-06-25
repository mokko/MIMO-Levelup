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
use File::Basename;
use File::Copy;
use File::Find;
use Getopt::Std;
use Storable;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $type = fileparse_set_fstype('MSWin32');

#sub simulate_dir_scan;

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
print "Load configuration...\n";

my %opts;
getopts( 'r:w:', \%opts );

#-s filecache scandir only: write the result to a file and quit
#-r filecache reach scandir: read cache and continue

#simple sanity check
if ( $opts{r} && $opts{w} ) {
	die "Error: Cannot be in read (scan only) and write mode at the same time";
}

if ( $opts{r} ) {
	if ( !-f $opts{r} ) {
		die "Error:Cannot find dir scan cache file: $opts{r}";
	}
}

if ( !$opts{r} && !$opts{w} ) {

	#normal mode
	print "NORMAL SCAN DIR MODE\n";
}

if ( $opts{w} ) {
	print "SCAN DIR WRITE-ONLY MODE\n";
	print "Scan all dirs specified in config, write result to file and quit.\n";
}

if ( $opts{r} ) {
	print "SCAN DIR READ MODE\n";
}


my %config = (
	mpx_fn => "/home/Mengel/M+Export/MIMO/4-lvl2/2join.lvl2.mpx",
	mpx_fn => "/home/Mengel/M+Export/MIMO/4-lvl2/Copy (2) of join.lvl2.mpx",

	index_offset => "100000000",
	1            => {
		parser => 'parse_78',
		parser => 'simulate_dir_scan',
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
	2 => {
		parser => 'parse_rainer',
		parser => 'simulate_dir_scan',
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
);

#
# 2) PARSE MPX
#

#get file name from config
my $xpc = parse_mpx( $config{mpx_fn} );

#
# Prepare new mume records
#

my $newdoc = XML::LibXML::Document->new( '1.0', 'UTF-8' );
my $root = $newdoc->createElement('mpx:museumPlusExport');
$newdoc->setDocumentElement($root);

#
# 2) SCAN DIRS (TODO)
#
print "About to scan dirs according to configuration...\n";
foreach my $dir_counter ( 1 .. 100 ) {
	if ( $config{$dir_counter} ) {

		#print "\n   dir $dir_counter\n\n";
		my ( $href, @file_map ) = scan_dir( \%config, $dir_counter );

		my %file_map_path;
		if ($href) {
			%file_map_path = %$href;
		}

		#
		#4) check if identNr from file corresponds with mpx-db
		#
		print "Find objects with common identNr in dir cache and mpx...\n";

		foreach my $node ( common_identNr( $xpc, @file_map ) ) {

			# if you get here it means you passed the first test:
			# scan_dir and mpx have a common identNr and you are parsing the
			# corresponding sammlungsobjekt

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

			my $full_path;
			my $objId   = $node->find('@objId');
			my $identNr = $node->getElementsByTagName('identNr');
			print "\tobjId: $objId (identNr: $identNr)\n";
			print "\t\tFind mume record for this object...\n";
			my $act = 0;    #1 = false
			  #/mpx:museumPlusExport/mpx:multimediaobjekt[mpx:verknüpftesObjekt eq $objId]
			foreach my $mume (
				$xpc->main::findByCriterion(
					"/mpx:museumPlusExport/mpx:multimediaobjekt",
					'verknüpftesObjekt', $objId
				)
			  )
			{
				my $mulId = $mume->find('@mulId');
				print "\t\tmulId: $mulId\n";
				$full_path = mk_full_path($mume);

				#print "\t\tFULL PATH: $full_path\n";

				#check if this path is also in file_map
				if ( $file_map_path{$full_path} ) {
					print
"\t\tpath already exists in dir cache, continue with next record\n";

					#that means we don't have to continue
					#this file is already indexed in mpx
					$act = 1;    #0=yes 1=no;
				}
				else {
					print
"\t\tpath does not exists in dir cache, fake a mume record\n";

					#this means that this file is not yet indexed,
					#we need to fake the mume record
				}
			}

			#print "\t\tDDSoll ich jetzt handeln oder nicht?act=$act (1=no)\n";
			#no mume record at all, so act anyways
			if ( $act == 0 ) {

				#OK Now I tested enough, now I will fake a mume record
				#this thing is called for each
				print "Fake mume record for $objId $identNr \n";

				#mume object
				my $mume = $newdoc->createElement('multimediaobjekt');
				$mume->setAttribute( 'mulId', '0' );
				$root->appendChild($mume);

				#path
				$mume->main::write_mpx_path( $full_path, \%file_map_path,
					$identNr );

				#constants
				$mume->main::write_mpx_constants( \%config, $dir_counter );

				#verkObjekt
				my $verkObjekt =
				  $newdoc->createElement('mpx:verknüpftesObjekt');
				my $text = XML::LibXML::Text->new($objId);
				$verkObjekt->appendChild($text);
				$mume->appendChild($verkObjekt);

				#just write a version now because we don't know if we end the
				#life of this script
				my $state = $newdoc->toFile( 'output.mpx', '1' );
				print $newdoc->toString('1');

				print "state: $state\n";

			}
		}
	}
}

my $state = $newdoc->toFile( 'output.mpx', '1' );
print "state: $state\n";
exit;

#my @sammlungsobjekte =
#  $xpc->main::findByCriterion( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
#	'identNr', @file_map );
#

#by now it is an exact match, but I might want to know if strings in @file_map
#are merely contained in mpx:identNr
#/mpx:museumPlusExport/mpx:sammlungsobjekt[contains (mpx:identNr, @file_map)]
#my @nodes =
#  $xpc->main::findByCriterionContains( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
#	'identNr', @file_map );
#exit;
#	push (@file_map, '^'.$identNr);
#TODO: I have to figure that out a mapping between parts and wholes
#dir:VII a 1 a -> mpx:VII a 1 a ->yes (exact match)
#dir:'VII a 1' -> mpx:'VII a 1'->yes (exact match)
#dir:'VII a 1 a' -> mpx:'VII a 1'->? (approximate, dir is more detailed)
#dir:'VII a 1 b' -> mpx:'VII a 1'->? (approximate, dir is more detailed)
#dir:'VII a 1' -> mpx:'VII a 1 a'->? (approximate, mpx is more detailed)

#foreach my $node ($xpc->main::findByCriterion( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
#'identNr', @file_map )) {

#my $link = $doc->createElement('a');
#   $link->setAttribute('href', $camelid_links{$item}->{url});
#   my $text = XML::LibXML::Text->new($camelid_links{$item}->{description});
#   $link->appendChild($text);
#   $body->appendChild($link);

# get objId:
# objId: /:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr eq 'FileIdentNr']/@objId
# get ALL linked multimediaObjekt if one or more exist:
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']
# get corresponding path
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaPfadangabe
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaDateiname
# /mpx:museumPlusExport/mpx:multimediaObjekt[mpx:verknüpftesObjekt eq '$objId']/multimediaErweiterung
# $multimediaPfadangabe.'\'.$multimediaDateiname.$multimediaErweiterung
# this is windows path. I have to transform it to cygwin

#
# SUBs
#
#

sub common_identNr {
	my $xpc      = shift;
	my @file_map = @_;

	#/mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr eq @file_map]
	#N.B. that in xpath2 you can search for only one match at a time
	my @sammlungsobjekte =
	  $xpc->main::findByCriterion( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
		'identNr', @file_map );

	print "\t"
	  . ( $#sammlungsobjekte + 1 )
	  . " object(s) with common IdentNr found\n";
	return @sammlungsobjekte;
}

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

sub mk_full_path {
	my $mume        = shift;
	my $pfad        = $mume->getElementsByTagName('multimediaPfadangabe');
	my $erweiterung = $mume->getElementsByTagName('multimediaErweiterung');
	my $name        = $mume->getElementsByTagName('multimediaDateiname');
	my $full_path;
	if ( $pfad && $erweiterung && $name ) {
		$full_path = "$pfad\\$name.$erweiterung";
		print "\t\tmpx path: $full_path\n";
	}
	return $full_path;
}

sub parse_mpx {
	my $file = shift;
	print "About to load and parse mpx file...\n";
	die "Cannot find mpx file" unless ( -f $file );
	print "\t$file exists\n";

	my $parser = XML::LibXML->new();
	my $doc    = $parser->parse_file($file);
	my $xpc    = XML::LibXML::XPathContext->new($doc);
	$xpc->registerNs( 'mpx', 'http://www.mpx.org/mpx' );

	#my $root = $doc->getDocumentElement;

	return $xpc;

}

sub parse_rainer {

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
		'M:\Testpath3\VII c 685.jpg' => "VII c 685",
'M:\MuseumPlus\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I A 720.jpg'
		  => "I A 720",
'M:\MuseumPlus\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I D 24055.jpg'
		  => "I D 24055",
'M:\Testpath\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I D 24055.jpg'
		  => "I D 24055",
'M:\Testpath1\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\VII c 16.jpg'
		  => "VII c 16",
	);

	foreach my $test ( keys %file_map ) {
		print "\t" . $file_map{$test} . "-->$test\n";
	}

#DEBUG
#split_path ('M:\MuseumPlus\Produktiv\Multimedia\EM\Ost- u. Nordasien\Fotos\I A 720.jpg');

	return \%file_map;
}

sub split_path {
	my $path = shift;
	print "\tTTTTTTTTT:$path\n";

	if ($path) {
		my ( $name, $pfad, $erweiterung ) =
		  fileparse( $path, '.jpg', '.mp3', '.JPG', '.pdf', '.PDF' );
		$pfad =~ s/\\$//;

		#		$path =~ /([\w+\s\\]+)\.(\w+)$/;

		#		my $pfad        = $1 if $1;
		#		my $name        = $2 if $2;
		#		my $erweiterung = $3 if $3;

		print "\tPFAD:$pfad\n";
		print "\tNAME:$name\n";
		print "\tERWEITERUNG:$erweiterung\n";
		return ( $pfad, $name, $erweiterung );
	}
}

sub findByCriterion {

#usage: @nodes=$xpc->findByCriterion ('/mpx:museumPlusExport/mpx:sammlungsobjekt/','@objId','search_pattern1', 'search_pattern2);
	my $doc    = shift;
	my $xpath1 = shift;
	my $xpath2 = shift;
	my %saw;
	my @search = grep( !$saw{$_}++, @_ );    #keep only unique entries
	my @result_nodes;

	#print "DD:search exact match for @search\n";

	foreach my $node ( $doc->findnodes($xpath1) ) {

		#e.g. xpath1='//sammlungsobjekt'
		#e.g. xpath2='identNr' (can have several)
		foreach ( $node->getElementsByTagName($xpath2) ) {

			my $string = $_->string_value();

			#DEBUG At this point I do not get all items, only a few
			#Why not all?
			#print "\tmpx string:$string\n" if ($string =~/VII c/i);

			#print "DD:$string\n";
			foreach my $search_pattern (@search) {
				if ( "" . $search_pattern eq "" . $string ) {

					#				print "\tDD:found $string\n";
					push( @result_nodes, $node );
				}
			}
		}
	}

	return @result_nodes;

}

sub findByCriterionBase {

#usage: @nodes=$xpc->findByCriterion ('/mpx:museumPlusExport/mpx:sammlungsobjekt/','@objId','search_pattern1', 'search_pattern2);
	my $doc    = shift;
	my $xpath1 = shift;
	my $xpath2 = shift;
	my %saw;
	my @search = grep( !$saw{$_}++, @_ );    #keep only unique entries
	my @result_nodes;

	#print "DD:search exact match for $xpath2 eq @search\n";

	foreach my $node ( $doc->findnodes($xpath1) ) {
		my @sub_nodes = $node->getElementsByTagName($xpath2);
		foreach (@sub_nodes) {
			my $string = identNr_base( $_->string_value() );

			#print "DD:$string\n";
			foreach my $search_pattern (@search) {
				$search_pattern = identNr_base($search_pattern);
				if ( "" . $search_pattern eq "" . $string ) {

					#				print "\tDD:found $string\n";
					push( @result_nodes, $node );
				}
			}
		}
	}

	return @result_nodes;

}

sub findByCriterionContains {

	#usage: @nodes=$xpc->findByCriterionContains
	#('/mpx:museumPlusExport/mpx:sammlungsobjekt/','@objId','search_pattern1',
	#'search_pattern2);
	my $doc    = shift;
	my $xpath1 = shift;
	my $xpath2 = shift;
	my %saw;
	my @search = grep( !$saw{$_}++, @_ );    #keep only unique entries
	my @result_nodes;

	#	print "DD:search contains for @search\n";

	foreach my $node ( $doc->findnodes($xpath1) ) {
		my @sub_nodes = $node->getElementsByTagName($xpath2);
		foreach (@sub_nodes) {
			my $node_str = $_->string_value();

			#print "D:$string\n";
			foreach my $search_pattern (@search) {
				if ( $node_str =~ /$search_pattern/ ) {

					#					print "\tDD:found inexact $node_str\n";
					push( @result_nodes, $node );
				}
			}
		}
	}

	return @result_nodes;

}

sub scan_dir {
	my $conf_href   = shift;
	my $dir_counter = shift;
	my $opts_href   = shift;
	my %config      = %$conf_href;

	my $new_href;
	my %opts;
	if ($opts_href) {
		%opts = %$opts_href;
	}
	print "\n   dir $dir_counter\n\n";
	print "   $config{$dir_counter}{path}\n";

	#we are in one of three modes
	#a) normal read and write without making a cache
	#b) read only: read dir cache and continue
	#c) write only: write dir cache and quit

	#
	# REPORT MODE
	#
	if ( !$opts{r} && !$opts{w} ) {

		#normal mode
	}


	if ( $opts{r} ) {
		print "SCAN DIR READ MODE\n";
		print "Read dir scan from file and continue.\n";

		#it seems that I load this file repeatedly for each
		#dir scan, then I will need to separate the hashes from various scans
		my $new = read_dir_cache( $opts{r} );
		my %new = %$new;
		$new_href = \$new{$dir_counter};
	}

	#scan-dir both in save-mode and in normal mode
	if ( !$opts{r} ) {
		no strict;
		$new_href =
		  $config{$dir_counter}{parser}( $config{$dir_counter}{path} );
		use strict;
	}

	if ( $opts{w} ) {
		#write mode
		#if I write only $new_href then I write only the scan current config dir
		$main::complete_map{$dir_counter}=$new_href;
		write_dir_cache(\$main::complete_map, $opts{w});
		print "Quit here since we are in write-only mode\n";
		exit;
	}


	#
	# rewrite and return dir-cache
	#
	my %file_map_path = %$new_href;

	#don't add the hashes, instead do one config after the other
	#my %file_map_identNr;    #I don't think this is a good idea TODO
	my @file_map;

	#this doesn't work. Since each identNr can have several paths
	#maybe it is better to search for it when I need it.

	#make an array which contains the identNrs
	foreach my $path ( keys %file_map_path ) {
		my $identNr = $file_map_path{$path};
		push( @file_map, $identNr );

		#	$file_map_identNr{$identNr} = $path;
	}
	return ( \%file_map_path, @file_map );
}

sub write_dir_cache {
	my $href     = shift;
	my $store_fn = shift;

	print "Write dir cache to file ($store_fn)\n";

	# store \%table, 'file';
	store $href, $store_fn;

}

sub read_dir_cache {
	my $file = shift;

	my $href = retrieve($file);

	return $href;

}

sub write_mpx_constants {
	my $mume        = shift;
	my $href        = shift;
	my %config      = %$href;
	my $dir_counter = shift;

	foreach
	  my $constant ( sort keys %{ $config{$dir_counter}{constant_fields} } )
	{
		my $constant_t = $newdoc->createElement("mpx:$constant");
		my $text       =
		  XML::LibXML::Text->new(
			$config{$dir_counter}{constant_fields}{$constant} );
		$constant_t->appendChild($text);
		$mume->appendChild($constant_t);
	}
}

sub write_mpx_path {
	my $mume          = shift;
	my $full_path     = shift;
	my $href          = shift;
	my %file_map_path = %$href;
	my $identNr       = shift;

	foreach my $path ( keys %file_map_path ) {
		if ( "" . $file_map_path{$path} eq "" . $identNr ) {
			$full_path = $path;
		}
	}

	print "DD:$full_path\n";

	print "split full_path: $full_path\n";

	my ( $pfad, $name, $erweiterung ) = split_path($full_path);

	print "split pfad: $pfad\n";
	print "split name: $name\n";
	print "split erweiterung: $erweiterung\n";

	my $tag  = $newdoc->createElement("mpx:multimediaDateiname");
	my $text = XML::LibXML::Text->new($name);
	$tag->appendChild($text);
	$mume->appendChild($tag);

	# multimediaErweiterung
	$tag  = $newdoc->createElement("mpx:multimediaErweiterung");
	$text = XML::LibXML::Text->new($erweiterung);
	$tag->appendChild($text);
	$mume->appendChild($tag);

	# multimediaPfadangabe
	$tag  = $newdoc->createElement("mpx:multimediaPfadangabe");
	$text = XML::LibXML::Text->new($pfad);
	$tag->appendChild($text);
	$mume->appendChild($tag);
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
