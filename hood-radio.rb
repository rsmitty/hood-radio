require 'open-uri'
require 'json'
require 'curses'

class Redditor
  attr_reader :subreddits, :urls, :audio_sources

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

class Jukebox
  attr_reader :playlist, :cache_path, :pid_id, :track_index, :terminal

  def initialize(playlist,cache_path)
    @playlist = playlist
    @cache_path = cache_path
    @track_index = 0
    @pid_id = 0
    @terminal = Terminal_Controller.new()
  end

  def play()
    terminal.write("Found #{@playlist.length()} tracks. Let's jam!")
    @playlist.each do |track|
      @track_index += 1
      clobber_cache()
      
      terminal.write("Grabbing #{track[:url]}...")
      `youtube-dl -x \"#{track[:url]}\" -q -o \"#{@cache_path}/current_track.%(ext)s\"`

      terminal.write("Download complete, now playing track \##{@track_index}: #{track[:title]}")
      terminal.write("Press 'n' for next track, CTRL+C to exit.")
      terminal.write("\n")
      unless File.exist?("#{@cache_path}/current_track.*")
        @pid_id = fork { exec "mplayer -really-quiet .cache/current_track.*"}
        listen()
      end
    end
    @track_index = 0
    clobber_cache()
  end

  def listen()
    sys_monitor = System_Monitor.new(@pid_id)
    while sys_monitor.mplayer_alive()
       input = terminal.handle_key()

       #Catch next track key
       if input == "n"
         sys_monitor.kill_process()
         break
       end
       #Catch a CTRL+C
       if input == 3
         sys_monitor.kill_process()
         exit
       end

    end
  end

  def clobber_cache()
    FileUtils.rm Dir["#{@cache_path}/current_track.*"]
  end
end

class System_Monitor
  attr_reader :pid_id, :child_pid

  def initialize(pid_id)
    @pid_id = pid_id
    @child_pid = 0
  end

  def get_child()
    @child_pid = `pgrep -P #{@pid_id}`.to_i
  end

  def mplayer_alive()
    begin
      if Process.kill(0, @pid_id) or Process.kill(0, @child_pid)
        return true
      end
        return false
    rescue Errno::ESRCH
      false
    end
  end

  def kill_process()
      get_child()
      Process.kill(1,@child_pid)
  end
end

class Terminal_Controller
  attr_reader :index, :main_window

  def initialize()
    @index = 0
    Curses.noecho
    Curses.raw
    Curses.nonl
    Curses.stdscr.nodelay = 1
    Curses.init_screen
    @main_window = Curses::Window.new(0,0,0,0)
  end

  def write(in_string)
    @main_window.setpos(@index, 0)
    @main_window.addstr(in_string)
    @main_window.refresh
    @index += 1
  end

  def handle_key()
    return main_window.getch
  end
end

redditor = Redditor.new(["trapmuzik","hiphopheads","trap"],["soundcloud","youtube"])
redditor.get_urls_from_sub()
juke = Jukebox.new(redditor.urls,".cache")
juke.play()
