#! /usr/bin/env ruby

require 'SQLite3'
require 'date'
require 'terminal-notifier'

class Bugger

    def initialize(db_path, cocoa)
        @db_path = db_path
        @db = SQLite3::Database.new(db_path)
        @cocoa = cocoa
    end

    def get_last_task()
        sql="select id from bugger where timestop is null"
        @db.execute(sql)[0][0]
    end

    def get_task_name(id)
        sql="select task from bugger where id = ?"
        @db.execute(sql, id)[0][0]
    end

    def time_spent_by(id)
        sql="select strftime('%s',timeStart), strftime('%s','now') from bugger where id=?"
        row = @db.execute(sql, id)[0]
        timestart = row[0].to_i
        now = row[1].to_i        
        seconds = now - timestart
        minutes = seconds / 60
        hours = minutes / 60
        extra_minutes = minutes - (hours * 60)        
        format('%02d', hours) + "h:" + format('%02d', extra_minutes) + "m"
    end


    def notify()
        #TODO use idle_time=$(($(ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/!{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q') / 1000000000))
        task_id = get_last_task
        title = "Time spent on task: " + time_spent_by(task_id)
        message = get_task_name(task_id)
        execute = File.dirname(__FILE__) + "/../bugadm prompt"
        puts execute
        TerminalNotifier.notify(message, :title => title, :execute => execute)
    end

    def end_current(id)
        sql = "update bugger set timeStop = DATETIME('now') where id=?"
        @db.execute(sql, id)
    end

    def register_new_task(task)
        sql = "insert into bugger values(null, ?, DATETIME('now'), null)"
        @db.execute(sql, task)
    end

    def prompt()
        task_id = get_last_task
        time_spent = time_spent_by(task_id)
        task_name = get_task_name(task_id)
        new_task = %x(#{@cocoa} standard-inputbox --title "Bugger - What are you working on?" --text "#{task_name}" --float --no-newline --no-cancel --informative-text "Time spent on current task: #{time_spent}" | tail -n 1 )
        if (task_name != new_task)
            #TODO check for null
            end_current(task_id)
            register_new_task(new_task)
        end
    end

end

if (ARGV.length < 2)
    puts "usage huteohuna"
    exit 
end

db_path = ARGV[0]
cocoa = ARGV[1]
bugger = Bugger.new(db_path, cocoa)

if (ARGV.length == 2)
    bugger.notify
elsif (ARGV.length == 3)
    bugger.prompt
end