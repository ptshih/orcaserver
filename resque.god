rails_env   = ENV['RAILS_ENV']  || "production"
rails_root  = ENV['RAILS_ROOT'] || "/home/bitnami/orcapods"
num_workers = rails_env == 'production' ? 3 : 2

num_workers.times do |num|
  God.watch do |w|
    # w.log = rails_root+'/log/god.log'
    w.name     = "resque-#{num}"
    w.group    = 'resque'
    w.interval = 30.seconds
    w.env      = {"QUEUE"=>"*", "RAILS_ENV"=>rails_env}
    w.start    = "/home/bitnami/.rvm/gems/ruby-1.9.2-p180/bin/rake -f #{rails_root}/Rakefile environment resque:work"

    w.uid = 'bitnami'
    w.gid = 'bitnami'

    # retart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 350.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
