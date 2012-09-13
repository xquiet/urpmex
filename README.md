urpmex
======

*urpmex* is a (small) suite of tools making Mageia system administration a bit more comfortable.

Currently it provides two scripts:

 * repos
 * kir

repos
-----

*repos* allow the sysadmin to enable/disable/refresh all the available medias without
having to recall their entire names.


kir
---

*kir* is a small script that aims to preserve a fixed number of bootable kernels, dropping the old ones. 
It's behaviour (the number of kernel images kept) can be defined by the user.
Consider that if you use _urpme --auto-orphans_ even the kernel previously kept will be deleted keeping only the last one.
