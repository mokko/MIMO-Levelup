#!/usr/bin/perl
#VERY QUICK AND VERY DIRTY

use strict;
use warnings;

use Log::Trivial;
use File::Copy;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Cwd;
use File::Basename;
sub message;

# run it inside the dir with the rtf-files without any options
# this script should create a good log
# I assume that this runs under cygwin

# CHANGES
# 2010-12-01
# make it run without all rtf
# use cygpath -wa to determine win path of temp folder
# 2010-06-24
# -changed some paths etc.
# -help section missing
# 2010-04-26
# -I forgot to zip the general log file. Now fixed.
# -I fixed some errors concerning return value of system introduced yesterday
# 2010-04-25
# -fix creates elements in wrong order, implement mpx-sort to fix the fix
# -config hash reorganized
# -bak function implemented backups everything important and only that
# 2010-04-24
# - Forgot to run rtftable2xml.pl with different indexes depending on input file
# - Now logging the output of rtftable2xml.pl
# - fix works
# - validate works (using Oxygen's dotnetValidator TODO)

# TODO (in no particular order)
# 1) put config in separat file to enhance portability DONE
# 2) create pack command so that result is automatically or optionally zipped: replaced by github
# 3) let the script die more often in case of serious errors
# 4) improve error logging
# 5) improve levelup's log messages
# 6) decide if you want to automatically delete rtf2xml log file
# 7) create a new test function which shows what will be done without doing it
# 8) replace dotnetValidator with openSource (xerces, libXML thru perl?)

#all config stuff. Change as necessary

{
        #this has of course serious security concerns!
	package Settings;
	my $settings = "/home/Mengel/usr/levelup/conf/lenny.config";
	die "Error: Don't find settings file " unless -e $settings;
	do $settings
	  or die "Error: Can't load config file!\n";

	#	foreach my $key ( keys %Settings::config ) {
	#		my $value = $Settings::config{$key};
	#		print "-$key --> $value\n";
}

my %config = %Settings::config;
%config = %Settings::config;

if ( !$config{1}{dir} ) { die "Error: Config seems not to work!"; }

my $logger = Log::Trivial->new( log_file => $config{log_fn} );

#
# Process input
#
if ( $ARGV[0] ) {
	if ( $ARGV[0] eq "bak" ) {
		print "go directly to bak test:$ARGV[0]\n";
		bak( \%config );
		exit;
	}
}

#
# MAIN
#

#first: move only correct rtf-files to subdir
##TODO:issue of overwriting currently uncertain
move_rtf( \%config );

#count the RTF-files we got, report result and continue anyways
count_rtf( \%config );

#from rtf to stupid xml
rtftable2xml( \%config );

#join all files on lvl-1
join_lvl1( \%config );

#levelup
lvl1to2( \%config );

#apply fix
fix( \%config );

#VALIDATE
print "About to validate fix\n";
validate("$config{5}{dir}/$config{5}{output_2}");

#bak: at the moment backup (bak) is carried out optionally when

#
# SUBs alphabetically
#

sub bak {
	my $href   = shift;
	my %config = %$href;
	my @now    = localtime(time);
	my $day    = $now[3];
	my $month  = $now[4];
	my $year   = $now[5];
	$year = sprintf( "%02d", $year % 100 );
	$year = "20$year";
	my $date_str = "$year-$month-$day";

	my $keyword;
	if ( $ARGV[1] ) {
		$keyword = "_$ARGV[1]";
	}

	my $bak_fn = basename(getcwd) . "_$year-$month-$day$keyword.zip";
	message "Write zip to $bak_fn\n";

	$main::zip = Archive::Zip->new();

	if ( -e $config{log_fn} ) {
		my $file_member = $main::zip->addFile("$config{log_fn}");
	}

	if ( -e "readme.txt" ) {
		my $file_member = $main::zip->addFile("readme.txt");
	}

	#save only the dirs we made, and the files in them, not recursively!
	my @list = 1 .. 5;
	foreach (@list) {
		my $dir        = $config{$_}{dir};
		my $dir_member = $main::zip->addDirectory("$dir/");
		my @files      = read_dir($dir);
		foreach (@files) {
			print "compressing $dir/$_ ...\n";
			my $file_member = $main::zip->addFile("$dir/$_");

		}
	}

	# Save the Zip file
	unless ( $main::zip->writeToFileNamed($bak_fn) == AZ_OK ) {
		die 'write error';
	}
}

sub count_rtf {
	my $href   = shift;
	my %config = %$href;
	my @found;    #those files which are actually found in pwd.
	my $wdir = $config{1}{dir};

	if ( !-d $wdir ) {
		message "Count: $wdir dir not found";
		return;
	}
	my @files = read_dir($wdir);
	my $count = 0;

	#print "test @files\n";
	foreach my $test ( @{ $config{basenames} } ) {
		my $this = 0;
		foreach my $file (@files) {

			#print "testfile $file $test\n";
			if ( "$test.rtf" =~ /$file/i ) {
				push @found, $file;

				#print "found $file\n";
				++$count;
				$this++
			}
		}
		if ($this == 0) {
			print "$test not identified as rtf\n";
		}
	}
	if ( $count < 7 ) {
		message
		  "Warning: RTF Level incomplete. Only $count of 7 files available!\n";
	}
	elsif ( $count == 7 ) {
		print "\tok\n";
	}
	elsif ( $count > 7 ) {

		#could happen with different cases in a non-cygwin environment
		die "Error: Something is strange. More files than there should be!";
	}
}

sub fix {
	my $href            = shift;
	my %config          = %$href;
	my $saxon           = $config{saxon_cmd};
	my $wdir            = $config{5}{dir};
	my $previous_dir    = $config{4}{dir};
	my $previous_output = "$config{4}{dir}/$config{4}{output}";

	my $output1_fn = $config{5}{output_1};
	my $output2_fn = $config{5}{output_2};
	my $log_fn     = $config{5}{log_fn};

	mk_dir($wdir);

	print "Check if fix exists already ...\n";
	if ( !-e "$wdir/$output1_fn" ) {
		my $cmd = "$saxon -xsl:'$config{5}{fix_xsl}' ";
		$cmd .= "-s:$previous_output ";
		$cmd .= "-o:'$wdir\\$output1_fn' ";
		$cmd .= "2>'$wdir\\$log_fn'";
		system($cmd);

		my $ret = $? >> 8;
		if ( $ret != 0 ) {
			die "system $cmd failed: $?";
		}

	}

	#fix the fix
	print "Check if fix is sorted already ...\n";

	if ( !-e "$wdir/$output2_fn" ) {
		print "\tNeed to sort\n";
		my $cmd = "$saxon -xsl:'$config{5}{mpxsort_xsl}' ";
		$cmd .= "-s:'$wdir\\$output1_fn' ";
		$cmd .= "-o:'$wdir\\$output2_fn' ";
		$cmd .= "2>>'$wdir\\$log_fn'";
		#print "DEBUG $cmd\n";
		system($cmd);
		my $ret = $? >> 8;

		if ( $ret != 0 ) {
			die "system $cmd failed: $?";
		}
	}
	else {
		print "\texists already\n";
	}
}

sub validate {
	my $file = shift;

	#	my $alt="$wdir\\$config{5}{output_2}";
	system("$config{validator} '$file' --auto");
	my $ret = $? >> 8;
	print "ret validate: $ret\n";
	if ( $ret eq 0 ) { message "Validate $file successful"; }
	else { message "Validate $file NOT successful"; }

	return $ret;
}

sub join_lvl1 {
	my $href         = shift;
	my %config       = %$href;
	my $wdir         = $config{3}{dir};
	my $previous_dir = $config{2}{dir};

	my $output   = "$wdir/$config{3}{output}";    #fully qualified linux path
	my $leer_xml = $config{3}{leer_xml};
	my $saxon    = $config{saxon_cmd};

	#java wants stupid windows path
	#this is soooo dirty....

	#maybe I should be joining with libxml2 instead instead of xslt
	#why is there no saxon module in cpan at all?

	mk_dir($wdir);
	print "Check if lvl1-join exists already ...\n";

	if ( -e $output ) {
		print "\t$output exists already\n";
		return;
	}

	#cp empty B
	#foreach part (list)
	#  join (part,B) > C
	#  mv C B
	#mv B to $output

	copy( $leer_xml, "$config{3}{temp_cyg}/B.xml" )
	  or die "Cannot copy $leer_xml to temp!";

	#determine win path for saxon
	my $temp_win = `cygpath -wa $config{3}{temp_cyg}`;
	$temp_win =~ s/\s+$//;

	#Debug
#	print "DDD: temp_win:$temp_win\n";

	foreach my $file ( @{ $config{basenames} } ) {
		my $source = "$previous_dir/$file.xml";
		if ( -e $source ) {
			print "DEBG: $source found\n";
			message "\tJoining $source";
			my $cmd = "$saxon -xsl:'$config{3}{join_xsl}' ";
			$cmd .= "-s:$source ";
			#path to B is relative from xsl
			$cmd .= "-o:'$temp_win\\C.xml'";

			#$cmd .= "2>>'$config{dirs}[4]\\join.log'";

			print "debug $cmd\n";
			system($cmd);
			my $ret = $? >> 8;
			if ( $ret != 0 ) {
				die "system $cmd failed: $?";
			}

			move( "$config{3}{temp_cyg}/C.xml", "$config{3}{temp_cyg}/B.xml" );

			#debug: keep a cp of every step
			#copy( "$config{3}{temp_cyg}/B.xml", "$config{3}{temp_cyg}/t_$file.xml" );
		}
	}
	#after your done with joining everything in temp, mv it to final destination
	copy( "$config{3}{temp_cyg}/B.xml", $output );
}

sub lvl1to2 {
	my $href            = shift;
	my %config          = %$href;
	my $wdir            = $config{4}{dir};
	my $output_fn       = $config{4}{output};
	my $log_fn          = $config{4}{log_fn};
	my $previous_dir    = $config{3}{dir};
	my $previous_output = "$config{3}{dir}/$config{3}{output}";
	my $levelup_xsl     = $config{4}{levelup_xsl};
	my $saxon           = $config{saxon_cmd};

	my $cmd = "$saxon -xsl:'$levelup_xsl' ";
	$cmd .= "-s:$previous_output ";
	$cmd .= "-o:'$wdir\\$output_fn' ";
	$cmd .= "2>'$wdir\\$log_fn'";

	#automatically overwrite the log the next time

	#todo: write fix log in file
	#print "\t\tDEBUG: $cmd\n";

	print "Check if lvl2 exists already ...\n";
	mk_dir($wdir);
	if ( !-e "$wdir/$output_fn" ) {
		print "About to $cmd";
		system($cmd);

		my $ret = $? >> 8;
		if ( $ret != 0 ) {
			die "system $cmd failed: $?";
		}

	}
}

sub message {
	my $message = shift;
	print $message. "\n";
	$logger->write($message);

}

sub move_rtf {
	my $href   = shift;
	my %config = %$href;
	my $wdir   = $config{1}{dir};

	print "Check if there is a RTF to move...\n";

	#first thing: look for right RTF files and move them to directory
	my @files = read_dir('.');
	foreach my $test ( @{ $config{basenames} } ) {
		foreach my $file (@files) {

			#		print "$test.rtf == $file\n";
			if ( "$test.rtf" =~ /$file/i ) {

				#silently convert filename to small letters in extension
				my $target = "$wdir/$test.rtf";
				mk_dir($wdir);

				#should we overwrite existing files or check before doing so?
				#now we just overwrite it!
				move( $file, $target )
				  or die "Error: Cannot move files ($file $target)";
				message "mv $file $target";
			}
		}
	}
}

sub mk_dir {
	my $dir = shift;
	if ( !-e $dir ) {
		mkdir($dir);
		message "mkdir ($dir)";
	}
}

sub read_dir {
	my $dir = shift;
	opendir( my $dh, $dir ) or die "Error: Can't opendir $dir: $!";
	my @files =
	  grep { !/^\./ && -f "$dir/$_" }
	  readdir($dh);    #ignore dots and files beginning with dots
	closedir $dh;

	#	print "read_dir($dir):";
	#	foreach (@files) {
	#		print "$_ ";
	#	}
	#	print "\n";

	return @files;
}

sub rtftable2xml {
	my $href         = shift;
	my %config       = %$href;
	my $previous_dir = $config{1}{dir};
	my $wdir         = $config{2}{dir};
	my $log_fq       = "$wdir/$config{2}{log_fn}";
	my $rtf2xml      = $config{2}{rtf2xml};

	mk_dir($wdir);
	if ( -e $log_fq ) {

		#print "Debug: log";
		unlink $log_fq;
	}
	print "Check if a rtf needs conversion ...\n";
	foreach ( @{ $config{basenames} } ) {

		#this is cheating, but who cares
		#instead it should be part of the config
		#assume that the index is objId
		my $index = 'objId';
		if ( $_ =~ /perkor/i ) {
			$index = 'kueId';
		} elsif ( $_ =~ /mume/i ) {
			$index = 'mulId';
		}

		#message "Debug:Using $index as index";
		#make new xml file only if it does not exist already; no overwrite
		if ( -f "$previous_dir/$_.rtf" && !-e "$wdir/$_.xml" ) {
			message "start rtftable2xml $_.rtf";
			my $cmd = "$rtf2xml -l -I $index ";
			$cmd .= "-f $previous_dir/$_.rtf ";
			$cmd .= "-o $wdir/$_.xml 2>>$log_fq";
			system($cmd);
			my $ret = $? >> 8;
			if ( $ret != 0 ) {
				die "system $cmd failed: $?";
			}
		}
	}
	print "\tok\n";
}

=head1 NAME

levelup.pl - Take specific tables in RTF as input and output MPX-lvl2.

=head1 DESCRIPTION

The function of this is to digest rtf input and output good xml; it's also to organize this process in a simple way (prepare bak).

=head1 USAGE

levelup.pl
levelup.pl bak

Execute the script inside the directory with the rtf files, usually without any options. Script will look for a specific set of files. Configuration through configuration file usually in conf dir.

=head1 CONFIGURATION


a) set $settings::settings in this script (if necessary) to point to the actual settings file


b) set the actual settings in that file. No documentation at the moment. I try to provide a commented example file


=head1 COMMAND LINE OPTIONS

bak - pack relevant files into a zip file

=head1 DIRECTORY STRUCTURE

This script assumes a specific directory structure which can be modified to some extent by the configuration. It looks for rtf files in the directory that it is executed in and will create various directories depending on the progress it makes when it is executing.

Eseentially this script evokes a series of transformations. For every step of this transformation, a directory created, usually the directory names should contain numbers which make the order exceedingly obvious to everybody.

=head1 AUTHOR

Maurice Mengel <mauricemengel@gmail.com> for MIMO (http://mimo-project.eu).

=head1 COPYRIGHT

Copyright 2010 Maurice Mengel

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut