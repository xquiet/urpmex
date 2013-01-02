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

package Repositories;

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use lib '..';
use urpmex::Urpmex;

use QtCore4;
use QtGui4;
use QtCore4::debug qw( ambiguous );
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    toggle => [],
    get_last_repo_selection => ['const QModelIndex &'];

my ($title);
my $tbvRepositories;
my $lblOperations;

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

	#my $label = Qt::Label(this->{title});
	this->{tbvRepositories} = Qt::TableView();

	this->connect(this->{tbvRepositories},SIGNAL 'clicked()', this, SLOT 'get_last_repo_selection()');

	my $commandBar = Qt::Widget();
	my $commandBarLayout = Qt::HBoxLayout();
	$commandBarLayout->setAlignment(Qt::AlignLeft());
	my $btnToggle = Qt::PushButton("Toggle active/inactive");
	this->{lblOperations} = Qt::Label();

	$commandBarLayout->addWidget($btnToggle);
	$commandBarLayout->addWidget(this->{lblOperations});

	$commandBar->setLayout($commandBarLayout);

	#$mainLayout->addWidget($label, 0, Qt::AlignTop());
	$mainLayout->addWidget(this->{tbvRepositories}, 0);
	#$mainLayout->addWidget($btnToggle, 0, Qt::AlignLeft()|Qt::AlignBottom());
	$mainLayout->addWidget($commandBar, 0, Qt::AlignBottom());

	this->connect($btnToggle,SIGNAL 'clicked()', this, SLOT 'toggle()');

	this->setLayout($mainLayout);

	populatePackageList();
}

sub populatePackageList {
	my $model;
	my $rows = 0;
	my $cols = 2;

	$model = this->{tbvRepositories}->model();
	$model = Qt::StandardItemModel() if(!defined($model));

	$model->clear();

	$model->setColumnCount(2);

	# usefull alternatives
	# to setup column headers text
	#$model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::Object::tr("S")));
	#$model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::Object::tr("Name")));
	#$model->setHorizontalHeaderLabels(["S", "Repo name"]);
	$model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String("S")));
	$model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String("Media name")));

	my @medias = retrieve_medias_array();
	my @actives = active_medias();

	$model->setRowCount(scalar(@medias));
	my $currRow = 0;
	my $currCol = 1;
	for my $media(@medias){
		$currCol = 0;
		my $bgColor;
		my $repoStatus;
		if(grep {$_ eq $media} @actives){
			$bgColor = Qt::Brush($green);
			$repoStatus = "A";
		}else{
			$bgColor = Qt::Brush($gray);
			$repoStatus = "I";
		}
		my $item = Qt::StandardItem();
		#$item->setBackground($bgColor);
		$item->setText($repoStatus);
		$item->setEditable(0);
		$model->setItem($currRow,$currCol,$item);
		$currCol++;
		$item = Qt::StandardItem();
		$item->setBackground($bgColor);
		$item->setText($media);
		$item->setEditable(0);
		$model->setItem($currRow,$currCol,$item);
		$currRow++;
	}
	this->{tbvRepositories}->setModel($model);
	setupTableView();
}

sub setupTableView {
	# adjust tableview settings
	this->{tbvRepositories}->setShowGrid(0);
	this->{tbvRepositories}->setSelectionMode(Qt::AbstractItemView::SingleSelection());
	this->{tbvRepositories}->setColumnWidth(0,20);
	#this->{tbvRepositories}->setColumnWidth(1,this->{tbvRepositories}->width()-80);
	this->{tbvRepositories}->setColumnHidden(0,1);
	adaptTableViewColumns();
}

sub adaptTableViewColumns {
	this->{tbvRepositories}->setColumnWidth(1,this->{tbvRepositories}->width()-20);
}

sub showWindow {
	this->setVisible(1);
	this->show();
}

sub get_last_repo_selection {
	my ($modelindex) = @_;
}

sub toggle {
	my $result;
	my $selectionModel = this->{tbvRepositories}->selectionModel();
	my $selection = $selectionModel->selectedIndexes();
	this->{lblOperations}->setText("Working...");
	Qt::Application::processEvents();
	if($selection && ref $selection eq 'ARRAY'){
		my $media;
		for my $idx(@$selection){
			$media = $idx->sibling($idx->row(), 1)->data()->toString();
			next if($media eq "");
			my $status = $idx->sibling($idx->row(), 0)->data()->toString();
			print Dumper($status);
			if($status eq "A"){
				$result = "Disabled $media";
				toggle_repo($media, 1);
			}else{
				$result = "Enabled $media";
				toggle_repo($media, 0);
			}
			Qt::MessageBox::warning( this, "INFO", $result );
			populatePackageList();
		}
	}else{
		Qt::MessageBox::warning( this, "ERR", "Empty" );
	}
	this->{lblOperations}->setText("");
	Qt::Application::processEvents();
}

sub resizeEvent {
	my ($e) = @_;
	this->SUPER::resizeEvent($e);
	#my $cr = this->contentsRect();
	#this->lineNumberArea->setGeometry(Qt::Rect($cr->left(), $cr->top(), this->lineNumberAreaWidth(), $cr->height()));
	#this->{tbvRepositories}->setColumnWidth(1,this->{tbvRepositories}->width()-80);
	adaptTableViewColumns();
}


sub NEW {
	my ($class, $title) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->setupGui();
	return this;
}

1;
