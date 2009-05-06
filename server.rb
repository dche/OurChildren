#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'webrick'

s = WEBrick::HTTPServer.new(:Port => 2008, :DocumentRoot => Dir.pwd)

trap('INT') {s.shutdown}
s.start