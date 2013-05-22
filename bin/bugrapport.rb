#! /usr/bin/env ruby

require 'SQLite3'
require 'date'

class BugRapport

    def initialize(db_path)
        @db = SQLite3::Database.new(db_path)
    end

    def generateRapportFor(date)
        sql = "select task, strftime('%s',timeStart), strftime('%s',timeStop) from bugger where DATE(timeStart) = DATE(?) and timeStop is not null"
        @db.execute(sql, date).each do |row|
            seconds = row[2].to_i - row[1].to_i
            minutes = seconds / 60
            hours = minutes / 60
            extra_minutes = minutes - (hours * 60)
            puts format('%02d', hours) + "h:" + format('%02d', extra_minutes) + "m - " + row[0]
        end
    end

    def prettyPrint(date)

    end

end



db_path = ARGV[0]
bugrapport=BugRapport.new(db_path)

if (ARGV.length == 1)
    bugrapport.generateDayRapport(Date.now)
elsif (ARGV.length == 2)
    date = ARGV[1]
    bugrapport.generateRapportFor(date)
end




