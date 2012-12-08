#!/usr/bin/perl
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


package Urpmex;

require Exporter;
use base qw(Exporter);
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use List::Compare;
use List::Util qw(first);

our @EXPORT = qw(retrieve_available_updates
             retrieve_available_packages_full
	     retrieve_available_packages_release
	     retrieve_brpm_pkgname
             retrieve_srpm_pkgname
	     retrieve_active_media_urls
	     retrieve_medias_array 
	     retrieve_medias_hash 
	     active_medias 
             refresh_repos 
             update_repo 
             toggle_repo 
             add_medias 
             remove_medias 
             update_repos
             compute_changes
             enumerate_symm_diff
	     $WITH_GROUP
	     $WITHOUT_GROUP
	     $UPDATES_ONLY
     	     );

my $PKG_QUERYMAKER = "urpmq";
my $RPM_COMMAND = "rpm";
my $RPM_QUERY = "-q";
my $RPM_QUERY_ALL = "-a";
my $RPM_QUERY_FMT = "--qf";
my $QUERY_LIST_AVAILABLE_PACKAGES = "--list";
my $QUERY_LISTMEDIA_PARM = "--list-media";
my $QUERY_LISTURL_PARM = "--list-url";
my $QUERY_LIST_UPDATES_ONLY = "--update";
my $QUERY_LOOKFORSRPM_PARM = "--sourcerpm";
my $QUERY_PKG_FULL = "-f";
my $QUERY_PKG_RELEASE = "-r";
my $QUERY_PKG_GROUP = "-g";
my $DLDER = "--wget";

my $REPO_ADDMEDIA = "urpmi.addmedia";
my $REPO_ADDMEDIA_PARAM_DISTRIB = "--distrib";
my $REPO_ADDMEDIA_PARAM_MIRRORLIST = "--mirrorlist";
my $REPO_RMMEDIA = "urpmi.removemedia";
my $REPO_RMMEDIA_ALL = "-a";
my $REPO_ENABLER = "urpmi.update";
my $REPO_PARAM_ACTIVATE = "--no-ignore";
my $REPO_PARAM_DEACTIVATE = "--ignore";

# constants
our $WITH_GROUP = 1;
our $WITHOUT_GROUP = 0;
our $UPDATES_ONLY = 1;
our $RPM_QUERY_NAMEONLY = 1;

# ----------------------------------------------------------------------
# find available updates - array
# ----------------------------------------------------------------------
sub retrieve_available_updates {
	my @installed = retrieve_installed_packages($RPM_QUERY_NAMEONLY);
	my @availables = retrieve_available_packages_release($WITHOUT_GROUP,$UPDATES_ONLY);
	my @intermediate = enumerate_symm_diff(\@installed, \@availables);
	print "INTERMEDIATE\n";
	print Dumper(@intermediate);
	print "INSTALLED\n";
	print Dumper(@installed);
	my @updates = enumerate_intersection(\@installed, \@intermediate);
	return @updates;
}

sub wrap_retrieve_installed_packages {
	my $nameonly = shift();
	my @args;
	my $command = "$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL";
	if(defined($nameonly) && ($nameonly == $RPM_QUERY_NAMEONLY)){
		push @args, "$RPM_QUERY_FMT \"%{NAME}\n\"";
	}
	$command = $command . " " . join(" ", @args);
	return $command;
}

# ----------------------------------------------------------------------
# retrieve installed packages - array
# ----------------------------------------------------------------------
sub retrieve_installed_packages {
	my $nameonly = shift();
	my $command = wrap_retrieve_installed_packages($nameonly);
	my @list = `$command`;
	chomp @list;
	return @list;
}

# ----------------------------------------------------------------------
# wrap command retrieve_available_packages
# @parm full   bool   if you want full output from urpmq
# @parm group  bool   if you want group output from urpmq
# @parm update bool   if you want to list updates only
# ----------------------------------------------------------------------
sub wrap_retrieve_available_packages {
	my $full = shift();
	my $group = shift();
	my $update = shift();
	my @args;
	my $command = $PKG_QUERYMAKER;
	push @args, $QUERY_LIST_AVAILABLE_PACKAGES;
	if(defined($update) && ($update == $UPDATES_ONLY)){
		push @args, $QUERY_LIST_UPDATES_ONLY;
	}
	if(defined($group) && ($group == $WITH_GROUP)){
		push @args, $QUERY_PKG_GROUP;
		print "Added -g\n";
	}
	if($full){
		push @args, $QUERY_PKG_FULL;
	}else{
		push @args, $QUERY_PKG_RELEASE;
	}
	$command = $command ." ". join(" ",@args) . "| sort -u";
	return $command;
}

# ----------------------------------------------------------------------
# retrieve the list of the available packages - array
# NOTE: no arch specified!
# ----------------------------------------------------------------------
sub retrieve_available_packages_release {
	my $group = shift();
	my $update = shift();
	my $command = wrap_retrieve_available_packages(0,$group,$update);
	my @list_pkgs = `$command`;
	chomp @list_pkgs;
	return @list_pkgs;
}

# ----------------------------------------------------------------------
# retrieve the list of the available packages - array
# NOTE: with arch specified
# ----------------------------------------------------------------------
sub retrieve_available_packages_full {
	my $group = shift();
	my $update = shift();
	my $command = wrap_retrieve_available_packages(1,$group,$update);
	my @list_pkgs = `$command`;
	chomp @list_pkgs;
	return @list_pkgs;
}

# ----------------------------------------------------------------------
# retrieve the binary rpm's pkg name - array
# ----------------------------------------------------------------------
sub retrieve_brpm_pkgname {
	my $pkg = shift();
    my @lista_brpms = `$PKG_QUERYMAKER -a $QUERY_PKG_FULL $pkg | grep "^$pkg" | sort -u`;
    return @lista_brpms;
}

# ----------------------------------------------------------------------
# retrieve the srpm's pkg name - array
# ----------------------------------------------------------------------
sub retrieve_srpm_pkgname {
	my $pkg = shift();
	my @lista_srpms = `$PKG_QUERYMAKER $QUERY_LOOKFORSRPM_PARM $pkg | sort -u | grep "$pkg:" | awk -F':' '{print \$2}'`;
	return @lista_srpms;
}

# ----------------------------------------------------------------------
# retrieve the urls of all the active medias - array
# ----------------------------------------------------------------------
sub retrieve_active_media_urls {
	my $dl_srpm = shift();
	my $awkFilter;
	if($dl_srpm){
		$awkFilter = "awk -F' ' '{gsub(/x86_64|i586/,\"SRPMS\",\$NF); gsub(/\\/media/,\"\",\$NF); print \$NF}'";
	}else{
		$awkFilter = "awk -F' ' '{print \$NF}'";
	}
	my @medias = `$PKG_QUERYMAKER $QUERY_LISTMEDIA_PARM active $QUERY_LISTURL_PARM | $awkFilter`;
	#if($dl_srpm){
	#	print "Fixing $url\n";
	#	$url =~s/x86_64|i586/SRPMS/g;
	#	$url =~s/\/media//g;
	#}
	return @medias;
}

# ----------------------------------------------------------------------
# retrieve the list of all available medias - array
# ----------------------------------------------------------------------
sub retrieve_medias_array {
	my @list;
	open(HFILE, $PKG_QUERYMAKER." ".$QUERY_LISTMEDIA_PARM."|") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		push @list, $_;
	}
	close(HFILE);
	return @list;
}

# ----------------------------------------------------------------------
# retrieve the list of all available medias - hash
# ----------------------------------------------------------------------
sub retrieve_medias_hash {
	my $values = shift;
	$values = defined($values)?$values:undef;
	my $list = undef;
	my $count = 0;
	open(HFILE, $PKG_QUERYMAKER." ".$QUERY_LISTMEDIA_PARM."|") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		$list->{$count} = $_;
		push(@$values, $count);
		$count++;
	}
	close(HFILE);
	return $list;
}

# ----------------------------------------------------------------------
# return actives medias - array
# ----------------------------------------------------------------------
sub active_medias {
	my @actives;
	open(HFILE, $PKG_QUERYMAKER." ".$QUERY_LISTMEDIA_PARM." active |") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		push @actives, $_;
	}
	close(HFILE);
	return @actives;
}

# ----------------------------------------------------------------------
# alias refresh_repos
# ----------------------------------------------------------------------
sub update_repos {
	return refresh_repos();
}

# ----------------------------------------------------------------------
# refresh medias
# ----------------------------------------------------------------------
sub refresh_repos {
	my @args = ();
	local (*OUT, *ERR);
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	#push(@args, $DLDER) if($use_wget);
	push(@args, '-a');
	print "@args\n";
	open OUT, ">&STDOUT";
	open ERR, ">&STDERR";
	close STDOUT;
	close STDERR;
	system(@args);
	open STDOUT, ">&OUT";
	open STDERR, ">&ERR";
	return 1; # makes main return value 1
}

# ----------------------------------------------------------------------
# refresh single media
# ----------------------------------------------------------------------
sub update_repo {
	my $repo = shift;
	my @args = ();
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	#push(@args, $DLDER) if($use_wget);
	push(@args, $repo);
	print "@args\n";
	return system(@args);
}

# ----------------------------------------------------------------------
# toggle_repo enable/disable repositories
# @param repo   string     the name of the repository
# @param status int/bool   0 to activate, 1 to disable
# ----------------------------------------------------------------------
sub toggle_repo {
        my $repo = shift;
        my $status = shift;
        my @args = ();
        print "Toggle $repo\n";
        push(@args, "/usr/bin/env");
        push(@args, $REPO_ENABLER);
        #push(@args, $DLDER) if($use_wget);
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

# ----------------------------------------------------------------------
# add repositories
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# remove repositories
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# medias activation/deactivation based on previous and current selections
# ----------------------------------------------------------------------
sub compute_changes {
	# current selection ref
	my $s = shift();
	my @currSelection = @$s;
	# complete list of repos
	my $r = shift();
	my @allRepos = @$r;
	# repository active at startup
	my $activerepos = shift();
	my @ids_of_active_repos = sort @$activerepos;
	# repository inactive at startup
	my $inactiverepos = shift();
	my @ids_of_inactive_repos = sort @$inactiverepos;
	# current unselected repos
	my @currentlyUnselected = enumerate_symm_diff(\@currSelection, \@allRepos);

	my @MEDIASTOENABLE;
	my @MEDIASTODISABLE;

	@currSelection = sort @currSelection;

	my $res = undef;
	my $fA=0;
	for my $media(@currSelection){
		# looking for medias that WERE NOT active 
		# the user want to activate them right now
		$res = first { $_ == $media } @ids_of_active_repos;
		next if(defined($res)); # it was already active, go on
		push(@MEDIASTOENABLE, $media);
		$fA=1;
	}

	$res = undef;
	my $fB=0;
	for my $media(@currentlyUnselected){
		$res = first { $_ == $media } @ids_of_inactive_repos;
		next if(defined($res));
		push(@MEDIASTODISABLE, $media);
		$fB=1;
	}
	
	return (undef, undef) if(($fA == 0)&&($fB == 0));
	return (\@MEDIASTOENABLE, \@MEDIASTODISABLE);
}

# ----------------------------------------------------------------------
# returns an array of unselected repos from the list
# ----------------------------------------------------------------------
sub enumerate_symm_diff {
	# ottengo i repository non abilitati/non selezionati
	my $selection = shift();
	my $repository = shift();
	
	my $previouslyDisabledRepos = List::Compare->new('--unsorted',\@$selection,\@$repository);
	my @enumerated_repos = $previouslyDisabledRepos->get_symmetric_difference();

	return @enumerated_repos;
}

# ----------------------------------------------------------------------
# returns the union of two lists - array
# ----------------------------------------------------------------------
sub enumerate_union {
	my $first_set = shift();
	my $second_set = shift();
	my $union = List::Compare->new('--unsorted',\@$first_set,\@$second_set);
	my @enumeration = $union->get_union();
	return @enumeration;
}

# ----------------------------------------------------------------------
# returns the intersection of two lists - array
# ----------------------------------------------------------------------
sub enumerate_intersection {
	my $first_set = shift();
	my $second_set = shift();
=comment
	my $intersection = List::Compare->new('--unsorted',\@$first_set,\@$second_set);
	my @enumeration = $intersection->get_intersection();
=cut
	my @enumeration;
	for my $pattern(@$first_set){
		push @enumeration, grep { $_ =~ /${pattern}\-/g } @$second_set;
	}
	return @enumeration;
}

1;
