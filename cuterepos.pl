#!/usr/bin/perl -w
use strict;
use warnings;
use diagnostics;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Curses::UI;
use List::Compare;
use List::Util qw(first);
use Data::Dumper;
use Getopt::Long;

#--------------------------------------------------
# repos.pl definitions
#--------------------------------------------------
my $PKG_QUERYMAKER = "urpmq";
my $QUERYMAKER_PARAM = "--list-media";
my $DLDER = "--wget";
my $REPO_ADDMEDIA = "urpmi.addmedia";
my $REPO_ADDMEDIA_PARAM_DISTRIB = "--distrib";
my $REPO_ADDMEDIA_PARAM_MIRRORLIST = "--mirrorlist";
my $REPO_RMMEDIA = "urpmi.removemedia";
my $REPO_RMMEDIA_ALL = "-a";
my $REPO_ENABLER = "urpmi.update";
my $REPO_PARAM_ACTIVATE = "--no-ignore";
my $REPO_PARAM_DEACTIVATE = "--ignore";
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
    { -label => 'Quit program',       -value => sub {exit(0)}        },
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
         . "CTRL+X: menu  CTRL+Q: quit"
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
    -title => "Mageia Repo Manager - URPMEX Suite",
    %args
);

# ----------------------------------------------------------------------
# Listbox
# ----------------------------------------------------------------------

my $repos = retrieve_medias();
my $activerepos = active_medias();

my @activereposids = (); # active medias at start, used for "diffing"

my @values; #setup in retrieve_medias()
my $labels={};
my $actives={};

for(keys %$repos){
	$labels->{$_} = $repos->{$_};
	for my $item (@$activerepos){
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
    -text => "Below you can select the media you want to enable/disable\n"
	   . "if the list is empty you can add the default ones pressing ^D\n"
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
    -y          => 4,
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
my @inactivereposids = enumerate_unselected_repos();

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
$cui->set_binding( sub { refresh_repos(); }, "\cU" );

# Bind <CTRL+A> to apply changes.
$cui->set_binding( sub { apply_changes(); }, "\cA" );


$w->focus;

$cui->mainloop;

# ----------------------------------------------------------------------
# retrieve the list of all available medias
# ----------------------------------------------------------------------
sub retrieve_medias {
	my $list = undef;
	my $count = 0;
	open(HFILE, $PKG_QUERYMAKER." ".$QUERYMAKER_PARAM."|") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		$list->{$count} = $_;
		push(@values, $count);
		$count++;
	}
	close(HFILE);
	return $list;
}

# ----------------------------------------------------------------------
# return @actives
# ----------------------------------------------------------------------
sub active_medias {
	# active medias
	my $actives = undef;
	open(HFILE, $PKG_QUERYMAKER." ".$QUERYMAKER_PARAM." active |") || die("Can't open stream\n");
	while(<HFILE>){
		chomp $_;
		push @$actives, $_;
	}
	close(HFILE);
	return $actives;
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
# applies all changes
# ----------------------------------------------------------------------
sub apply_changes {
	# current selection
	my @sel = $repoList->get();
	# viene istanziato più sopra, pressi ListBox
	# scope globale
	my @repos = keys %$repos;
	my @currunsel = enumerate_unselected_repos();

	@sel = sort @sel;
	# viene istanziato più sopra, pressi ListBox
	# scope globale
	@activereposids = sort @activereposids;

	my $str = "";

	$str = "TO ENABLE: ";
	my $result = undef;
	for my $repo(@sel){
		# looking for medias that WERE NOT active 
		# the user want to activate them right now
		$result = first { $_ == $repo } @activereposids;
		next if(defined($result)); # it was already active, go on
		$str = $str . $labels->{$repo}.";"; # ready to be activated
		push(@TOENABLE, $labels->{$repo});
	}
	
	$str .= "\n";

	$result = undef;
	$str .= "TO DISABLE: ";
	for my $repo(@currunsel){
		$result = first { $_ == $repo } @inactivereposids;
		next if(defined($result));
		$str = $str . $labels->{$repo}.";";
		push(@TODISABLE, $labels->{$repo});
	}
	
	$cui->dialog($str);
	
	confirmation($str);
}

# ----------------------------------------------------------------------
# Confirmation box
# ----------------------------------------------------------------------

sub confirmation {
		my $str = shift();
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
			-title => "Mageia Repo Manager - URPMEX Suite",
			%arguments
		);
		
		$confirmWindow->add(
			undef, 'Label',
			-text => "Confirm pending operations.\n\n"
			        .$str
			);

		$confirmWindow->add(
			'lbloperations', 'Label',
			-y => 7,
			-width => -1,
			-bold => 1,
			-text => "...",
		);

		sub button_callback($;)
		{
			my $this = shift;
			my $label = $this->parent->getobj('lbloperations');
			if($this->get() == -1){ #confirmed
				$label->text("Processing...");
				for(@TOENABLE){
					print "toggle($_,0)\n";
					#toggle($_,0); # status 0 --> to activate
				}
				for(@TODISABLE){
					print "toggle($_,1)\n";
					#toggle($_,1); # status 1 --> to disable
				}
			}else{
				$w->focus;
				$cui->delete('confirmation_window');
			}
		}

		$confirmWindow->add(
			undef, 'Buttonbox',
			-y => 5,
			-buttons => [
				 {
					-label => "Confirm",
				-value => -1,
				-onpress => \&button_callback,
				},{
					-label => "Cancel",
				-value => 0,
				-onpress => \&button_callback,
				},
			],
		);
		
		$confirmWindow->focus;
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
# returns an array of unselected repos from the listbox
# ----------------------------------------------------------------------
sub enumerate_unselected_repos {
	# ottengo i repository non abilitati/non selezionati
	my @repos = keys %$repos;
	my @sel = $repoList->get();
	my $prevdisabledrepos = List::Compare->new('--unsorted',\@sel,\@repos);
	my @enumeratedrepos = $prevdisabledrepos->get_symmetric_difference();

	return @enumeratedrepos;
}
