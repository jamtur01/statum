$: << File.dirname(__FILE__)

require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'data_mapper'
require 'json'
require 'yaml'

module Statum
  class Application < Sinatra::Base

    register Sinatra::StaticAssets

    enable :sessions

    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')

    configure :development do
      #load_configuration("config/config.yml", "APP_CONFIG")
    end

    configure :production do
      log = File.new("log/production.log", "a")
      STDOUT.reopen(log)
      STDERR.reopen(log)
      #load_configuration("config/config.yml", "APP_CONFIG")
    end

    enable :logging, :dump_errors, :raise_errors
    DataMapper.setup(:default, "sqlite3:db/statum.db")
    enable :show_exceptions

    require 'models'

    before do
      @app_name = "Statum"
    end

    get '/' do
      @u = session[:user]
      erb :index
    end

    get '/user/login' do
      erb :login
    end

    post '/user/login' do
      if session[:user] = User.authenticate(params["login"], params["password"])
        flash("Login successful")
        redirect '/'
      else
        flash("Login failed - Try again")
        redirect '/user/login'
      end
    end

    get '/user/logout' do
      session[:user] = nil
      flash("Logout successful")
      redirect '/'
    end

    get '/user/create' do
      erb :create
    end

    post '/user/create' do
      u = User.new
      u.login = params["login"]
      u.password = params["password"]
      u.email = params["email"]
      if u.save
        flash("User created")
        redirect '/user/list'
      else
        tmp = []
        u.errors.each do |e|
          tmp << (e.join("<br/>"))
        end
       flash(tmp)
       redirect '/user/create'
      end
    end

    get '/user/list' do
      @u = User.all
      erb :list
    end

    helpers do
      def logged_in?
        return true if session[:user]
        nil
      end

      def link_to(name, location, alternative = false)
        if alternative and alternative[:condition]
          "<a href=#{alternative[:location]}>#{alternative[:name]}</a>"
        else
          "<a href=#{location}>#{name}</a>"
        end
      end

      def random_string(len)
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        str = ""
        1.upto(len) { |i| str << chars[rand(chars.size-1)] }
        return str
      end

      def flash(msg)
        session[:flash] = msg
      end

      def show_flash
        if session[:flash]
          tmp = session[:flash]
          session[:flash] = false
          "<fieldset><legend>Notice</legend><p>#{tmp}</p></fieldset>"
        end
     end
    end

  end
end
