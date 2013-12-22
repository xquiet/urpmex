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

package PackageManager;

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib '..';
use urpmex::Urpmex;
use urpmex::Shared;

use QtCore4;
use QtGui4;
use QtCore4::debug qw( ambiguous );
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    search_package => [];

use File::Basename;

use Modern::Perl;

my $title;
my $lnedtSearch;
my $tbvPackageList;
my $btnSearch;
my $rdbUpdate;
my $rdbAvailable;
my $btnApply;
my $btnReset;

my $green = Qt::Color(100, 255, 100);
my $gray  = Qt::Color(221, 221, 221);

sub setupGui {
	# ---------------------------------------
	# gui setup
	# ---------------------------------------
	this->setWindowTitle (Qt::String(this->{title}));
	this->setGeometry(10,10,400,500);

	my $mainLayout = Qt::VBoxLayout();
	$mainLayout->setAlignment(Qt::AlignTop());
	$mainLayout->setContentsMargins(10,10,10,10);


	# ------ buttons bar def and layout -------------
	my $buttonsBar = Qt::Widget();
	my $buttonsBarLayout = Qt::HBoxLayout();
	$buttonsBar->setLayout($buttonsBarLayout);

	# ------ command bar def and layout -------------
	my $commandBar = Qt::Widget();
	my $commandBarLayout = Qt::HBoxLayout();
	$commandBar->setLayout($commandBarLayout);

	# ------ options bar def and layout -------------
	my $optionsBar = Qt::Widget();
	my $optionsBarLayout = Qt::HBoxLayout();
	$optionsBar->setLayout($optionsBarLayout);


	# ------ command bar -------------
	this->{lnedtSearch} = Qt::LineEdit();
	this->{btnSearch} = Qt::PushButton("Search");
	$commandBarLayout->setAlignment(Qt::AlignLeft());
	$commandBarLayout->addWidget(this->{lnedtSearch});
	$commandBarLayout->addWidget(this->{btnSearch});

	this->connect(this->{btnSearch}, SIGNAL 'clicked()', this, SLOT 'search_package()');

	# ------ options bar -------------
	this->{rdbUpdates} = Qt::RadioButton("Updates");
	this->{rdbAvailable} = Qt::RadioButton("Available");
	$optionsBarLayout->setAlignment(Qt::AlignLeft());
	$optionsBarLayout->addWidget(this->{lblOperations});
	$optionsBarLayout->addWidget(this->{rdbUpdates});
	$optionsBarLayout->addWidget(this->{rdbAvailable});

	# ------ buttons bar ------------
	this->{btnApply} = Qt::PushButton("Apply");
	this->{btnReset} = Qt::PushButton("Reset");
	$buttonsBarLayout->setAlignment(Qt::AlignRight());
	$buttonsBarLayout->addWidget(this->{btnReset});
	$buttonsBarLayout->addWidget(this->{btnApply});

	# ------ mainlayout -------------
	this->{tbvPackageList} = Qt::TableView();
	setupTable();
	$mainLayout->addWidget($commandBar);
	$mainLayout->addWidget($optionsBar);
	$mainLayout->addWidget(this->{tbvPackageList});
	$mainLayout->addWidget($buttonsBar);

	this->setLayout($mainLayout);
}

sub setupTable {
	my $model = this->{tbvPackageList}->model();
	if(!defined($model)){
		$model = Qt::StandardItemModel();
		this->{tbvPackageList}->setModel($model);
	}else{
		$model->clear();
	}
	$model->setRowCount(0);
	$model->setColumnCount(3);
	# status
	$model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String("S")));
	# group
	$model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String("Group")));
	# package
	$model->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String("Package")));
	this->{tbvPackageList}->setEditTriggers(Qt::AbstractItemView::NoEditTriggers());
	this->{tbvPackageList}->verticalHeader()->hide();
	this->{tbvPackageList}->setColumnWidth(0,20);
	this->{tbvPackageList}->setColumnWidth(1,110);
	this->{tbvPackageList}->setColumnWidth(2,this->{tbvPackageList}->width()-130-10);
}

sub search_package {
	this->{btnSearch}->setEnabled(0);
	setupTable();
	my $model = this->{tbvPackageList}->model();

	if(this->{rdbAvailable}->isChecked()){
		my @list_pkgs = retrieve_available_packages_release($WITH_GROUP);
		my $filter = this->{lnedtSearch}->text();
		my @found = grep { $_ =~ /${filter}/ } @list_pkgs;
		$model->setRowCount(scalar(@found));
		my $row = 0;
		my $col = 0;
		foreach(@found){
			my $chkItem = Qt::StandardItem("");
			# make the first column item checkable (checkbox)
			# http://qt-project.org/doc/qt-4.8/qstandarditem.html#setCheckable
			$chkItem->setCheckable(1);
			$model->setItem($row,$col, $chkItem);
			$col++;
			$model->setItem($row,$col, Qt::StandardItem(dirname($_)));
			$col++;
			$model->setItem($row,$col, Qt::StandardItem(basename($_)));
			$row++;
			$col = 0;
		}
	}elsif(this->{rdbUpdates}->isChecked()){
		my @list_updates = retrieve_available_updates($WITH_GROUP);
	}else{
		Qt::MessageBox::warning(this,"Warning", "No options selected") ;
	}
	this->{btnSearch}->setEnabled(1);
}

sub showWindow {
	this->setVisible(1);
	this->show();
}

sub resizeEvent {
	my ($e) = @_;
	this->SUPER::resizeEvent($e);
	#my $cr = this->contentsRect();
	#this->lineNumberArea->setGeometry(Qt::Rect($cr->left(), $cr->top(), this->lineNumberAreaWidth(), $cr->height()));
	this->{tbvPackageList}->setColumnWidth(2,this->{tbvPackageList}->width()-130);
}


sub NEW {
	my ($class, $title) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->setupGui();
	return this;
}

1;
