package urpmex::RPM;

use strict;
use warnings;
use diagnostics;
require Exporter;
use base qw(Exporter);
use urpmex::Shared;
use RPM4;

our @EXPORT = qw(compare_packages
		rpm_name
		rpm_version
		rpm_release
		rpm_epoch
		rpm_fullname);

sub compare_packages {
	my $a = shift();
	my $b = shift();
	# example rpmdev-vercmp 0:1.1-1.mga2 0:1.1-2.mga2
	# 0:1.1-1.mga2 < 0:1.1-2.mga2
	# return 12
	# pk1 --> local
	# pk2 --> remote
	my $pk1;
	my $pk2;
	my $ret;
	if(rpm_epoch($a) eq "(none)"){
		$pk1 = rpm_version($a,1)."-".rpm_release($a,1);
		$pk2 = rpm_version($b,0)."-".rpm_release($b,0);
		return undef if($pk1 eq $pk2);
		$ret = rpmvercmp($pk1, $pk2);
		print "RPMVERCMP($pk1, $pk2)\n";
	}else{
		$pk1 = rpm_epoch($a,1).":".rpm_version($a,1)."-".rpm_release($a,1);
		$pk2 = rpm_epoch($b,0).":".rpm_version($b,0)."-".rpm_release($b,0);
		return undef if($pk1 eq $pk2);
		$ret = RPM4::compare_evr($pk1,$pk2);
		print "COMPAREEVR($pk1, $pk2)\n";
	}
	return $ret;
}

sub rpm_name {
	my $pkg = shift();
	my $is_installed = shift();
	my $name = undef;
	if($is_installed){
		# query local db
		#print "$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $RPM_QUERY_FMT \"%{NAME}\\n\" $pkg 2>/dev/null\n";
		$name = `$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $RPM_QUERY_FMT "%{NAME}\n" $pkg 2>/dev/null`;
	}else{
		# query remote db / urpmq
		my @data = split(':',`$PKG_QUERYMAKER $QUERY_PKG_INFORMATIONS $pkg 2>/dev/null | grep Name | uniq`);
		$name = trim($data[1]);
	}
	chomp $name;
	return $name;
}

sub rpm_version {
	my $pkg = shift();
	my $is_installed = shift();
	my $version = undef;
	if($is_installed){
		# query local db
		$version = `$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $RPM_QUERY_FMT "%{VERSION}\n" $pkg 2>/dev/null`;
	}else{
		# query remote db / urpmq
		my @data = split(':',`$PKG_QUERYMAKER $QUERY_PKG_INFORMATIONS $pkg 2>/dev/null | grep Name | uniq`);
		$version = trim($data[1]);
	}
	chomp $version;
	return $version;
}

sub rpm_release {
	my $pkg = shift();
	my $is_installed = shift();
	my $release = undef;
	if($is_installed){
		# query local db
		$release = `$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $RPM_QUERY_FMT "%{RELEASE}\n" $pkg 2>/dev/null`;
	}else{
		# query remote db / urpmq
		my @data = split(':',`$PKG_QUERYMAKER $QUERY_PKG_INFORMATIONS $pkg 2>/dev/null | grep Name | uniq`);
		$release = trim($data[1]);
	}
	chomp $release;
	return $release;
}

sub rpm_epoch {
	my $pkg = shift();
	my $is_installed = shift();
	my $epoch = undef;
	$epoch = `$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $RPM_QUERY_FMT "%{EPOCH}\n" $pkg 2>/dev/null`;
	chomp $epoch;
	return $epoch;
}

sub rpm_fullname {
	my $name = shift();
	my $full = undef;
	# query local db
	$full = `$RPM_COMMAND $RPM_QUERY $RPM_QUERY_ALL $name 2>/dev/null`;
	chomp $full;
	return $full;
}

1;
