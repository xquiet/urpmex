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

use Getopt::Long;
#use Data::Dumper;
my $PKG_REMOVER="/usr/sbin/urpme";
my $KRNLTOKEEP=3;
my $force=0;
#my $PKG_REMOVER="echo";
my $result = GetOptions ("kernelstokeep=i" => \$KRNLTOKEEP, # numeric
		      "pkgremover=s" => \$PKG_REMOVER, # string
		      "force" => \$force); # flag
my @commandlist;
my @lista=`rpm -qa kernel-\{server,desktop\}* | egrep -v 'devel|latest'`;
@lista=sort @lista;
my $count=scalar @lista;
my $current=0;
if($count>$KRNLTOKEEP){
	print "SUMMARY OF THE KERNELS (".($count-$KRNLTOKEEP)."/$count) THAT WILL BE REMOVED:\n";
	for(@lista){
		if($current<($count-$KRNLTOKEEP)){
			chomp $_;
			print "$_\n";
			my @args = ("/usr/bin/env", $PKG_REMOVER, "--auto", $_);
			push @commandlist, [ @args ];
		}
		$current++;
	}
}else{
	exit(2);
}
$current=0;
print "Are you sure?\n";
my $char=<STDIN>;
chomp $char;
if(lc($char) eq 'y'){
	for my $aref (@commandlist){
		print "Removing ".@$aref[2]."...\n";
		system(@$aref);
	}
}elsif(lc($char) eq 'n'){
	exit(0);
}
exit(1);

