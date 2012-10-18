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
use Getopt::Long qw(:config permute);
#use Data::Dumper;


my $PKG_QUERYMAKER = "urpmq";
my $QUERY_LISTMEDIA_PARM = "--list-media";
my $QUERY_LISTURL_PARM = "--list-url";
my $QUERY_LOOKFORSRPM_PARM = "--sourcerpm";
my $DLDER = "--wget";
my $use_wget = 0; # false
my $dl_srpm = 0; # false
my $use_major = 0; # false
my @pacchetti;


sub process_args {
	my $pkg = shift;
	#print "$pkg\n";
	push @pacchetti, $pkg;
}

my $result = GetOptions ("wget" => \$use_wget, 
			 "source" => \$dl_srpm, 
		 	 '<>' => \&process_args,
	 		 "major" => \$use_major); 

sub main {
	my $pkg = "";
	#my @media_urls=`urpmq --list-media active --list-url | awk -F' ' '{gsub(/x86_64|i586/,"SRPMS",\$NF); gsub(/\/media/,"",\$NF); print   \$NF}'`;
	my @media_urls=`$PKG_QUERYMAKER $QUERY_LISTMEDIA_PARM active $QUERY_LISTURL_PARM | awk -F' ' '{print \$NF}'`;
	if(scalar(@pacchetti) gt 0){
		for $pkg(@pacchetti){
			my @lista_srpms;
			if($dl_srpm){
				@lista_srpms = `$PKG_QUERYMAKER $QUERY_LOOKFORSRPM_PARM $pkg | sort -u | grep "$pkg:" | awk -F':' '{print \$2}'`;
			}else{
				@lista_srpms = `$PKG_QUERYMAKER -a -f $pkg | grep "^$pkg" | sort -u`;
			}
			#print "@lista_srpms\n";
			if($use_major){
				#print "Using only major version\n";
				for(my $i=0;$i<scalar(@lista_srpms)-1;$i++){
					shift @lista_srpms;
					#print "@lista_srpms\n";
				}
			}
			for my $srpm(@lista_srpms){
				$srpm =~s/^\s+//g;
				chomp $srpm;
				$srpm = $srpm.".rpm" if(!$dl_srpm);
				print "Processing $srpm\n";
				for my $url(@media_urls){
					chomp $url;
					my @protocol = split(':',$url);
					if($protocol[0] eq "http"){
						if($dl_srpm){
							print "Fixing $url\n";
							$url =~s/x86_64|i586/SRPMS/g;
							$url =~s/\/media//g;
						}
						#print "Trying $url/$srpm\n";
						my $check = `curl -s --head "$url/$srpm" | head -n 1 | grep "200 OK" > /dev/null ; echo \$?`;
						chomp $check;
						#print "Result: $check\n";
						if($check eq "0"){
							print "Found $srpm\n";
							`curl -s $url/$srpm -o $srpm`;
							last;
						}
					}elsif($protocol[0] eq "ftp"){
	
					}elsif($protocol[0] eq "rsync"){
	
					}
					
				}
			}
		}
		return 0;
	}else{
		print "No packages passed as argument\n";
		exit(2);
	}
}

while(main() eq 1){
}

exit(0);
