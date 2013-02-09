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
# Copyright: 2012-2013 by Matteo Pasotti <matteo.pasotti@gmail.com>
use strict;
use warnings;
use diagnostics;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use urpmex::Urpmex;


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
# params used speed mode
my $e_repolist = undef;
my $d_repolist = undef;
my $repolist = undef;
my $useBackports = undef;
my $useTesting = undef;
my $useDebug = undef;

my $result = GetOptions ("wget" => \$use_wget,
			 "enable=s" => \$e_repolist,
			 "disable=s" => \$d_repolist,
	 		 "backports!" => \$useBackports,
	 		 "testing!" => \$useTesting,
	 		 "debug!" => \$useDebug); 

die("You cannot specify --enable and --disable at the same time\n") if grep($_, $e_repolist, $d_repolist) > 1;

my $toggleValue = undef; # contains the value for toggle_repo routine, see doc header
if(defined($e_repolist)){
	$repolist = $e_repolist;
	$toggleValue = 0;
}elsif(defined($d_repolist)){
	$repolist = $d_repolist;
	$toggleValue = 1;
}

if(defined($repolist)){
	chomp $repolist;
	my $filter = "Updates|Release";
	if($useBackports){
		$filter .= "|Backports";
	}
	if($useTesting){
		$filter .= "|Updates Testing|Release Testing";
		if($useBackports){
			$filter .= "|Backports Testing";
		}
	}
	if($useDebug){
		$filter .= "|Updates Debug|Release Debug";
		if($useTesting){
			$filter .= "|Updates Testing Debug|Release Testing Debug";
		}
		if($useBackports){
			$filter .= "|Backports Debug";
			if($useTesting){
				$filter .= "|Backports Testing Debug";
			}
		}
	}

	my @choices = split(',',$repolist);
	my @repolist = retrieve_medias_array();
	my @selected_medias = ();
	if(check_no_medias(@repolist)){
		die("No medias found");
	}
	# rte = repo to enable
	for my $media(@repolist){
		$media = urpmex::Shared::trim($media);
		if($media eq ""){
			print "An empty media found?!\n";
		}
		for my $rte(@choices){
			$rte = ucfirst($rte);
			if($media =~ /^${rte}\s+($filter)$/g){
				push @selected_medias, $media;
			}
		}
	}

	my @active_medias = active_medias();
	my @medias = ();
	@medias = find_medias_to_enable(\@selected_medias, \@active_medias) if($toggleValue == 0);
	@medias = r_strip_occurrences(\@selected_medias, \@active_medias) if($toggleValue == 1);
	for(@medias){
		print "Enabling repo $_ ...\n" if($toggleValue == 0);
		print "Disabling repo $_ ...\n" if($toggleValue == 1);
		toggle_repo($_,$toggleValue);
	}
	exit(0);
}

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

	# retrieve all medias
	@list = retrieve_medias_array();
	if(check_no_medias(@list)){
		die("No medias found");
	}
	# active medias
	@actives = active_medias();
	
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
	toggle_repo($list[$input-1],$active) if(exists($list[$input-1]));
	return 1;
}

# ----------------------------------------------------------------------
# check if there's no media and ask the user to add them eventually
# ----------------------------------------------------------------------
sub check_no_medias {
	my @list = @_;
	my $input;
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
