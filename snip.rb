%w(rubygems sinatra active_record uri haml).each  { |lib| require lib}

ActiveRecord::Base.establish_connection(
  YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), 'config', 'database.yml')))
)

configure do
  LOGGER = Logger.new(File.expand_path(File.join(File.dirname(__FILE__), 'log', 'sinatra.log')))
end
 
helpers do
  def logger
    LOGGER
  end
end

class Url < ActiveRecord::Base
  def snipped() self.id.to_s(36) end
end

error ActiveRecord::RecordNotFound do
  haml :index
end

get '/' do haml :index end

get '/list' do 
  @urls = Url.find(:all, :limit => 50, :order => "id desc")
  haml :list
end

get '/api' do
  uri = URI::parse(params[:url])
  raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
  @url = Url.find_or_create_by_original(uri.to_s)
  "http://burgr.nl/#{@url.snipped}"
end

post '/' do
  uri = URI::parse(params[:original])
  raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
  @url = Url.find_or_create_by_original(uri.to_s)
  haml :index
end

get '/:snipped' do 
  @url = Url.find(params[:snipped].to_i(36))
  @url.update_attribute(:counter, @url.counter + 1)
  redirect @url.original
end
