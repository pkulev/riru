# riru
Unofficial gentoo overlay

# Installation
Add to `/etc/portage/repos.conf/layman.conf` something like this:
```console
[riru]
priority = 50
location = /var/lib/layman/riru
layman-type = git
sync-type = laymansync
sync-uri = git://github.com/pankshok/riru.git
auto-sync = Yes
```

Then sync repos:
```console
# layman -S
```
