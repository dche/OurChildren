# -*- coding: UTF-8 -*-

require 'hpricot'

data = File.open(ARGV[0]) do 
  |f| Hpricot.XML(f) 
end

res = []

(data/"Document/Folder/Placemark").each do |elm|
  town = {}
  town["name"] = "#{(elm/"name").text} "  # add a tail space to force to_yaml escape utf-8 string.
  town["city"] = ""
  town["region"] = ""
  town["type"] = "town"
  town["latitude"] = (elm/"LookAt/Latitude").text.to_f
  town["longitude"] = (elm/"LookAt/Longitude").text.to_f
  res.push town
end

File.open("geoData.yml", "w") do |f|
  yaml = res.to_yaml
  
  utf8 = ""
  conv_states = [:z, :e, :x, :f]
  cs = :z
  byte = ""
  yaml.each_byte do |c|
    case cs
    when :z
      if c != ?\\
        utf8 << c; next
      end
      cs = :e
    when :e
      if c != ?x
        cs = :z; next
      end
      cs = :x
    when :x
      byte << c
      cs = :f
    when :f
      byte << c
      utf8 << byte.to_i(16)
      cs = :z
      byte = ""
    end
  end
  
  f.puts utf8
end
