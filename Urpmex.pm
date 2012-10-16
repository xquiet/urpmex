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
@EXPORT = qw(retrieve_medias_array retrieve_medias_hash active_medias refresh_repos update_repo toggle add_medias remove_medias update_repos);

my $PKG_QUERYMAKER = "urpmq";
my $QUERY_LISTMEDIA_PARM = "--list-media";
my $QUERY_LISTURL_PARM = "--list-url";
my $QUERY_LOOKFORSRPM_PARM = "--sourcerpm";
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
	push(@args, "/usr/bin/env");
	push(@args, $REPO_ENABLER);
	push(@args, $DLDER) if($use_wget);
	push(@args, '-a');
	print "@args\n";
	system(@args);
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
	push(@args, $DLDER) if($use_wget);
	push(@args, $repo);
	print "@args\n";
	return system(@args);
}

# ----------------------------------------------------------------------
# toggle enable/disable repositories
# ----------------------------------------------------------------------
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

1;
