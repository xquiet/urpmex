#!/bin/bash
# @copyright 2012 by Matteo Pasotti <matteo.pasotti@gmail.com>

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

pacchetto="yaflight"
LISTASRC=(`urpmq --sourcerpm $pacchetto | sort -u | grep "$pacchetto:" | awk -F':' '{print $2}'`)
lastitemindex=${#LISTASRC[*]}
lastitemindex=$lastitemindex-1
srcpkg=${LISTASRC[$lastitemindex]}
echo "Found $srcpkg"
for url in `urpmq --list-media active --list-url | awk -F' ' '{gsub(/x86_64|i586/,"SRPMS",$NF); gsub(/\/media/,"",$NF); print \$NF}'`;
do
	protocol=`echo $url | awk -F':' '{print $1}'`
	if [[ "$protocol" -eq "http" ]]; then
		#echo "Trying $url/$srcpkg"
		check=`curl -s --head "$url/$srcpkg" | head -n 1 | grep "200 OK" > /dev/null ; echo $?`
		if [[ "${check}" -eq "0" ]]; then
			curl -s $url/$srcpkg -o $srcpkg
			break;
		fi
	#elif [[ "$protocol" -eq "ftp" ]]; then
	#	#echo "Trying $url/$srcpkg"
	#	check=`curl -l $url/$srcpkg`
	#	if [[ "$check" -eq "$srcpkg" ]];then
	#		echo "FTP found"
	#		break;
	#	fi
	fi
done
