hood-radio
=============

A command line music player in Ruby. 
Creates a shuffled list of hot posts from /r/trap, /r/trapmuzik, and /r/hiphopheads subreddits, 
then downloads and plays the audio tracks one at a time.


Installation:

UBUNTU
------
- Install youtube-dl - Install from directions here: https://github.com/rg3/youtube-dl
- Install mplayer - Built-in for Ubuntu. Other binaries can be had here: http://www.mplayerhq.hu/design7/dload.html
- Install ncurses-dev - 'sudo apt-get install ncurses-dev'

MAC
---
- Install packages via homebrew - 'brew install youtube-dl mplayer ncurses'
- Install necessary gems - 'sudo gem install json curses'
- Clone this repo

Usage:

- Simply run 'ruby hood-radio.rb' in the directory.
