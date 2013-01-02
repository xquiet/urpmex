urpmex
======

*urpmex* is a (small) suite of tools making Mageia system administration a bit more comfortable,
especially when no graphical environment are available (i.e. remote terminals and so on).

Currently it provides three scripts:

 * repos
 * cuterepos
 * kir
 * urpm-downloader

repos
-----

*repos* allows the sysadmin to enable/disable/refresh all the available medias without
having to recall their entire names.

cuterepos
---------

*cuterepos* does the same job of repos but it provides an easiest user interface (thanks to ncurses)

kir
---

*kir* is a small script that aims to preserve a fixed number of bootable kernels, dropping the old ones. 
Its behaviour (the number of kernel images kept) can be defined by the user.
Consider that if you use _urpme --auto-orphans_ even the kernel previously kept will be deleted keeping the last one only.

urpm-downloader
---------------

*urpm-downloader* was inspired by yum-downloader. It can download both source and binary rpms from the repositories.
Currently it works only with _HTTP_ repositories, ftp and rsync support are in progress.
It's still a prototype so it may suffer of ugly bugs.

copyrights
----------

(C) 2012-2013 by Matteo Pasotti <matteo@mageia.it>
