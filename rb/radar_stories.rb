require 'rubygems'
require 'typhoeus'
require 'json'
require 'couchrest'
require 'logger'

log = Logger.new('/tmp/radar_stories.log', 'weekly')

COUCHDB = "http://db.andrewnicolaou.co.uk/news"
APPDATA = "/app_data"
RADAR   = "http://radar.journalismlabs.com/radar-0.1/story/json"

# Get last updated timestamp from db
response = Typhoeus::Request.get( COUCHDB + APPDATA )

# If no timestamp in DB then set flag to create one later
if response.code == 404 
  app_data = { "_id" => "app_data", "last_accessed_timestamp" => "" }
else
  app_data = JSON.parse(response.body)
end

log.info "Got last_accessed_timestamp from db: #{app_data['last_accessed_timestamp']}"

# ?since=2010-01-22T16:37:35+0000
last_access_url = "?since=#{app_data['last_accessed_timestamp']}"

response = Typhoeus::Request.get( RADAR + last_access_url )

if response.code != 200
  log.fatal "Response code from radar wasn't 200. Exiting."
  exit
end

# Get radar stories as JSON
json = JSON.parse( response.body )

# Ensure we update the last accessed timestamp
# or create one if necessary
app_data["last_accessed_timestamp"] = json["lastUpdated"]
response = Typhoeus::Request.put( COUCHDB + APPDATA,
                                  :body     => JSON.unparse(app_data),
                                  :headers  => { 
                                    "Content-Type" => 'application/json' 
                                  })
log.info "Update last accessed to #{app_data['last_accessed_timestamp']} (#{response.code})"

@db = CouchRest.database( COUCHDB )

story_ids = json['stories'].collect { |i| i._id }.join(",")

log.info "There are #{json['stories'].length} stories: #{story_ids}"

json["stories"].each_with_index do | story, index |
  print "#{index} "
  story["_id"] = story["id"].to_s
  story.delete("id")
end
puts ""

if json['stories'].length > 0
  # Save to db
  @db.bulk_save( json["stories"] )
  log.info "Saved to db. Relax."
else
  log.info "Nothing to save to db"
end

