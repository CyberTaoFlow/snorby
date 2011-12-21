#!/usr/bin/ruby

require 'rubygems'
require 'datamapper'

PRG_VERSION="1.0"

DataMapper.setup(
  :default,
  {:adapter  => 'mysql',
  :username => 'snorby',
  :password => 'redborder',
  :host     => 'localhost',
  :database => 'snorby'}
)

class Trap
  include DataMapper::Resource
  property :id, Serial
  property :ip, String
  property :port, Integer
  property :protocol, String
  property :hostname, String
  property :community, String
  property :message, String, :length => 512
  property :timestamp, DateTime
end

hostname  = nil
ipaddress = nil
port      = nil
protocol  = nil
msg       = nil


ARGF.each_with_index do |line, idx|
  line.chop!
  if idx==0
    hostname=line
  elsif idx==1
    ipaddress=line
  elsif idx==2
    msg = line
  else
    msg = msg +"; " +line
  end
end

#+-----------+------------------+------+-----+---------+----------------+
#| Field     | Type             | Null | Key | Default | Extra          |
#+-----------+------------------+------+-----+---------+----------------+
#| id        | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
#| ip        | varchar(50)      | YES  |     | NULL    |                |
#| port      | int(11)          | YES  |     | NULL    |                |
#| protocol  | varchar(50)      | YES  |     | NULL    |                |
#| hostname  | varchar(50)      | YES  |     | NULL    |                |
#| community | varchar(50)      | YES  |     | NULL    |                |
#| message   | varchar(512)     | YES  |     | NULL    |                |
#| timestamp | datetime         | YES  |     | NULL    |                |
#+-----------+------------------+------+-----+---------+----------------+

#UDP: [192.168.122.51]:52024->[192.168.122.53] | redBorder | DISMAN-EVENT-MIB::sysUpTimeInstance 0:0:04:30 ... | 2011-10-27 18:12:59

if hostname.length>=47
  hostname = hostname.slice(0,45) + " ..."
end

if msg.length>=508
  msg = msg.slice(0,508) + " ..."
end

r = /([^:]+): \[([^\]]+)\]:([0-9]+)/
m = r.match ipaddress

if !m.nil? && m.length>3
  protocol  = m[1]
  ipaddress = m[2]
  port      = m[3]

  if !hostname.nil? && !ipaddress.nil? && !msg.nil? && !protocol.nil? && !port.nil?
    Trap.create(:ip => ipaddress, :hostname => hostname, :protocol => protocol, :port => port, :community => "redBorder", :message => msg, :timestamp => Time.now)
  else
    system("logger -t traptobbdd \"Trap no valid. It should have more parameters!!\" ")
  end  
else
  system("logger -t traptobbdd \"Trap no valid!!\" ")
end


