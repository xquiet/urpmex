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
use urpmex::Urpmex;


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
	my @media_urls=retrieve_active_media_urls($dl_srpm);
	if(scalar(@pacchetti) gt 0){
		for $pkg(@pacchetti){
			my @lista_srpms;
			if($dl_srpm){
				@lista_srpms = retrieve_srpm_pkgname($pkg);
			}else{
				@lista_srpms = retrieve_brpm_pkgname($pkg);
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
						#print "Protocol: HTTP\n";
						#print "Trying $url/$srpm\n";
						my $check = `curl -s --head "$url/$srpm" | head -n 1 | grep "200 OK" > /dev/null ; echo \$?`;
						chomp $check;
						#print "Result: $check\n";
						if($check eq "0"){
							download($url,$srpm);
							last;
						}
					}elsif($protocol[0] eq "ftp"){
						#print "Protocol: FTP\n";
						my $check = `curl -s --head "$url/$srpm"`;
						$check =~s/\n/ /g;
						$check =~s/^\s+//g;
						$check =~s/\s+$//g;
						if($check ne ""){
							download($url,$srpm);
							last;
						}
					}elsif($protocol[0] eq "rsync"){
						print "Protocol: RSYNC\n";
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

sub download {
	my $url = shift();
	my $rpm = shift();
	if($use_wget){
		`wget "$url/$rpm" -O $rpm`;
	}else{
		`curl -s "$url/$rpm" -o $rpm`;
	}
}

while(main() eq 1){
}

exit(0);
