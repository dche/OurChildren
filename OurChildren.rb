# -*- coding: UTF-8 -*-
#
# coryright (c) 2009 Diego Che
#
# For our children

require 'yaml'
require 'time'
require 'json/pure'
require 'pp'

def human_check(children, expr, desc)
  # (puts desc; pp children) if expr
end

class Child
  THEDAY = Time.parse("2008-05-12 14:28:00")
  
  @@attr = [:name, :gender, :birth_year, :birth_month, :birth_day, :age,
      :province, :school_city, :homt_city, :town, :school, :grade, :class_, :home_address, 
      :parents_or_relatives, :phone, :file, :lineno
    ]
    
  @@parsers = {}
  
  @@attr.each do |sym|
    attr_accessor sym
  end
  
  def self.add_parser(sym, &proc)
    return unless @@attr.member? sym
    
    @@parsers[sym] ||= [];
    @@parsers[sym] << proc;
  end
  
  def self.parser_for(sym)
    @@parsers[sym]
  end
  
  def self.normalize_school_name(str)
    str
  end
  
  def self.normalize_grade_name(str)
    str
  end
  
  def initialize(line, info = {}, hints = [])
    @@attr.each do |sym|
      parsers = Child.parser_for(sym)
      
      parsers && parsers.each do |p|
        val = p.call(self, line.split(/\s+/), hints)
        break if (val)
      end
      
      self.send((sym.to_s + '=').to_sym, info[sym.to_s]) unless self.send(sym)
    end
  end
  
  def same_child?(c)
    return false unless (c.name == self.name)
    [:age, :gender, :school, :grade, :class, :parents_or_relatives].inject(true) do |b, v|
      break unless b
      if (self.send(v) && c.send(v))
        self.send(v) == c.send(v)
      else
        true
      end
    end
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

# register parsers
Child.add_parser(:name) do |child, parts, hints|
  if (parts[1].length == 1 && parts[0].length == 1)
    name = parts[0 .. 1].join
  elsif (parts[0].length >= 3 && parts[0] =~ /(.*)(男|女)$/)  # potential bug.
    name = $1
    child.gender = ($2 == '男') ? ('male') : ('female')
    human_check(parts.join("\s"), true, "Found a probable typo.")
  else
    human_check(parts[0], parts[0].length > 3, "Found a child's name too long.")
    name = parts[0]
  end
  
  child.name = name.sub(/？|\?/, "\u25a1")
end

Child.add_parser(:gender) do |child, parts, hints|
  parts[1 .. parts.count].each do |str|
    if str =~ /^男$/
      child.gender = "male"
      break
    elsif str =~ /^女$/
      child.gender = "female"
      break
    end
  end
  child.gender
end

Child.add_parser(:age) do |child, parts, hints|
  idx = hints.index("age")
  if (idx  && idx < parts.length)
    parts[((idx - 1 < 0) ? 0 : (idx - 1)) .. ((idx + 1 >= hints.count) ? (idx) : (idx + 1))].each do |str|
      if str =~ /^(([1-2])?[0-9])(岁)?$/
        child.age = $1.to_i
        break;
      end
    end
  end
  child.age
end

Child.add_parser(:birth_year) do |child, parts, hints|
  idx = hints.index("birthday")
  if (idx && idx < parts.length)
    parts.each do |str|
      [/^((19|20)\d{2})年?((\d+)月((\d+)日)?)?$/, 
        /^((19|20)\d{2})(-(\d+)(-(\d+))?)?$/, 
        /^((19|20)\d{2})(\.(\d+)(\.(\d+))?)?$/,
        /^((19|20)\d{2})(\\(\d+)(\\(\d+))?)?$/,
        /^((19|20)\d{2})(\/(\d+)(\/(\d+))?)?$/].each do |re|
        if re.match str
          child.birth_year = $1.to_i
          child.birth_month = $4.to_i if $4
          child.birth_day = $6.to_i if $6
          
          break
        end
      end
      
      if (child.birth_year)
        tstr = [child.birth_year, child.birth_month, child.birth_day].map do |num|
          num.nil? ? "1" : num.to_s
        end.join("-")
        
        age = ((Child::THEDAY - Time.parse(tstr)) / (60 * 60 * 24 * 365)).floor
        human_check(child, child.age && child.age != age, "Age and birthday mismatch.")
        child.age = age
        
        break
      end
    end
  end
  child.birth_year
end

Child.add_parser(:school) do |child, parts, hints|
  idx = hints.index("school")
  if (idx && idx < parts.length)
    parts[((idx - 1 < 0) ? 0 : (idx - 1)) .. ((idx + 1 >= hints.count) ? (idx) : (idx + 1))].each do |str|
      if str =~ /^(.*(中学|小学|幼儿园|职中|一中|学院|学校|北中))(.*)?$/
        if $1
          child.school = Child.normalize_school_name($1)
          p child.school
          if $3
            parsers = Child.parser_for(:grade)
            parsers && parsers.each do |p|
              break if p.call(child, [$3], ["grade"])
            end
          end
          break
        end
      end
    end    
  end
  child.school
end

Child.add_parser(:grade) do |child, parts, hints|
  idx = hints.index("grade")
  if (idx && idx < parts.length)
    parts[((idx - 1 < 0) ? 0 : (idx - 1)) .. ((idx + 1 >= hints.count) ? (idx) : (idx + 1))].each do |str|
      if str =~ /^[\/]?(((初|高)(中)?)?[一二三四五六123456](年级)?)([、，,])?(.*)?$/
        child.grade = Child.normalize_grade_name($1)
        p child.grade
        p $7
      end
    end    
  end
  child.grade  
end

Child.add_parser(:parents_or_relatives) do |child, parts, hints|
  
end

Child.add_parser(:home_address) do |child, parts, hints|
  
end

# Parsing
children = [];
Dir.glob("victims/*.txt") do |fn|   
  File.open(fn) do |file|
    reading_yaml = false
    hints = []
    info = {}
    lineno = 0
    file.read.each_line do |line|
      lineno += 1
      next if line =~ /^\s*$/
      if (line =~ /^---\s*$/)
        reading_yaml = !reading_yaml
        next
      end
      if (line =~ /^name/)
        hints = line.split(/\s+/)
        next
      end
      if reading_yaml
        info.merge! YAML.load(line)
      else
        c = Child.new(line, info, hints)
        c.file = fn; c.lineno = lineno  # For human check.
        
        p line.split(/\s+/)

        remembered = false;
        children.each do |child|
          if (c.same_child?(child))
            child.merge(c)
            remembered = true
            
            human_check(c, remembered, "Found a child in #{fn}:#{lineno} has been remembered in #{child.file}:#{child.lineno}.")
            break
          end
        end
        children << c unless remembered
        human_check(line, c.age.nil?, "Found a line in #{fn}:#{lineno} does not contain age.")
      end
    end
  end
end

schools = []
children.each do |child|
  schools << child.school if child.school && !schools.member?(child.school)
end

pp schools

# export. group 500 names into on json file.
0.upto((children.length - 1) / 300) do |i|
  max = i * 300 + 299
  childs = children[(i * 300) .. (max >= children.length ? children.length - 1 : max)]
  File.open("names/OurChildren#{i}.json", "w") do |f|
    f.puts "(" + {"children" => childs}.to_json + ")"
  end
end