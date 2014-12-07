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
