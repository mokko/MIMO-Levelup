#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use File::Find;
use Getopt::Std;
use XML::Twig;

#my $Version_String = XML::LibXML::LIBXML_DOTTED_VERSION;
#print "Version_String $Version_String \n";

print "About to parse xml file\n";
my $file ="/home/Mengel/M+Export/MIMO/4-lvl2/2join.lvl2.mpx";

my $twig=XML::Twig->new();    # create the twig
  $twig->parsefile( $file);   # build it

my $root= $twig->root;



my $parser = XML::LibXML->new();
my $doc    = $parser->parse_file( $file );
my $xpc    = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs( 'mpx', 'http://www.mpx.org/mpx' );

my $root   = $doc->getDocumentElement;

my @file_map=['VII c 16','VII c 685'];

my $count=0;
foreach my $node ( $xpc->findnodes('/mpx:museumPlusExport/mpx:sammlungsobjekt') ) {
		#print $node->string_value()."\n";
		$count++;

#		foreach my $identNr_node ($node->getElementsByTagName('identNr')) {
#			my $identNr_str=$identNr_node->string_value();
#			print "node:$identNr_node: $identNr_str\n";# if ($identNr_str =~/VII c/i);
#		}
}

print "found: $count total\n";

exit;

my @sammlungsobjekte =
  $xpc->main::findByCriterion( "/mpx:museumPlusExport/mpx:sammlungsobjekt",
	'identNr', @file_map );


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
		foreach ($node->getElementsByTagName($xpath2)) {

			my $string = $_->string_value();
			#DEBUG At this point I do not get all items, only a few
			#Why not all?
			print "\tmpx string:$string\n" if ($string =~/VII c/i);

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
