module Fluent

  class TeamspeakTailInput < TailInput
    Plugin.register_input('tail_teamspeak', self)

    def initialize
      super

      @parser = nil
    end

    def configure_parser(conf)
      @parser = TeamspeakParser.new
      @parser.configure(conf)
    end
  end

  class TeamspeakParser
    include Configurable

    def parse(line)
      logs = line.split("|")
      time = logs[0]
      data = logs[4].strip

      response =
        case data
        when /^client connected/
          /^client connected '(?<user>[^']*)'\(id:(?<id>\d*)\) from (?<ip>[^:]*)/ =~ data
          {
            :action => "connected",
            :user => convert_utf8(user),
            :id => id.to_i,
            :ip => ip,
            :type => "client",
            :msg => nil,
          }
        when /^client disconnected/
          /^client disconnected '(?<user>[^']*)'\(id:(?<id>\d*)\) reason 'reasonmsg=(?<reason>[^']*)'/ =~ data
          {
            :action => "disconnected",
            :user => convert_utf8(user),
            :id => id.to_i,
            :ip => nil,
            :type => "client",
            :msg => reason,
          }
        when /^query client/
          /^query client (?<action>[^ ]*) '(?<user>[^ ]*) from (?<ip>[^:]*).*'\(id:(?<id>\d*)\)( reason 'reasonmsg=(?<reason>[^']*))?/ =~ data
          {
            :action => action,
            :user => convert_utf8(user),
            :id => id.to_i,
            :ip => ip,
            :type => "query_client",
            :msg => reason,
          }
        when /^file/
          /^file (?<action>[^ ]*) from [^,]*, '(?<msg>[^']*)'( by client '(?<user>[^']*)'\(id:(?<id>\d*)\))?/ =~ data
          {
            :action => action,
            :user => convert_utf8(user),
            :id => id.to_i,
            :ip => ip,
            :type => "file",
            :msg => convert_utf8(msg),
          }
        else
          {}
        end

      [convert_time(time), response]
    end

    private

    def convert_time(time)
      /(?<year>\d{4})-(?<month>\d{2})-(?<day>\w{2}) (?<hour>\w{2}):(?<minute>\w{2}):(?<sec>\w{2}).+$/ =~ time
      Time.gm(year, month, day, hour, minute, sec).to_i
    end

    def convert_utf8(str)
      str.gsub(/&#(\w+);/) {$1.to_i.chr("utf-8")}
    end

  end

end
