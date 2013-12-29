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

package About;

use Modern::Perl 2011;
use autodie;
use English qw(-no_match_vars);
use diagnostics;
use lib '..';
use urpmex::Urpmex;

use QtCore4;
use QtGui4;
use QtCore4::debug qw( ambiguous );
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    showwebsite => [];

sub showwebsite {
	my $command = "www-browser ".this->{appwebsite};
	print "running command $command\n";
	system ($command);
}

sub setupGui {
	# ---------------------------------------
	# gui setup
	# ---------------------------------------
	this->setWindowTitle (Qt::String(this->{title}));
	this->setGeometry(10,10,400,500);

	my $mainLayout = Qt::VBoxLayout();
	$mainLayout->setAlignment(Qt::AlignTop());
	$mainLayout->setContentsMargins(10,10,10,10);

	this->{lblAppName} = Qt::Label(this->{appname});
	this->{lblAppVersion} = Qt::Label(this->{appversion});
	this->{lblAppLegal} = Qt::Label(this->{applegal});
	this->{lblAppLegal}->setTextFormat(Qt::RichText());

	this->{btnWebSite} = Qt::PushButton(this->{appwebsite});
	# this->{btnWebSite}->setCursor(Qt::Cursor(Qt::PointingHandCursor()));
	# this->{btnWebSite}->setStyleSheet(this->{lbllink_css});
	this->connect(this->{btnWebSite}, SIGNAL 'clicked()', this, SLOT 'showwebsite()');

	$mainLayout->addWidget(this->{lblAppName}, 0, Qt::AlignTop());
	$mainLayout->addWidget(this->{lblAppVersion}, 0);
	$mainLayout->addWidget(this->{lblAppLegal}, 0, Qt::AlignLeft()|Qt::AlignBottom());
	$mainLayout->addWidget(this->{btnWebSite}, 0, Qt::AlignLeft()|Qt::AlignBottom());

	this->setLayout($mainLayout);
}

sub showWindow {
	this->setVisible(1);
	this->show();
}

sub resizeEvent {
	my ($e) = @_;
	this->SUPER::resizeEvent($e);
}

sub NEW {
	my ($class, $title, $appname, $appver, $appleg, $website) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->{appname} = $appname;
	this->{appversion} = $appver;
	this->{applegal} = $appleg;
	this->{appwebsite} = $website;
	this->{lbllink_css} = "color: rgb(0,0,255); text-decoration: underline;";
	this->setupGui();
	return this;
}

1;
