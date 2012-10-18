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

package MainWindow;

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib '..';
use Urpmex;

use QtCore4;
use QtGui4;
use QtCore4::debug qw( ambiguous );
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    apply_changes => [];

my ($title);
my $ledtSearch;
my $lstviewPackages;

sub setupGui {
	# ---------------------------------------
	# gui setup
	# ---------------------------------------
	this->setWindowTitle (Qt::String(this->{title}));
	this->setGeometry(10,10,400,500);
	#this->setFixedSize(200,200);

	my $mainLayout = Qt::VBoxLayout();
	#$mainLayout->setAlignment(Qt::AlignTop());
	$mainLayout->setContentsMargins(10,10,10,10);
	my $optionsLayout = Qt::HBoxLayout();

	my $label = Qt::Label(this->{title});
	this->{ledtSearch} = Qt::LineEdit();
	this->{lstviewPackages} = Qt::ListView();
	my $btnApply = Qt::PushButton("Apply");

	my $wdg_options = Qt::Widget();
	my $rdbUpdates = Qt::RadioButton("Updates");

	$optionsLayout->addWidget($rdbUpdates);

	$wdg_options->setLayout($optionsLayout);

	$mainLayout->addWidget($label, 0, Qt::AlignTop());
	$mainLayout->addWidget(this->{ledtSearch}, 0, Qt::AlignTop());
	$mainLayout->addWidget($wdg_options, 0, Qt::AlignTop());
	$mainLayout->addWidget(this->{lstviewPackages}, 0, Qt::AlignTop());
	$mainLayout->addWidget($btnApply, 0, Qt::AlignCenter());

	this->connect($btnApply,SIGNAL 'clicked()', this, SLOT 'apply_changes()');

	this->setLayout($mainLayout);

	populatePackageList();
}

sub populatePackageList {
	my $model;
	$model = this->{lstviewPackages}->model();
	$model = Qt::StringListModel() if(!defined($model));
	$model->setStringList(["prova", "prova", "prova"]);
	this->{lstviewPackages}->setModel($model);
}

sub showWindow {
	this->setVisible(1);
	this->show();
}

sub apply_changes {
	this->{ledtSearch}->setText("PROVA");
}

sub NEW {
	my ($class, $title) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->setupGui();
	return this;
}

1;
