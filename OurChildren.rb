#
# coryright (c) 2009 Diego Che
#
# For our children

require 'rubygems'
require 'json/pure'

class Child
  
  @@attr = [:name, :gender, :birth_year, :birth_month, :birth_day, :age
      :province, :region, :city, :town, :village, :school, :grade, :class,
      :rest_address, :father, :mother, :other_relatives, :phone
    ];
  
  @@attr.each do |sym|
    attr_accessor sym
  end
  
  def self.parser_for(sym, &proc)
    
  end
  
  def initialize(str)
    
  end
  
  def is_same_child?(c)
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

# parse names.
children = [];
Dir.glob("../student_victims/*.txt") do |f|
  
end

# export. group 500 names into on json file.
0.upto(children.length / 500) do |i|
  max = i * 500 + 499
  json = children[(i * 500) .. (max >= children.length ? children.length - 1 : max)].to_json
  File.open("OurChildren#{i}.json", "w") do |f|
    f.puts json
  end
end