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

use FindBin;
use lib "$FindBin::RealBin";
use Curses::UI;
use Data::Dumper;
use Getopt::Long;
use Urpmex;

my $HFILE = undef;

my @TOENABLE  = undef;
my @TODISABLE = undef;

#--------------------------------------------------

#--------------------------------------------------
# get options
#--------------------------------------------------
my $use_wget = 0; # false


my $result = GetOptions ("wget" => \$use_wget); 
#--------------------------------------------------

#--------------------------------------------------
# debug
#--------------------------------------------------
my $debug = 1;

# -------------------------------------------------
# gui start
# -------------------------------------------------
# app title
my $app_title = "Mageia Repo Manager - URPMEX Suite";

# window
my $w;

my $cui = new Curses::UI (-clear_on_exit => 1);
#my $cui = new Curses::UI (-clear_on_exit => 1,
#			  -debug => 1);

# splash screen
#$cui->dialog("Welcome in URPMEX");

# ----------------------------------------------------------------------
# Create a menu
# ----------------------------------------------------------------------

my $file_menu = [
    { -label => 'Apply changes <Ctrl+A>', -value => sub { apply_changes() }  },
    { -label => 'Informations <Ctrl+I>',  -value => sub { about() }          },
    { -label => 'Quit program <Ctrl+Q>',  -value => sub {exit(0)}            },
];

my $menu = [
    { -label => 'File',               -submenu => $file_menu         }
];

$cui->add('menu', 'Menubar', -menu => $menu);

# ----------------------------------------------------------------------
# Create the explanation window
# ----------------------------------------------------------------------

my $w0 = $cui->add(
    'w0', 'Window', 
    -border        => 1, 
    -y             => -1, 
    -height        => 3,
);
$w0->add('explain', 'Label', 
  -text => "CTRL+U: refresh medias  CTRL+R: remove all medias  "
         . "CTRL+X: menu  CTRL+Q: quit  CTRL+A: apply changes  "
         . "CTRL+D: add default medias  "
);

my %args = (
    -border       => 1, 
    -titlereverse => 0, 
    -padtop       => 2, 
    -padbottom    => 3, 
    -ipad         => 1,
);

my $id = "main_window";
$w = $cui->add(
	$id, 'Window', 
    -title => $app_title,
    %args
);

# ----------------------------------------------------------------------
# Listbox
# ----------------------------------------------------------------------

my @values; #setup in retrieve_medias()
my $repos = retrieve_medias_hash(\@values);
my @activerepos = active_medias();

my @activereposids = (); # active medias at start, used for "diffing"

my $labels={};
my $actives={};

for(keys %$repos){
	$labels->{$_} = $repos->{$_};
	for my $item (@activerepos){
		if($labels->{$_} eq $item){
			# http://search.cpan.org/~marcus/Curses-UI-0.95/lib/Curses/UI/Listbox.pm#WIDGET-SPECIFIC_OPTIONS
			$actives->{$_} = 1;
			push(@activereposids,$_);
			last;
		}
	}
}

$w->add(
    undef, 'Label',
    -text => "Below you can select the media you want to enable/disable\n",
);

sub listbox_callback()
{
#    my $listbox = shift;
#    my $label = $listbox->parent->getobj('listboxlabel');
#    my @sel = $listbox->get;
#    @sel = ('<none>') unless @sel;
#    my $sel = "selected: " . join (", ", @sel);
#    $label->text($listbox->title . " $sel");
}

my $repoList = $w->add(
    undef, 'Listbox',
    -y          => 3,
    -padbottom  => 2,
    -values     => \@values,
    -labels     => $labels,
    -selected   => $actives,
    #-width      => 20,
    -border     => 1,
    -title      => 'Repositories',
    -vscrollbar => 1,
    -multi      => 1,
    -onchange   => \&listbox_callback,
);

# call enumerate_unselected_repos/get_unselected when listbox instance
# is already populated (the sub rely on this)
my @tmpCurrSel = $repoList->get();
my @tmpAllRepos = keys %$repos;
my @inactivereposids = enumerate_unselected_repos(\@tmpCurrSel, \@tmpAllRepos);

$w->add(
    'listboxlabel', 'Label',
    -y => -1,
    -bold => 1,
    -text => "Select the medias you want to enable and deselect the medias you want to disable.",
    -width => -1,
);

# ----------------------------------------------------------------------
# Setup bindings and focus 
# ----------------------------------------------------------------------

# Bind <CTRL+Q> to quit.
$cui->set_binding( sub{ exit }, "\cQ" );

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );

# Bind <CTRL+U> to refresh repos.
$cui->set_binding( sub { refresh_repos(); confirmation("Repositories updated",1); }, "\cU" );

# Bind <CTRL+A> to apply changes.
$cui->set_binding( sub { apply_changes(); }, "\cA" );

# Bind <CTRL+I> to show informations of the product.
$cui->set_binding( sub { about(); }, "\cI" );


$w->focus;

$cui->mainloop;

# ----------------------------------------------------------------------
# applies all changes
# ----------------------------------------------------------------------
sub apply_changes {
	my @sel = $repoList->get();
	my @repos = keys %$repos;
	my ($TOENABLE, $TODISABLE) = compute_changes(\@sel,\@repos,\@activereposids,\@inactivereposids);
	
	my $str;
	if (defined($TOENABLE)){
		$str = "TOENABLE (".scalar(@$TOENABLE)."): ";
		for(@$TOENABLE){
			$str .= $labels->{$_}."|";
			push(@TOENABLE, $labels->{$_});
		}
	}
	if (defined($TODISABLE)){
		$str .= "\n\nTODISABLE (".scalar(@$TODISABLE)."): ";
		for(@$TODISABLE){
			$str .= $labels->{$_}."|";
			push(@TODISABLE, $labels->{$_});
		}
		#$cui->dialog( $str );
		# removing the first element (undefined)
		shift @TOENABLE;
		shift @TODISABLE;
		confirmation( $str );
	}
}

 #----------------------------------------------------------------------
# Confirmation box
# ----------------------------------------------------------------------

sub confirmation {
		my $str = shift();
		my $singleButton = shift();
		$singleButton = defined($singleButton)?$singleButton:0;
		my $confirmWindow;
		my %arguments = (
			-border       => 1, 
			-titlereverse => 0, 
			-padtop       => 2, 
			-padbottom    => 3, 
			-ipad         => 1,
		);

		my $cid = "confirmation_window";
		$confirmWindow = $cui->add(
			$cid, 'Window', 
			-title => $app_title,
			%arguments
		);
		
		my $confirmation_message;
		my $op_msg;
		if(!$singleButton){
			$confirmation_message = "Confirm pending operations.\n\n";
			$op_msg = "...";
		}else{
			$confirmation_message = "Media Refresh\n\n";
			$op_msg = "";
		}
		$confirmWindow->add(
			undef, 'Label',
			-text => $confirmation_message.$str
			);

		$confirmWindow->add(
			'lbloperations', 'Label',
			-y => 7,
			-width => -1,
			-bold => 1,
			-text => $op_msg,
		);

		sub button_callback($;)
		{
			my $this = shift;
			my $label = $this->parent->getobj('lbloperations');
			if($this->get() == -1){ #confirmed
				$label->text("Processing...");
				if(@TOENABLE){
					for(@TOENABLE){
						next if(!defined($_));
						$label->text("toggle_repo($_,0)\n");
						toggle_repo($_,0); # status 0 --> to activate
					}
				}
				if(@TODISABLE){
					for(@TODISABLE){
						next if(!defined($_));
						$label->text("toggle_repo($_,1)\n");
						toggle_repo($_,1); # status 1 --> to disable
					}
				}
				$label->text("Done!");
				$w->focus;
				$cui->delete('confirmation_window');
			}else{
				$w->focus;
				$cui->delete('confirmation_window');
			}
		}

		my $buttons;
		if(!$singleButton){
			$buttons = [{
					-label => "Confirm",
					-value => -1,
					-onpress => \&button_callback,
					},{
					-label => "Cancel",
					-value => 0,
					-onpress => \&button_callback,
					}];
		}else{
			$buttons = [{
					-label => "Ok",
					-value => -1,
					-onpress => \&button_callback,
					}];
		}

		$confirmWindow->add(
			undef, 'Buttonbox',
			-y => 5,
			-buttons => $buttons,
		);
		
		$confirmWindow->focus;
}

# ----------------------------------------------------------------------
# about box
# ----------------------------------------------------------------------
sub about {
	$cui->dialog("(C) 2012 by Matteo Pasotti <matteo.pasotti\@gmail.com>\n".
		     "License: GPLv3");
}

