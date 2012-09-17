#!/usr/bin/perl -w
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright: 2012 by Matteo Pasotti <matteo.pasotti@gmail.com>
use strict;
use warnings;
use diagnostics;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
#use Data::Dumper;


my $PKG_QUERYMAKER = "urpmq";
my $QUERYMAKER_PARAM = "--list-media";
my $DLDER = "--wget";
my $REPO_ADDMEDIA = "urpmi.addmedia";
my $REPO_ADDMEDIA_PARAM_DISTRIB = "--distrib";
my $REPO_ADDMEDIA_PARAM_MIRRORLIST = "--mirrorlist";
my $REPO_RMMEDIA = "urpmi.removemedia";
my $REPO_RMMEDIA_ALL = "-a";
my $REPO_ENABLER = "urpmi.update";
my $REPO_PARAM_ACTIVATE = "--no-ignore";
my $REPO_PARAM_DEACTIVATE = "--ignore";
my $HFILE = undef;
my @list = undef;
my @params = undef;
my @actives = undef;
my $PRESENT=undef;
my $item=undef;
my $j=0;
my $k=0;
my $i=1;
my $input = undef;
my $active = undef;
my $count = undef;
my $use_wget = 0; # false


my $result = GetOptions ("wget" => \$use_wget); 

#------------------------ formats -----------------------------------------------
format HEAD=
Elenco dei media disponibili 
Attivi: @#####
$count
---------------------------------------------------------------------------------------------------------------------------
.

format STDOUT=
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
$params[0],                                $params[1],                             $params[2]
.
#---------------------------------------------------------------------------------

sub main {

	@list=();
	@params=();
	@actives=();
	$count=0;
	$input=undef;
	$active=undef;
	$j=0;
	$i=1;
	$k=0;
	$item=undef;
	$PRESENT=undef;

	# all medias
	open(HFILE, $PKG_QUERYMAKER." ".$QUERYMAKER_PARAM."|") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		push @list, $_;
	}
	close(HFILE);
	if(scalar(@list) le 0){
		print "No available medias.\n Do I have to add all the default medias? (Y/n)\n";
		$input=<STDIN>;
		chomp $input;
		if (lc($input) eq "y"){
			return add_medias();
		}else{
			return 0;
		}
	}
	# active medias
	open(HFILE, $PKG_QUERYMAKER." ".$QUERYMAKER_PARAM." active |") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		push @actives, $_;
	}
	close(HFILE);
	
	select(HEAD);
	$count=scalar(@actives);
	write;

	select(STDOUT);
	system('clear');
	
	for(@list){
		$item=$_;
		$j=0 if($j ge 3);
		$PRESENT="[X]" if(grep {$_ eq $item} @actives);
		$PRESENT="[ ]" if(!grep {$_ eq $item} @actives);
		$params[$j]=$i.". $PRESENT ".$_;
		$j++;
		$i++;
		write if($j eq 3);
	}

	if($j lt 3){
		for($k=$j;$k<3;$k++){
			$params[$k]="";
		}
		write;
	}
	
	
	print ": ";
	$input=<STDIN>;
	
	chomp $input;
	return 1 if ($input eq "");
	return 0 if ($input eq "q");
	return add_medias() if ($input eq "amdm");
	return remove_medias() if ($input eq "rmall");
	return update_repos() if ($input eq "u");
	return show_help() if ($input eq "h");

	# out of range
	return 1 if (($input-1) > scalar(grep $_, @list));

	$active=1 if(grep {$_ eq $list[$input-1]} @actives);
	$active=0 if(!grep {$_ eq $list[$input-1]} @actives);
	toggle($list[$input-1],$active) if(exists($list[$input-1]));
	return 1;
}

sub toggle {
	my $repo = shift;
	my $status = shift;
	my @args = ();
	print "Toggle $repo\n";
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	push(@args, $DLDER) if($use_wget);
	push(@args, $REPO_PARAM_ACTIVATE) if($status eq 0);
	push(@args, $REPO_PARAM_DEACTIVATE) if($status eq 1);
	push(@args, $repo);
	print "E' attivo. Procedo alla disattivazione...\n" if($status eq 1);
	print "Non e' attivo. Procedo all'attivazione...\n" if($status eq 0);
	print "@args\n";
	system(@args) || update_repo($repo);
	#readline *STDIN;
	return;
}

sub update_repos {
	my @args = ();
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	push(@args, $DLDER) if($use_wget);
	push(@args, '-a');
	print "@args\n";
	system(@args);
	return 1; # makes main return value 1
}

sub update_repo {
	my $repo = shift;
	my @args = ();
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	push(@args, $DLDER) if($use_wget);
	push(@args, $repo);
	print "@args\n";
	return system(@args);
}

sub add_medias {
	my @args = ();
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ADDMEDIA);
	push(@args, $REPO_ADDMEDIA_PARAM_DISTRIB);
	push(@args, $REPO_ADDMEDIA_PARAM_MIRRORLIST);
	print "@args\n";
	system(@args);
	return 1;
}

sub remove_medias {
	my @args = ();
	print "Are you sure you want to remove ALL medias? Digit YES to confirm, just [Enter] to go back\n";
	my $input = <STDIN>;
	chomp $input;
	return 1 if (uc($input) ne "YES");
	push(@args, "/usr/bin/env");
	push(@args, $REPO_RMMEDIA);
	push(@args, $REPO_RMMEDIA_ALL);
	system(@args);
	return 1;
}

sub show_help {
	system('clear');
	print BRIGHT_BLUE, "Digit the media correspondent number then press ",BOLD,"[Enter]",RESET,BRIGHT_BLUE," to toggle the repo active/inactive\n", RESET;
	print "Press ", BOLD, "q", RESET, " then [Enter] to quit\n";
	print "Press ", BOLD, "u", RESET, " then [Enter] to refresh medias\n";
	print "Press ", BOLD, "h", RESET, " then [Enter] for this help\n";
	print "Press ", BOLD, "amdm", RESET, " then [Enter] to add default medias\n";
	print "Press ", BOLD, "rmall", RESET, " then [Enter] to remove all available medias\n";
	print "Press ", BOLD, "[Enter]", RESET, " to quit this help and go back to the repositories\n";
	print ": ";
	<STDIN>;
	return 1;
}

while(main() eq 1){
}

exit(0);
