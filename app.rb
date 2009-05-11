
require 'sinatra'

set :public, File.dirname(__FILE__)

get "/" do
  redirect "/index.html"
end
