(function(){
    
    window.kenton = window.kenton || {};
    window.kenton.data = window.kenton.data || {};
    
    kenton.data.Data = function( d ) {
      var dataSource = d; // an array from couchdb
                
      return {
        byHour: function () {
          
          var hours = [];
                        
          dojo.forEach( dataSource, function(item) {
            // Check that key has hour slot
            if ( item.key && item.key[3] ) {
              var hour = item.key[3];
              
              // if first item to be put in hour
              if ( !hours[ hour ] ) { hours[ hour ] = []; }                    
              hours[ hour ].push( item );
              
            }
          });
                        
          return hours;
        }
      }
    }
    
    dojo.require( 'dojo.io.script' );
    kenton.data.StoriesPublished = function () {
      var baseUrl = 'http://db.andrewnicolaou.co.uk/news/_design/news/_view/storie_by_publication_date'; 
      
      /**
        Load feed using storie_published view
      */
      function load( cb, startKey, endKey ) {
        var startKeyString = 'startkey=[' + startKey.join(',') + ']',
            endKeyString   = 'endkey=[' + endKey.join(',')   + ']',
            url = baseUrl + '?' + startKeyString + '&' + endKeyString;
        
        console.log('load', url); //return;
                   
        dojo.io.script.get({
          url: url,
          callbackParamName: 'callback',
          load: function ( data, meta ) {
            console.log( "Loaded", data, meta );
            process( data.rows, cb );
          }
        });
      }
      
      /**
        Put the data into a Data object 
        which makes it easy to slice it 
        by hour etc. etc.
      */
      function process( data, cb ) {
        var d = new kenton.data.Data( data );
        cb( d );
      }
      
      return {
        byDay: function ( callback, year, month, day ) {
          load( callback, [ year, month, day, 0, 0 ], [ year, month, day, 23, 59 ] );
        }
      }
    }();
    
})();