# Monitor couchdb
# From: http://japhr.blogspot.com/2009/08/oh-god-book-ii.html
#
God.watch do |w|
  w.name = "couchdb"
  w.interval = 30.seconds # default
  w.start   = "/usr/local/etc/init.d/couchdb start"
  w.stop    = "/usr/local/etc/init.d/couchdb stop"
  w.restart = "/usr/local/etc/init.d/couchdb restart"
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.pid_file = '/usr/local/var/run/couchdb/couchdb.pid'

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
      #c.notify = 'chris'
    end
  end
      
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 30.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
      #c.notify = 'chris'
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
      #c.notify = 'chris'
    end
  end

  w.lifecycle do |on| 
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      #c.notify = 'chris'
    end
  end
  
end