#!/usr/bin/perl

#NAME - fake_mume_records.pl
#a little utility which fakes mume records from files on the hardisk

#USAGE
# fake_mume_records.pl
# fake_mume_records.pl -w filename
# fake_mume_records.pl -r filename
#
# write-only-mode (-w filename): scan the local directories, saves them
#      to a file and quits
# read (-r filename): read the result of the scan dir from file cache and
#      continue
# I did this so that one version of this script can run work pc and the
# other on my laptop.

#
#DESCRIPTION
# the purpose is that you don't have to enter the resources manually
# in the database. This should be esp useful for the audio-samples.
# In general it would be better to enter everything manually in M+
# to remind of that I use the word "fake".
#
#At the moment, I take the
# a) constant metadata info from config in this file
# b) file name (identNr)
# c) automatic extraction from file (todo)
#
#In the future, I could extract more info both from the file name (e.g. Ansicht)
#Or I could use ImageMagick etc. to extract info (e.g. farbig).
#
#N.B.
#I don't really know how to make persistent mulId for these files, so I try
#how far I get without a proper and unique id

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
#use Term::Activity;

#use XML::LibXSLT;

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
# 1 INITIALIZE COMMAND LINE OPTIONS
#

my %opts;
getopts( 'r:w:', \%opts );

#
# 2 LOAD CONFIG
#

my $config = load_config( \%opts, \@ARGV );
cli_init($config);

#print "DEBUG:" . $config->{1}{path} . "\n";

#
# 3) mulId init
#

$config->{mulId} = init_mulId($config);

#
# 3) NEW SCAN DIR
#

scan_dir_new($config);    #result in %main::file_map

#print "RESULT OF SCAN DIR NEW:\n";
#foreach my $project ( keys %$dir_cache ) {
#	print "R\t $project ->\n";
#	foreach ( keys %{ $dir_cache->{$project} } ) {
#		print "RR\t\t $_ ->$dir_cache->{$project}{$_}\n";
#	}
#}

#
# 4) PARSE MPX
#

my $xpc = parse_mpx( $config->{mpx_input_fn} );    #get file name from config

#
# 5) MPX-path-cache
# store all mpx-mume-paths in one hash with mume-mulId as index
my %mpx_paths;                                     #path cache

print "Writing mpx mume path cache\n";
foreach
  my $mume ( $xpc->findnodes('/mpx:museumPlusExport/mpx:multimediaobjekt') )
{
	my $mulId     = $mume->find('@mulId');
	my $mume_path = mk_full_path($mume);
	die "mulId exists already" if $mpx_paths{$mulId};
	if ($mume_path) {
		$mpx_paths{$mulId} = $mume_path;
	}
}

#
# 6) Prepare new mume records
#

my ( $newdoc, $root ) = init_new_mpx();

#
# 7) WALK THRU config-project and mpx OR Work on one project only if specified on ARGV[0]
#
if ( $ARGV[0] =~ /\d+/ ) {

	#if $ARGV[0] is a number
	if ( $config->{ $ARGV[0] } ) {

		#if this number is defined as project in the config
		process_project( $config, $ARGV[0], $xpc, \%mpx_paths, $newdoc, $root );
	}

}
else {
	print "About to WALK THRU the projects and mpx defined in config ...\n";
	foreach my $project ( 1 .. 100 ) {
		if ( $config->{$project} ) {
			process_project( $config, $project, $xpc, \%mpx_paths, $newdoc,
				$root );

		}
	}

}

#Ulrike Zoeller: Karibik nacht 1. Mai Bayern Klassik

my $state = $newdoc->toFile( $config->{output_fn}, '1' );
store \$config->{mulId}, $config->{mulId_fn};
print "state: $state\n";

#
# dirty sort with saxon!
#

saxon_sort($config);

#
# join two files with libXML
#

#load $config->{mpx_input_fn}

exit;

#
# SUBs
#

sub cli_init {
	my $config = shift;
	my $opts   = $config->{opts};
	my @cli    = @{ $config->{cli} };

	#-s filecache scandir only: write the result to a file and quit
	#-r filecache reach scandir: read cache and continue

	#simple sanity check
	if ( $opts->{r} && $opts->{w} ) {
		die
"Error: Cannot be in read (scan only) and write mode at the same time";
	}

	if ( $opts->{r} ) {
		if ( !-f $opts->{r} ) {
			die "Error:Cannot find dir scan cache file: $opts{r}";
		}
	}

	if ( !$opts->{r} && !$opts->{w} ) {

		#normal mode
		print "NORMAL SCAN DIR MODE\n";
	}

	if ( $opts->{w} ) {
		print "SCAN DIR WRITE-ONLY MODE\n";
		print
		  "Scan all dirs specified in config, write result to file and quit.\n";
	}

	if ( $opts->{r} ) {
		print "SCAN DIR READ MODE\n";
	}

	foreach (@cli) {
		die "Project specified on command line not defined in config hash"
		  unless $config->{$_};
	}

}

sub common_identNr {
	my $xpc      = shift;
	my @file_map = sort(@_);    #contains identNr

	#print "file_map has $#file_map items (@file_map)\n";
	#print "null:$file_map[0]\n";

	#/mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr eq @file_map]
	#N.B. that in xpath2 you can search for only one match at a time
	print "Find objects with common identNr in dir cache and mpx...\n";

	print "common objects: @file_map\n";

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

sub init_mulId {
	my $config = shift;
	my $mulId;
	if ( -f $config->{mulId_fn} ) {
		print "Retrieve mulId";
		$mulId = retrieve( $config->{mulId_fn} );
	}
	else {
		$mulId = $config->{mulId_offset};
	}
	die "mulId is no integer" if ( $mulId !~ /\d+/ );
	return $mulId;
}

sub init_new_mpx {
	my $newdoc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

	#my $ns = XML::LibXML::Namespace->new('http://www.mpx.org/mpx');
	my $ns_uri = 'http://www.mpx.org/mpx';

	my $root = $newdoc->createElementNS( $ns_uri, 'museumPlusExport' );
	$root->setNamespace( 'http://www.w3.org/2001/XMLSchema-instance', 'xsi',
		0 );
	$root->setAttributeNS(
		'http://www.w3.org/2001/XMLSchema-instance',
		'schemaLocation',
'http://www.mpx.org/mpx file:/c:/cygwin/home/Mengel/usr/levelup/lib/mpx-lvl2.v2.xsd'
	);
	$newdoc->setDocumentElement($root);
	return $newdoc, $root;
}

sub load_config {
	my $opts = shift;
	my $cli  = shift;    #aref
	print "Load configuration...\n";

	#	foreach my $key ( keys %Settings::config ) {
	#		my $value = $Settings::config{$key};
	#		print "-$key --> $value\n";

	#all config stuff. Change as necessary

	#{
	#	package Settings;
	#	my $settings = "/home/Mengel/usr/levelup/lenny.config";
	#	die "Error: Don't find settings file " unless -e $settings;
	#	do $settings
	#	  or die "Error: Can't load config file!\n";
	#}

	my $home = $ENV{HOME};

	my %config = (
		cli          => $cli,
		log_fn       => 'fake-mume-records.log',
		mpx_input_fn => "$home/M+Export/MIMO/4-lvl2/2join.lvl2.mpx",
		mpx_input_fn => "$home/M+Export/VII_78/6-fake-mume/78-fake-mume.sort2.mpx",
		mulId_fn     => "$home/.mulId",
		mulId_offset => "100000000",

		#		mpx_input_fn => "$home/M+Export/MIMO/4-lvl2/join.lvl2.mpx",
		ns_uri => 'http://www.mpx.org/mpx',

		opts => $opts
		,    #put cli options here to reduce number of params in function calls
		output_fn      => '1-fakemume.mpx',
		output_sort_fn => '2-fakemume.sort.mpx',
		output_join_fn => '3-fakemue.join.mpx',
		saxon          => {
			java => 'java -jar -Xmx256m ',

			#work
			saxon => "-jar 'D:\\Programme\\saxonb8-9j\\saxon8.jar' ",

			#Lenny
			#			saxon =>
			#			  "'C:\\Program Files\\saxon\\saxonhe9-2-0-6j\\saxon9he.jar' ",
			#			xsl_sort => '/home/mengel/usr/levelup/lib/mpx-sort.xsl',
		},

		#VII 78s
		1 => {
			parser => 'simulate_dir_scan',
			parser => 'parse_78',
			path   => '/cygdrive/M/MuseumPlus/Produktiv/Multimedia/EM/'
			  . 'Medienarchiv/Audio/Produktiv/VII_78',
			constant_fields => {

				#exact list of constant fields is not fixed and can vary
				multimediaAnfertDat    => "2010-04",
				multimediaFormat => "mp3 128kbit mono",

		  #multimediaPersonKörperschaft        => "Rainer Hatoum",
				multimediaFunktion => "Repro Digitalisat",
				multimediaTyp      => "Audio Sample",
			},
		},

		#MIMO instrumente in VII
		2 => {
			parser => 'simulate_dir_scan',
			parser => 'parse_VII_instruments',
			path   => '/cygdrive/M/MuseumPlus/Produktiv/Multimedia/EM/'
			  . 'Musikethnologie/Fotos/Archiv TIFF und Raw',
			constant_fields => {

				#exact list of constant fields is not fixed and can vary
				multimediaFunktion  => "Webseite",
				multimediaTyp       => "Audio Sample",
				multimediaAnfertDat => "2010",

				#multimediaFarbe     => "farbig",
				#multimediaPersonKörperschaft        => "Rainer Hatoum",
				#multimediaUrhebFotograf => "Andrea Blumtritt",
			},
		},
	);

	return \%config;

}

sub mk_full_path {
	my $mume        = shift;
	my $pfad        = $mume->getElementsByTagName('multimediaPfadangabe');
	my $erweiterung = $mume->getElementsByTagName('multimediaErweiterung');
	my $name        = $mume->getElementsByTagName('multimediaDateiname');
	my $full_path;
	if ( $pfad && $erweiterung && $name ) {
		$full_path = "$pfad\\$name.$erweiterung";
		print "\t\tmpx mume path cache: $full_path\n";
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

sub parse_VII_instruments {
	my $dir = shift;    # this is the dir we have to search
	$main::project = shift;    # current project
	                           #my $opts =shift;
	                           #write result in %main::file_map
	print "Project:$main::project\n";

	sub wanted1 {

		#act only on sample mp3 files
		if ( $_ =~ /\.jpg|\.tif|\.tiff|\.pdf$/i ) {

			#print "DD:$_\n";
			#VII_78_1234_a
			$_ =~
/(VII|I|III)[_|\s]([a-f]|nls|[a-f] nls)[_|\s](\d+)[_|\s|\.|\-\w|]([a-h]|a,b|ab|a+b|)/i;
			die "Cannot identify $_" unless $1 && $2 && $3;

			my $identNr = uc($1) . ' ' . $2 . ' ' . $3 if ( $1 && $2 && $3 );
			print "$File::Find::name\n";
			print "\t--> $identNr \n";
			$main::file_map{$main::project}{$File::Find::name} = $identNr;
		}
	}

	if ( -d $dir ) {
		find( \&wanted1, $dir );
	}
	else {
		die "dir $dir not found";
	}
}

sub parse_78 {

	#LOOKS ONLY FOR SAMPLES!
	my $dir_path = shift;    # this is the dir we have to search
	$main::project = shift;
	die "need project" unless $main::project;
	open( LOG, "> ", $config->{log_fn} );
	print LOG "dir parser: parse_78\n";

	#	my $opts = shift;
	#$opts->{w};
	#%main::file_map = (); #to communicate with find
	my %file_map;

	#identNr is not necessarily unique
	#path has to be unique
	#	%file_map{$fullpath}=$identNr

	sub wanted {

		#act only on sample mp3 files

		if ( $_ =~ /sample\.mp3/i ) {

			#VII_78_1234_a
			$_ =~ /^(VII)_(\d+)_(\d+)/;
			if ( !$1 && $2 && $3 ) {
				push( @main::dir_parser_not_found, $File::Find::name );
			}
			else {
				my $identNr = "$1 $2/" . sprintf( "%04d", $3 );
				print "parse_78:$File::Find::name\n";
				print "parse_78:\t--> $identNr\n";
				$main::file_map{$main::project}{$File::Find::name} = $identNr;
			}
		}

	}
	if ( -d $dir_path ) {
		print LOG "dir parser looks only for files ending on .sample.mp3\n";
		find( \&wanted, $dir_path );
	}
	else {
		die "dir $dir_path not found";
	}
	print LOG "#\n#not identified\n#\n";
	foreach (@main::dir_parser_not_found) {
		print LOG "$_ \n";
	}
	@main::dir_parser_not_found = [];

#I am cheating here since this lists the whole file_map and not only the one for this project
	print LOG "#\n#identified\n#\n";
	foreach my $path ( keys %{ $main::file_map{$main::project} } ) {
		print LOG "$main::file_map{$main::project}{$path} -> $path\n";
	}
	undef $main::project;
	close LOG;    #	return %main::file_map;

}

sub saxon_sort {
	my $config       = shift;
	my $xsl_sort_win = cygpath( $config->{saxon}{xsl_sort} );

	my $cmd = $config->{saxon}{java} . $config->{saxon}{saxon};

	if ( -f $config->{output_fn} && $xsl_sort_win ) {

		$cmd .= "-t -s:$config->{output_fn} ";
		$cmd .= "-xsl:'$xsl_sort_win' ";          #needs win path
		$cmd .= "-o:$config->{output_sort_fn}";

		print "Debug: $cmd\n";
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
	}
	else {
	}
}

sub scan_dir_new {
	my $config = shift;
	my $opts   = $config->{opts};
	my @cli    = @{ $config->{cli} };

	print "NEW SCANDIR...\n";

	# First I need to decide what to do
	# Which mode:
	# a) read-from-file-cache,
	# b) write-file-cache-after-read-and-quit or
	# c) normal (scan dirs and then continue without writing file cache)

	if ( $opts->{r} ) {

		#read-mode: read dir cache from file
		print "\tEnter read mode: read dir cache from file $opts{r} \n";
		read_dir_cache( $opts{r} );

	}
	else {

		#in write and normal mode
		print "\tAbout to scan dirs ...\n";
		if (@cli) {
			foreach (@cli) {
				if ( $config->{$_} ) {
					scan_dir_single( $config, $_ );
				}
			}
		}
		else {

			foreach my $project ( 1 .. 100 ) {

				if ( $config->{$project} ) {
					scan_dir_single( $config, $project );

				}
			}
		}

		if ( $opts->{w} ) {

			#in write-only mode
			#$opts->w should contain a filename
			print
"\tWrite mode. Will write scan dir result to file cache in $opts->{w} ...\n";
			write_dir_cache( $opts->{w} )
			  or die "Cannot write dir cache";
			print "Exit here since write-only mode\n";
			exit;
		}

		#	print "RESULT OF SCAN DIR NEW:\n";
		#	foreach my $project(keys %main::file_map){
		#		print "R\t $project ->\n";
		#		foreach (keys %{$main::file_map{$project}}) {
		#			print "RR\t\t $_ ->$dir_cache{$project}{$_}\n";
		#		}
	}
}

sub scan_dir_single {
	my $config  = shift;
	my $project = shift;

	print "\t   scan_dir_single $project\n\n";
	no strict;
	$config->{$project}{parser}( $config->{$project}{path}, $project );

	#return value in %main::file_map
	use strict;

	#DEBUG
	foreach my $project ( keys %main::file_map ) {
		foreach my $path ( keys %{ $main::file_map{project} } ) {
			print "SYD path:$path->\n";
			print "SYD identNr: $main::file_map{project}{$path}\n";
		}
	}
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

sub cygpath {
	my $nix_path = shift;

	#should I check if path is unix path? Could be difficult
	if ($nix_path) {
		my $win_path = `cygpath -wa '$nix_path'`;
		$win_path =~ s/\s+$//;
		return $win_path;

	} else {
		#catches error which breaks execution
		warn "Warning: cygpath called without param" ;
	}
}

sub findByCriterion {

#usage: @nodes=$xpc->findByCriterion ('/mpx:museumPlusExport/mpx:sammlungsobjekt/','@objId','search_pattern1', 'search_pattern2);
	my @result_nodes;    # for return
	my %saw;             #keep only unique search_patterns
	my $doc    = shift;                      # document
	my $xpath1 = shift;                      # findnodes
	my $xpath2 = shift;                      # getElementsByTagName
	my @search = grep( !$saw{$_}++, @_ );    #rest of the opts

	#warn "No search patterns given!" if ( $#search eq 0 );
	print "DD:search exact match for @search\n";

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

sub write_dir_cache {
	my $store_fn = shift;

	print "Write dir cache to file ($store_fn)\n";

	# store \%table, 'file';
	store \%main::file_map, $store_fn;

}

sub process_project {
	my $config    = shift;
	my $project   = shift;
	my $xpc       = shift;
	my $mpx_paths = shift;
	my $newdoc    = shift;
	my $root      = shift;

	print "\n   process project $project\n\n";

	#file_map is specific for this project; it contains identNr
	my @file_map;
	foreach my $path ( keys %{ $main::file_map{$project} } ) {

		#path is here a dir_cache path
		#print "Y $path\n";
		#print "YY:$main::file_map{$project}{$path}\n";

		#push( @file_map, $file_map_path{$_} );
		push( @file_map, $main::file_map{$project}{$path} );
	}

	#print "file_map:@file_map\n";

	#
	#4) check if identNr from file corresponds with mpx-db
	#
	foreach my $node ( $xpc->main::common_identNr(@file_map) ) {

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

		my $full_path;    #this will be mpx-mume-path not a dir cache path
		my $objId   = $node->find('@objId');
		my $identNr = $node->getElementsByTagName('identNr');
		print "\tobjId: $objId (identNr: $identNr)\n";
		print "\t\tFind mume record for this object...\n";

		#OK Now I tested enough, now I will fake a mume record
		#this thing is called for each
		print "Fake mume record(s) for objId $objId $identNr \n";

		foreach my $file_path ( keys %{ $main::file_map{$project} } ) {
			my $file_identNr = $main::file_map{$project}{$file_path};
			if ( "" . $file_identNr eq "" . $identNr ) {

				#foreach cache item which has the current identNr
				#check if that file path already used (anywhere in mpx)
				my $act = 1;
				foreach my $mulId ( keys %$mpx_paths ) {
					my $mume_path = $mpx_paths->{$mulId};
					$act = 0 if ( $file_path eq $mume_path );
				}
				if ( $act == 1 ) {

					#mume object
					my $mume =
					  $newdoc->createElementNS( $config->{ns_uri},
						'multimediaobjekt' );
					$mume->setAttribute( 'mulId', $config->{mulId}++ );
					$root->appendChild($mume);

			  #path: where do i get this path from?
			  #I have to take it from dir_cache in main::file_map
			  #I do have the identNr; there can be several paths for one identNr
			  #do I all the paths for each identNr?
			  #no at least I cannot simply repeat the paths tags
			  #instead I have to repeat the whole mume tag
					$mume->main::write_mpx_path( $config, $file_path, $identNr,
						$project );

					#constants
					$mume->main::write_mpx_constants( $config, $project );

					#verkObjekt
					$mume->main::write_mpx_verkObjekt( $config, $objId );
				}
			}
		}

		#just write a version now because we don't know if we end the
		#life of this script
		my $state = $newdoc->toFile( $config->{output_fn}, '1' );
		store \$config->{mulId}, $config->{mulId_fn};
		#print $newdoc->toString('1');

		print "state: $state\n";
	}

}

sub read_dir_cache {
	my $file = shift;
	my $href = retrieve($file);
	%main::file_map = %$href;

	#DEBUG -> look in log file instead!
	#		foreach  my $project(keys %main::file_map)  {
	#			foreach  my $path (keys %{$main::file_map{$project}})  {
	#				print "MMM:$project| $path -->\n";
	#				print "\tIdentNr:$main::file_map{$project}{$path}\n";
	#			}
	#		}

	#	print "QUIT HERE FOR DEBUGGING!\n";
}

sub write_mpx_constants {
	my $mume    = shift;
	my $href    = shift;
	my %config  = %$href;
	my $project = shift;

	foreach my $constant ( sort keys %{ $config{$project}{constant_fields} } ) {
		my $constant_t =
		  $newdoc->createElementNS( $config{ns_uri}, "$constant" );
		my $text =
		  XML::LibXML::Text->new(
			$config{$project}{constant_fields}{$constant} );
		$constant_t->appendChild($text);
		$mume->appendChild($constant_t);
	}
}

sub write_mpx_path {
	my $mume      = shift;
	my $config    = shift;
	my $full_path = shift;
	my $identNr   = shift;
	my $project   = shift;

	#print "DD:split full_path: $full_path\n";
	#Ich will eigentlich nicht den Punkt in mpx:multimediaErweiterung stehen haben

	my ( $name, $pfad, $erweiterung ) = fileparse( $full_path, qr/\.[^.]*/ );

	$pfad = cygpath($pfad);
	$pfad =~ s/\\$//;

	#	print "split pfad: $pfad\n";
	#	print "split name: $name\n";
	#	print "split erweiterung: $erweiterung\n";

	#dateiname
	if ($name) {
		my $tag =
		  $newdoc->createElementNS( $config->{ns_uri}, "multimediaDateiname" );
		my $text = XML::LibXML::Text->new($name);
		$tag->appendChild($text);
		$mume->appendChild($tag);
	}

	# multimediaErweiterung
	if ($erweiterung) {
		my $tag =
		  $newdoc->createElementNS( $config->{ns_uri},
			"multimediaErweiterung" );
		my $text = XML::LibXML::Text->new($erweiterung);
		$tag->appendChild($text);
		$mume->appendChild($tag);
	}

	# multimediaPfadangabe
	if ($pfad) {
		my $tag =
		  $newdoc->createElementNS( $config->{ns_uri}, "multimediaPfadangabe" );
		my $text = XML::LibXML::Text->new($pfad);
		$tag->appendChild($text);
		$mume->appendChild($tag);
	}
}

sub write_mpx_verkObjekt {
	my $mume   = shift;
	my $config = shift;
	my $objId  = shift;

	my $verkObjekt =
	  $newdoc->createElementNS( $config->{ns_uri}, 'verknüpftesObjekt' );

	my $text = XML::LibXML::Text->new($objId);
	$verkObjekt->appendChild($text);
	$mume->appendChild($verkObjekt);

}

#does not work
sub xslt_sort {

	#Usage: $xpc->main::xslt_sort($config);
	my $source = shift;
	my $config = shift;

	my $xslt       = XML::LibXSLT->new();
	my $stylesheet = $xslt->parse_stylesheet( $config->{style_doc} );
	my $results    = $stylesheet->transform($source);

	return $results;
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

#
# OLD NOTES
#
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

#
# New Notes
#
#1) dir_map{$path}=$dir_identNr
#2) mpx_path_cache: pfad+name+erweiterung from mpx for every mume record
#2) sammlungsobjekt[identNr = $dir_identNr]
#	-> gets me
#	a) objId for verkObj AND
#	b) sorts out files which are not in the scope of that mpx
#   results in a set identNr which are common to dir_cache and mpx
#NOT:3)  loop thru every file in dir_map
#3) loop thru every common identNrfile in dir_map
#   foreach common_identNr get a
#	a) dir_path from from dir_map (there can be m:1 dir_path to identNr!)
#   b) mume_path from mpx_path_cache (there can be m:1 path for each path!)
#	if ! dir_path = file_path;
#   else write mume record
