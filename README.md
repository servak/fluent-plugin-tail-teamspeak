Teamspeak input plugin for Fluentd
=================

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-tail-teamspeak'

## Configuration

```
<source>
  type tail_teamspeak
  path /teamspeak_path/logs/ts3server.log
  pos_file /tmp/teamspeak.pos
  tag ts3.server.access
</source>
```
