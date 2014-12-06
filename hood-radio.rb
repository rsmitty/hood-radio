require 'open-uri'
require 'json'
require 'io/console'

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
  attr_reader :playlist, :cache_path, :pid_id, :track_index

  def initialize(playlist,cache_path)
    @playlist = playlist
    @cache_path = cache_path
    @track_index = 0
    @pid_id = 0
  end

  def play()
    puts "Found #{@playlist.length()} tracks. Let's jam!"
    @playlist.each do |track|
      @track_index += 1
      clobber_cache()
      
      puts "Grabbing #{track[:url]}..."
      `youtube-dl -x \"#{track[:url]}\" -q -o \"#{@cache_path}/current_track.%(ext)s\"`

      puts "Download complete, now playing track \##{@track_index}: #{track[:title]}"
      puts "Press 'n' for next track\n\n"
      @pid_id = fork {exec "mplayer -really-quiet .cache/current_track.*" }
      listen()
    end
    @track_index = 0
    clobber_cache()
  end

  def listen()
    sys_monitor = System_Monitor.new(@pid_id)
    get_keystrokes(sys_monitor)
  end

  def get_keystrokes(sys_monitor)
    while sys_monitor.mplayer_alive()
      puts "alive"
      system("stty -raw echo")
      str = STDIN.getc
      if str == "n"
        sys_monitor.kill_process()
        return
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
      Process.kill(0, get_child())
      true
    rescue Errno::ESRCH
      false
    ensure
      false
    end
  end

  def kill_process()
    if mplayer_alive()
      Process.kill(1,@child_pid)
    end
  end
end

redditor = Redditor.new(["trapmuzik","hiphopheads","trap"],["soundcloud","youtube"])
redditor.get_urls_from_sub()
juke = Jukebox.new(redditor.urls,".cache")
juke.play()
