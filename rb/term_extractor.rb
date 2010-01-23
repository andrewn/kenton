require 'rubygems'
require 'typhoeus'
require 'json'
require 'couchrest'
require 'logger'

log = Logger.new('/tmp/term_extractor.log', 'weekly')
log.level = Logger::INFO  # Only log 'info' level and above (ignores debug)

# TODO: 
#  - Log if Yahoo API starts rejecting our requests

COUCHDB       = "http://db.andrewnicolaou.co.uk/news"
NO_TERM_VIEW  = "/_design/news/_view/stories_without_terms"

YAHOO         = "http://search.yahooapis.com/ContentAnalysisService/V1/termExtraction"
APPID         = "hV1USf7V34Gmznx3.HY2FfFxEGltJvGUP3HE6zdo9CE5U3IRXXQAufpp4IQAWm_klcpdwCTN"

@db = CouchRest.database( COUCHDB )

all_docs_without_terms = Typhoeus::Request.get( COUCHDB + NO_TERM_VIEW )

json = JSON.parse( all_docs_without_terms.body )["rows"]

log.info "Fetched #{json.length} stories without terms."

json.each do | row |
  # Get story object from couchdb
  story = JSON.parse( Typhoeus::Request.get(COUCHDB + "/#{row['id']}").body )
  
  if !story['summary'].nil?

    summary = CGI::escape( story['summary'] )
  
    # Get terms from Yahoo!
    yahoo_url = YAHOO + "?appid=#{APPID}&context=#{summary}&output=json"
    yahoo = Typhoeus::Request.get( yahoo_url )
  
    if ( yahoo.code != 200 ) 
      log.fatal "Argh! Brok."
      log.fatal yahoo_url
      exit
    end
  
    terms = JSON.parse( yahoo.body )["ResultSet"]["Result"]
    story["terms"] = terms
    story_json = JSON.unparse( story )
  
    # Put terms in
    response = Typhoeus::Request.put( COUCHDB + "/#{row['id']}",
                                      :body     => story_json,
                                      :headers  => { 
                                        "Content-Type" => 'application/json' 
                                      })
    log.debug "#{row['id']} #{terms} (#{response.code})"
    
  end
end
