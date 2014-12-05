require 'open-uri'
require 'json'
require 'io/console'

def get_urls_from_sub(subreddit)

  json_data = open("http://www.reddit.com/r/#{subreddit}/.json?limit=100")
  parsed = JSON.parse(json_data.read)

  urls = []
  parsed["data"]["children"].each do |child|
    child_url = {:title => child["data"]["title"], :url => child["data"]["url"]}
    if child_url[:url].include? "soundcloud" or child_url[:url].include? "youtube"
      urls << child_url
    end
  end
  return urls
end

def process_alive(pid)
  begin
    Process.kill(0,pid)
    true
  rescue Errno::ESRCH
    false
  end
end

hood_urls = get_urls_from_sub("hiphopheads")
hood_urls << get_urls_from_sub("trap")
hood_urls.shuffle!

hood_urls.each do |url|
  FileUtils.rm Dir[".cache/current_track.*"]
  puts "Going to get #{url[:url]}"
  `youtube-dl -x \"#{url[:url]}\" -q -o \".cache/current_track.%(ext)s\"`

  puts "Playing #{url[:title]}...\n\n\n"
  parent_pid = fork {`mplayer -quiet .cache/current_track.*`}
  child_pid = `pgrep -P #{parent_pid}`.to_i
  while process_alive(child_pid)
  end
end
