# -*- coding: UTF-8 -*-
#
# coryright (c) 2009 Diego Che
#
# For our children

require 'time'
require 'json/pure'
require 'pp'
require 'digest/sha1'

class Child
  THEDAY = Time.parse("2008-05-12 14:28:00")
  
  @@attr = [:name, :gender, :birth_year, :birth_month, :birth_day, :age,
      :province, :school_city, :home_city, :home_town, :school, :grade, :home_address, 
      :father, :mother, :relatives, :phone, :lineno
    ]
    
  @@attr.each do |sym|
    attr_accessor sym
  end
  
  def initialize(line)
    info = line.split(',')
    info.each_with_index do |val, index|
      v = val.strip
      next if v.empty?
      
      case index
      when 0
        # name
        self.name = v.gsub(/？|\?/, "\u25a1")
      when 1
        # gender
        if (v =~ /^男/)
          self.gender = "male"
        elsif (v =~ /^女/)
          self.gender = "female"
        else
          puts "Found a wrong typed gender info: [#{v}]"
        end
      when 2
        # birthday
        case v
        when /^(Aug|Sep)-(9[13])$/i # Aug-93. Only 2 children's info use this format.
          self.birth_year = 1900 + $2.to_i
          self.birth_month = ($2 == 'Aug') ? 8 : 9
        when /(((19(8|9))|200)[0-9])([\.-]([01]?[0-9])([\.-]([0-3]?[0-9]))?)?/ # 1992-6-18 or 1992.6.18
          self.birth_year = $1.to_i
          self.birth_month = $6.to_i if $6.to_i > 0
          self.birth_day = $8.to_i if $6 && $8.to_i > 0
        when /^([01]?[0-9])\/([0-3]?[0-9])\/([890][0-9])$/ # 18-6-92
          self.birth_year = ($3.to_i < 10) ? (2000 + $3.to_i) : (1900 + $3.to_i)
          self.birth_month = $1.to_i
          self.birth_day = $2.to_i
        else
          puts "Found a date string not matched by any pattern: [#{v}]"
        end
        
        if (self.birth_year)
          tstr = [self.birth_year, self.birth_month, self.birth_day].map do |num|
            num.nil? ? "1" : num.to_s
          end.join("-")
          
          begin
            age = ((Child::THEDAY - Time.parse(tstr)) / (60 * 60 * 24 * 365)).floor
            puts "#{tstr} => #{age}"
            self.age = age
          rescue ArgumentError
            puts "Wrong birthday: [#{v}]"
          end
        end
      when 3
        if v =~ /^(([1-2])?[0-9])(岁)?$/
          self.age = $1.to_i
        end unless self.age
      when 4
        # school
        self.school = v
      when 5
        # grade
        self.grade = v
      when 7
        # school_city
        self.school_city = v
      when 11
        # parent1
      when 14
        # home_address
        self.home_address = v
        puts "home_address: #{v}"
      when 15
        # parent2
      end
    end
  end
  
  def same_child?(c)
    return false unless (c.name == self.name)
    [:age, :gender, :school, :grade].inject(true) do |b, v|
      break unless b
      if (self.send(v) && c.send(v))
        self.send(v) == c.send(v)
      else
        true
      end
    end
  end
  
  def key
    Digest::SHA1.hexdigest(self.name + (self.gender || "") + (self.school || "") + (self.grade || ""))
  end
  
  def merge(c)
    return unless same_child?(c)
    
  end
   
  def to_json(*a)
    h = {}
    @@attr.each do |sym|
      h[sym] = self.send(sym) if self.send(sym)
    end
    h.to_json(*a)
  end
end

# Parsing
allchildren = {};
lineno = 0;
File.open("children/names.csv") do |file|
  file.read.each_line do |line|
    lineno += 1
    next if line =~ /^\s*$/
    c = Child.new(line)
    c.lineno = lineno  # For human check.

    key = c.key
    if (allchildren.has_key? key)
      puts "Found children with same name [#{c.name}] in line #{allchildren[key].lineno} and #{lineno}."
      pp c
      pp allchildren[key]
    else
      allchildren[key] = c
    end
  end
end

# export. group 300 names into one json file.
children = allchildren.values
0.upto((children.length - 1) / 300) do |i|
  max = i * 300 + 299
  childs = children[(i * 300) .. (max >= children.length ? children.length - 1 : max)]
  File.open("names/OurChildren#{i}.json", "w") do |f|
    f.puts "(" + {"children" => childs}.to_json + ")"
  end
end