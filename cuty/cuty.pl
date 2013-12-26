#!/usr/bin/perl
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

use strict;
use warnings;
use Modern::Perl;
use QtCore4;
use QtGui4;
use MainWindow;
use Repositories;

sub main
{
	my $title = "URPMEX Suite - Graphical Package Manager";
	my $app = Qt::Application(\@ARGV);
	$app->setApplicationName($title);
	$app->setQuitOnLastWindowClosed(1);
	my $dialog = MainWindow($title);
	$dialog->showWindow();
	return $app->exec();
}
exit main();
