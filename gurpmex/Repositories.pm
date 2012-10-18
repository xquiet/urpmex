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

package Repositories;

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
    apply_changes => [],
    get_last_repo_selection => ['const QModelIndex &'];

my ($title);
my $tbvRepositories;

sub setupGui {
	# ---------------------------------------
	# gui setup
	# ---------------------------------------
	this->setWindowTitle (Qt::String(this->{title}));
	this->setGeometry(10,10,400,500);

	my $mainLayout = Qt::VBoxLayout();
	$mainLayout->setAlignment(Qt::AlignTop());
	$mainLayout->setContentsMargins(10,10,10,10);

	my $label = Qt::Label(this->{title});
	this->{tbvRepositories} = Qt::TableView();
	this->{tbvRepositories}->setShowGrid(0);

	this->connect(this->{tbvRepositories},SIGNAL 'clicked()', this, SLOT 'get_last_repo_selection()');

	my $btnToggle = Qt::PushButton("Toggle active/inactive");

	$mainLayout->addWidget($label, 0, Qt::AlignTop());
	$mainLayout->addWidget(this->{tbvRepositories}, 0);
	$mainLayout->addWidget($btnToggle, 0, Qt::AlignLeft()|Qt::AlignBottom());

	this->connect($btnToggle,SIGNAL 'clicked()', this, SLOT 'apply_changes()');

	this->setLayout($mainLayout);

	populatePackageList();

	this->{tbvRepositories}->setColumnWidth(0,20);
	this->{tbvRepositories}->setColumnWidth(1,this->{tbvRepositories}->width()-80);
}

sub populatePackageList {
	my $model;
	my $rows = 0;
	my $cols = 2;

	$model = this->{tbvRepositories}->model();
	$model = Qt::StandardItemModel() if(!defined($model));

	#$model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::Object::tr("S")));
	#$model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::Object::tr("Name")));
	$model->setHorizontalHeaderLabels(["S", "Name"]);

	my @medias = retrieve_medias_array();
	my @actives = active_medias();

	$model->setRowCount(scalar(@medias));
	$model->setColumnCount(2);
	my $currRow = 0;
	my $currCol = 1;
	for my $media(@medias){
		$currCol = 0;
		my $bgColor;
		if(grep {$_ eq $media} @actives){
			#$bgColor = Qt::Brush(Qt::green());
			$bgColor = Qt::Brush(Qt::Color(100, 255, 100));
		}else{
			#$bgColor = Qt::Brush(Qt::gray());
			$bgColor = Qt::Brush(Qt::Color(221, 221, 221));
		}
		my $item = Qt::StandardItem();
		$item->setBackground($bgColor);
		$item->setText("");
		$item->setEditable(0);
		$model->setItem($currRow,$currCol,$item);
		$currCol++;
		$item = Qt::StandardItem();
		#$item->setBackground($bgColor);
		$item->setText($media);
		$item->setEditable(0);
		$model->setItem($currRow,$currCol,$item);
		$currRow++;
	}
	this->{tbvRepositories}->setModel($model);
}

sub showWindow {
	this->setVisible(1);
	this->show();
}

sub get_last_repo_selection {
	my ($modelindex) = @_;
}

sub apply_changes {
	this->{ledtSearch}->setText("PROVA");
}

sub resizeEvent {
	my ($e) = @_;
	this->SUPER::resizeEvent($e);
	#my $cr = this->contentsRect();
	#this->lineNumberArea->setGeometry(Qt::Rect($cr->left(), $cr->top(), this->lineNumberAreaWidth(), $cr->height()));
	this->{tbvRepositories}->setColumnWidth(1,this->{tbvRepositories}->width()-80);
}


sub NEW {
	my ($class, $title) = @_;
	$class->SUPER::NEW();
	this->{title} = $title;
	this->setupGui();
	return this;
}

1;
