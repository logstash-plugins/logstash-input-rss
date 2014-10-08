logstash-pluginbase
===================

A base repo to make logstash plugins.

Create
======

Depending on what you're trying to build, place your ruby files in one of the lib/logstash/ directories.
Don't forget to remove the others. 


Gem Dependencies
================

To add a Ruby Gem dependancy, modify the logstash-contrib.gemspec file and add something like the following before the end tag:

gem.add_runtime_dependency "net-http-persistent"

Java Dependencies
=================

Work in Progress

Build
=====

Run 'make tarball' to build the project. A tarball will end up in ./build. Extract the file over top of your logstash directory. 
(Hint: or, just copy the ./lib and ./vendor directories to your logstash folder)

Spec Files
==========

If you choose to include some tests, you can create the spec files in the spec directory. I suggest you look at the current logstash/logstash-contrib projects for details.


Todo
====

You'll notice that the bundler will want to be included. :(
