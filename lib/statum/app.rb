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
      @statuses = Status.all(:login => session[:user][:login])
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
      erb :user_create
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
      erb :user_list
    end

    get '/user/delete' do
      erb :user_delete
    end

    post '/user/delete' do
      u = User.first(:login => params[:login])
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

    post '/status/create' do
      s = Status.new
      s.status = params["status"]
      s.login = session[:user][:login]
      if s.save
        redirect '/', :success => 'Status created'
      else
        tmp = []
        s.errors.each do |e|
          tmp << e
        end
        redirect '/', :error => tmp
      end
    end

    get '/status/list' do
      @s = Status.all
      erb :status_list
    end

    post '/status/update' do
      s = Status.first(:id => params[:id])
      if params[:delete]
        if s.destroy
          redirect '/', :success => 'Status deleted'
        else
          tmp = []
          s.errors.each do |e|
            tmp << e
          end
          redirect back, :error => tmp
        end
      else
        if s.update(:status => params[:status])
          redirect back, :success => 'Status updated'
        else
          redirect back
        end
      end
    end

    get '/status/:id' do |id|
      @status = Status.first(:id => id)
      @comments = @status.comments
      erb :status_item
    end

    post '/status/comment' do
      s = Status.first(:id => params[:id])
      if s.comments.create(
        :login => session[:user][:login],
        :email => session[:user][:email],
        :url   => "url",
        :body  => params[:body])
          redirect back, :success => 'Comment created'
      else
        tmp = []
        s.errors.each do |e|
          tmp << e
        end
        redirect back, :error => tmp
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
