#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Copy;
use File::Find;
use Getopt::Std;
use Storable;
use XML::LibXML;
use XML::LibXML::XPathContext;

#join two mpx files
my $home   = $ENV{HOME};
my $file_1 = "$home/M+Export/MIMO/4-lvl2/Copy (2) of join.lvl2.mpx";
my $file_2 = "$home/M+Export/VII_78/4-lvl2/join.lvl2.mpx";

print "parse doc 1\n";
my $dom_1 = XML::LibXML->new();
my $doc_1 = $dom_1->parse_file($file_1);
my $xpc_1 = XML::LibXML::XPathContext->new($doc_1);
$xpc_1->registerNs( 'mpx', 'http://www.mpx.org/mpx' );
#my $root_1 = $dom_1->documentElement();
my $root_1 = $xpc_1->findnodes('/*');

print "parse doc 2\n";

my $dom_2 = XML::LibXML->new();
my $doc_2 = $dom_2->parse_file($file_2);
my $xpc_2 = XML::LibXML::XPathContext->new($doc_2);
$xpc_2->registerNs( 'mpx', 'http://www.mpx.org/mpx' );

print "Try to join\n";

my @nodes_from_2 =
  $xpc_2->findnodes(
'/*/*'
  );

#
foreach my $node (@nodes_from_2) {
	my $type='objId';
	my $id   = $node->find('@objId');
if (! $id) {
		$id=$node->find('@mulId');
		$type='mulId';
}
if (! $id) {
	$id='kueId'.$node->find('@kueId');
		$type='kueId';
}
	print  ("Id: $type $id\n");
	my $xnode=$doc_1->importNode($node);
	$root_1->append($xnode);


}
print "Write new doc\n";

my $state = $doc_1->toFile( 'File3.xml', '1' );

