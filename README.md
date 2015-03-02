textmining
==========

E-Portfolio-Plattform "Grundlagen des Textmining für Kultur- und SozialwissenschafterInnen"

Ziel des Projektes ist, ein Konzept für ein E-Learning-Modul zu entwickeln,
das Studierende geistes-, sozial- und geschichtswissenschaftlicher Fächer in
Analysemethoden der Digital Humanities einführt.

package CPAN module
===================

    $ ./script/textmining generate makefile
    $ perl Makefile.PL
    $ make test
    $ make manifest
    $ make dist

requirements
============

applications
------------

* git (optional)

libraries
---------

###  development version

* libgdbm
* libxslt1
* libxml2

perl modules
------------

* Data::Printer
* Exporter
* File::Basename
* File::Copy::Recursive
* File::Glob
* File::Path
* File::Spec::Functions
* Mojolicious
* Storable
* Text::NSP
* XML::LibXML
* XML::LibXSLT

    $ cpan \`cat requirements.txt\`

run application
===============

    $ hypnotoad script/textmining
    Server available at http://127.0.0.1:8080.

configuration
-------------

    # textmining.conf
    {
      hypnotoad => {
        listen  => ['https://*:443?cert=/etc/server.crt&key=/etc/server.key'],
        workers => 10
      }
    };

develop application
===================

    $ morbo script/textmining
    Server available at http://127.0.0.1:3000.

more information
================

    http:/mojolico.us/perldoc/Mojolicious/Guides/Cookbook#Built-in-web-server
