$: << File.dirname(__FILE__)

require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'data_mapper'
require 'pp'

module Statum
  class Application < Sinatra::Base

    register Sinatra::StaticAssets
    register Sinatra::Flash
    helpers Sinatra::RedirectWithFlash

    enable :sessions

    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')

    configure :development do
      set    :session_secret, "here be dragons"
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
        redirect '/', :success => 'Logged in'
      else
        redirect '/user/login', :error => 'Login failed - try again!'
      end
    end

    get '/user/logout' do
      session[:user] = nil
      redirect '/', :success => 'Logout successful!'
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
        redirect '/user/create', :success => 'User created'
      else
        tmp = []
        u.errors.each do |e|
          tmp << e
        end
        redirect '/user/create', :error => tmp
      end
    end

    get '/user/list' do
      @u = User.all
      erb :list
    end

    get '/user/delete' do
      erb :delete
    end

    post '/user/delete' do
      login = params["login"]
      u = User.first(:login => login)
      if u.destroy
        redirect '/user/delete', :success => 'User deleted'
      else
        tmp = []
        u.errors.each do |e|
          tmp << e
        end
        redirect '/user/delete', :error => tmp
      end
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
    end

  end
end
