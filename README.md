linkme.sh
=========

Introduction:
-------------

This is a script to simplify deploying git managed config files from their
working directory using symbolic links.

Prereqs:
--------

 * A POSIX shell
 * ~/bin in your path

Deploy:
-------

The deployment assumes you will have ~/bin in your PATH.

Clone repo to your home directory:

    git clone git://github.com/nurfherder/linkme.git ~/code/bin/linkme

Install into ~/bin:

    cd ~/code/bin/linkme
    ./linkme.sh
