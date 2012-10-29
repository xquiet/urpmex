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
@ISA = qw(Exporter);
@EXPORT = qw(retrieve_brpm_pkgname
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
             enumerate_unselected_repos);

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use List::Compare;
use List::Util qw(first);

my $PKG_QUERYMAKER = "urpmq";
my $QUERY_LIST_AVAILABLE_PACKAGES = "--list";
my $QUERY_LISTMEDIA_PARM = "--list-media";
my $QUERY_LISTURL_PARM = "--list-url";
my $QUERY_LOOKFORSRPM_PARM = "--sourcerpm";
my $QUERY_PKG_FULL = "-f";
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


# ----------------------------------------------------------------------
# retrieve the list of the available packages - array
# ----------------------------------------------------------------------
sub retrieve_available_packages {
	my $filter_arch = shift();
	my @list_pkgs = `$PKG_QUERYMAKER $QUERY_LIST_AVAILABLE_PACKAGES $QUERY_PKG_GROUP $QUERY_PKG_FULL | sort -u`;
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
	my @currentlyUnselected = enumerate_unselected_repos(\@currSelection, \@allRepos);

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
sub enumerate_unselected_repos {
	# ottengo i repository non abilitati/non selezionati
	my $selection = shift();
	my $repository = shift();
	
	my $previouslyDisabledRepos = List::Compare->new('--unsorted',\@$selection,\@$repository);
	my @enumerated_repos = $previouslyDisabledRepos->get_symmetric_difference();

	return @enumerated_repos;
}


1;
