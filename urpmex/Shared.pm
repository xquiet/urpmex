package urpmex::Shared;

require Exporter;
use base qw(Exporter);

use Modern::Perl;
use English qw(-no_match_vars);

our @EXPORT = qw($PKG_QUERYMAKER
		$PKG_INSTALLER
		$RPM_COMMAND
		$RPM_VERCMP
		$RPM_QUERY
		$RPM_QUERY_ALL
		$RPM_QUERY_FMT
		$QUERY_LIST_AVAILABLE_PACKAGES
		$QUERY_LISTMEDIA_PARM
		$QUERY_LISTURL_PARM
		$QUERY_LIST_UPDATES_ONLY
		$QUERY_LOOKFORSRPM_PARM
		$QUERY_PKG_FULL
		$QUERY_PKG_RELEASE
		$QUERY_PKG_GROUP
		$QUERY_PKG_INFORMATIONS
		$QUERY_PKG_DEPENDENCIES
		$INSTALLER_FORCE
		$INSTALLER_AUTO
		$INSTALLER_AUTORESOLVEDEPS
		$INSTALLER_MANUALLYRESOLVEDEPS
		$DLDER
		$REPO_ADDMEDIA
		$REPO_ADDMEDIA_PARAM_DISTRIB
		$REPO_ADDMEDIA_PARAM_MIRRORLIST
		$REPO_RMMEDIA
		$REPO_RMMEDIA_ALL
		$REPO_ENABLER
		$REPO_PARAM_ACTIVATE
		$REPO_PARAM_DEACTIVATE
		$WITH_GROUP
		$WITHOUT_GROUP
		$UPDATES_ONLY
		$RPM_QUERY_NAMEONLY
		$RPM_QUERY_NAME_VERSION_RELEASE
		indexArray
		check_privileges
		trim);


our $PKG_QUERYMAKER = "urpmq";
our $PKG_INSTALLER = "urpmi";
our $RPM_COMMAND = "rpm";
our $RPM_QUERY = "-q";
our $RPM_QUERY_ALL = "-a";
our $RPM_QUERY_FMT = "--qf";
our $QUERY_LIST_AVAILABLE_PACKAGES = "--list";
our $QUERY_LISTMEDIA_PARM = "--list-media";
our $QUERY_LISTURL_PARM = "--list-url";
our $QUERY_LIST_UPDATES_ONLY = "--update";
our $QUERY_LOOKFORSRPM_PARM = "--sourcerpm";
# QUERY_PKG_DEPENDENCIES -d (dependencies) and -m for display what's not already installed
# man urpmq
# -m equivalent to -d -u or -du
# http://wiki.rosalab.ru/en/index.php/Urpmi#Getting_a_list_of_dependencies_before_installing
our $QUERY_PKG_DEPENDENCIES = "-m";
our $QUERY_PKG_FULL = "-f";
our $QUERY_PKG_RELEASE = "-r";
our $QUERY_PKG_GROUP = "-g";
our $QUERY_PKG_INFORMATIONS = "-i";
our $DLDER = "--wget";
# rpmdev-vercmp provided by rpmdevtools
our $RPM_VERCMP = "rpmdev-vercmp";

our $REPO_ADDMEDIA = "urpmi.addmedia";
our $REPO_ADDMEDIA_PARAM_DISTRIB = "--distrib";
our $REPO_ADDMEDIA_PARAM_MIRRORLIST = "--mirrorlist";
our $REPO_RMMEDIA = "urpmi.removemedia";
our $REPO_RMMEDIA_ALL = "-a";
our $REPO_ENABLER = "urpmi.update";
our $REPO_PARAM_ACTIVATE = "--no-ignore";
our $REPO_PARAM_DEACTIVATE = "--ignore";

our $INSTALLER_FORCE = "--force";
our $INSTALLER_AUTO = "--auto";
our $INSTALLER_AUTORESOLVEDEPS = 'A';
our $INSTALLER_MANUALLYRESOLVEDEPS = 'M';

# constants
our $WITH_GROUP = 1;
our $WITHOUT_GROUP = 0;
our $UPDATES_ONLY = 1;
our $RPM_QUERY_NAMEONLY = 1;
our $RPM_QUERY_NAME_VERSION_RELEASE = 2;

# http://www.perlmonks.org/?node_id=66003
sub indexArray{
	1 while $_[0] ne pop;
	@_-1;
}

######################################################
# check_privileges - bool
# @desc if the script is running as root, return true
#       otherwise return false
######################################################

sub check_privileges {
	return $EUID == 0;
}

sub trim {
	my $st = shift();
	$st =~s/^\s*//g;
	$st =~s/\s*$//g;
	return $st;
}
