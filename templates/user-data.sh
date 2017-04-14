#!/bin/bash
echo "Hello from $(hostname)" > /tmp/index.html
(cd /tmp/; nohup nohup ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => 8888, :DocumentRoot => Dir.pwd).start')&


