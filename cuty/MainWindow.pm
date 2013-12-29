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

package MainWindow;

use strict;
use warnings;
use diagnostics;
use Repositories;
use PackageManager;
use About;

use QtCore4;
use QtGui4;
use QtCore4::debug qw( ambiguous );
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    apply_changes => [];

my ($title);
my $ledtSearch;
my $lstviewPackages;

use Modern::Perl;

sub setupGui {
	# ---------------------------------------
	# gui setup
	# ---------------------------------------
	this->setWindowTitle (Qt::String(this->{title}));
	this->setGeometry(10,10,600,500);
	#this->setFixedSize(200,200);

	my $mainLayout = Qt::VBoxLayout();
	$mainLayout->setContentsMargins(10,10,10,10);

	this->{tab} = Qt::TabWidget(this);

	$mainLayout->addWidget(this->{tab}, 0);

	this->setLayout($mainLayout);

	this->{wdgRepositories} = Repositories(this->{title}." - [Repositories]");
	this->{wdgPackageManager} = PackageManager(this->{title}." - [Package Manager]");
	this->{wdgAbout} = About(this->{title}." - [About]",
				"cuty",
				"0.2",
				"&copy; 2012-2013 by Matteo Pasotti<br />".
				"This is free software GPLv3 licensed",
				"https://github.com/xquiet/urpmex"
				);

	setupTabs();
}

sub setupTabs {
	this->{tab}->setTabPosition(Qt::TabWidget::West());
	this->{tab}->addTab(this->{wdgPackageManager}, "Packages");
	this->{tab}->addTab(this->{wdgRepositories}, "Repositories");
	this->{tab}->addTab(this->{wdgAbout}, "About");
}
sub showWindow {
	this->setVisible(1);
	this->show();
}

sub NEW {
	my ($class, $title) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->setupGui();
	return this;
}

1;
