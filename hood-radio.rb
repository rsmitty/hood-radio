require 'open-uri'
require 'json'
require 'curses'

##Retrieves and parses JSON from subreddits.
##Adds relevant results to an array of hashes like urls=[{title,url}...]
class Redditor
  attr_reader :urls

  def initialize(subreddits,audio_sources)
    @subreddits = subreddits
    @urls = []
    @audio_sources = audio_sources    
  end

  def get_urls_from_sub() 
    @subreddits.each do |subreddit|
      json_data = open("http://www.reddit.com/r/#{subreddit}/.json?limit=100")
      parsed = JSON.parse(json_data.read)
      parsed["data"]["children"].each do |child|
        child_url = {:title => child["data"]["title"], :url => child["data"]["url"]}
        @audio_sources.any? do |audio_source| 
          if child_url[:url].include? audio_source
            @urls << child_url
          end
        end
      end
    end
    prepare_playlist()
  end

  def prepare_playlist()
    @urls.uniq!
    @urls.shuffle!
  end
end

##Acts as player for urls. Downloads audio files from corresponding videos
##...and once downloaded, passes control to mplayer to play it.
##Also handles next track and application closing functionality.
class Jukebox

  def initialize(playlist,cache_path)
    @playlist = playlist
    @cache_path = cache_path
    @track_index = 0
    @pid_id = 0
    @terminal = Terminal_Controller.new()
  end

  def play()
    @terminal.write("Found #{@playlist.length()} tracks. Let's jam!")
    @playlist.each do |track|
      @track_index += 1
      clobber_cache()
      
      @terminal.write("Grabbing #{track[:url]}...")
      `youtube-dl -x \"#{track[:url]}\" -q -o \"#{@cache_path}/current_track.%(ext)s\"`

      @terminal.write("Download complete, now playing track \##{@track_index}: #{track[:title]}")
      @terminal.write("Press 'n' for next track, CTRL+C to exit.")
      @terminal.write("\n")
      unless File.exist?("#{@cache_path}/current_track.*")
        listen()
      end
    end
    @track_index = 0
    clobber_cache()
  end

  def listen()
    mplayer = Mplayer.new(@cache_path)

    while mplayer.alive() do
       input = @terminal.handle_key()
       #Catch next track key
       if input == "n"
         mplayer.die()
         clobber_cache()
       end
       #Catch a CTRL+C
       if input == 3
         mplayer.die()
         clobber_cache()
         exit
       end
    end
  end

  #Destroy cached files we made
  def clobber_cache()
    FileUtils.rm Dir["#{@cache_path}/current_track.*"]
  end
end

##Actually launches mplayer and return info about whether its process still exists
class Mplayer

  def initialize(cache_path)
    @cache_path = cache_path
    @pid = Process.spawn("mplayer -really-quiet #{@cache_path}/current_track.*")
    @child_pid = `pgrep -P #{@pid}`.to_i
  end

  def alive()
    begin
      if Process.waitpid(@pid, Process::WNOHANG) == nil
        return true
      end
        return false
    rescue Errno::ECHILD
      return false
    end
  end

  def die()
    Process.kill(1,@child_pid.to_i)
    Process.kill(1,@pid.to_i)
  end
end

##Handles curses options and functionality for writing to screen
class Terminal_Controller

  def initialize()
    @index = 0
    Curses.noecho
    Curses.raw
    Curses.nonl
    Curses.init_screen
    @main_window = Curses::Window.new(0,0,0,0)
    @main_window.timeout = 0
  end

  def write(in_string)
    @main_window.setpos(@index, 0)
    @main_window.addstr(in_string)
    @main_window.refresh
    @index += 1
  end

  def handle_key()
    return @main_window.getch
  end
end

##Create a new redditor and retrieve results from hood subreddits.
redditor = Redditor.new(["trapmuzik","hiphopheads","trap"],["soundcloud","youtube"])
redditor.get_urls_from_sub()
##Play results
juke = Jukebox.new(redditor.urls,".cache")
juke.play()
