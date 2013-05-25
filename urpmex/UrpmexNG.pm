#!/usr/bin/perl
# vim: set et ts=4 sw=4:
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


package urpmex::UrpmexNG;

require Exporter;
use base qw(Exporter);
use strict;
use warnings;
use diagnostics;
use urpmex::Shared;
use urpmex::RPM;
use POSIX;

use Modern::Perl;

use urpm;
use urpm::cfg;
use urpm::media;

our @EXPORT = qw(
		list_available_media
        list_active_media
        _dbg_show_config
        _dbg_media_read_config
     	     );


####################################################
# == load_urpm_config ==
# @desc It loads the urpm configuration
# @return config hash, the entire urpm configuration
####################################################
sub load_urpm_config {
	my $urpm = new urpm();
	urpm::get_global_options($urpm);
	my $config = urpm::cfg::load_config($urpm->{config});
	return $config;
}

sub _dbg_show_config {
    use Data::Dumper;
    print Dumper(load_urpm_config());
}

sub _dbg_media_read_config {
    my $urpm = new urpm();
    urpm::media::read_config($urpm,0);
    use Data::Dumper;
    print Dumper($urpm);
}

####################################################
# == list_available_media ==
# @desc It returns the complete list of media
# @param status boolean, if true the items of @media 
#                        will contains informations
#                        about the medium status
# @return media array, the complete list of media
####################################################
sub list_available_media {
    my $status = shift;
	my $config = load_urpm_config();
	my $media = $config->{media};
    my @media;
    my $str;
	foreach my $medium (@$media)
	{
        if(defined($medium->{ignore}))
        {
            $str = $medium->{name};
            $str .= ':0' if($status);
        }
        else
        {
            $str = $medium->{name};
            $str .= ':1' if($status);
        }
        push(@media,$str);
        $str = '';
	}
	return @media;
}

####################################################
# == list_active_media ==
# @desc It returns the list of the active media
# @return media array, the list of the active media
####################################################
sub list_active_media {
    my $config = load_urpm_config();
    my $media = $config->{media};
    my @media;
    foreach my $medium (@$media)
    {
        if(!defined($medium->{ignore}))
        {
            push(@media,$medium->{name});
        }
    }
    return @media;
}

1;
