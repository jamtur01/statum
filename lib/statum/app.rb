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
    end

    configure :production do
      log = File.new("log/production.log", "a")
      STDOUT.reopen(log)
      STDERR.reopen(log)
    end

    enable :logging, :dump_errors, :raise_errors, :show_exceptions
    DataMapper.setup(:default, "sqlite3:db/statum.db")

    require 'models'

    before do
      @app_name = "Statum"
    end

    get '/' do
      @u = session[:user]
      @statuses = Status.all(:login => session[:user][:login]) if @u
      erb :index
    end

    get '/user/login' do
      erb :login
    end

    post '/user/login' do
      if session[:user] = User.authenticate(params[:login], params[:password])
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
      authenticated!
      erb :user_create
    end

    post '/user/create' do
      authenticated!
      u = User.new
      u.login = params[:login]
      u.password = params[:password]
      u.name = params[:name]
      u.email = params[:email]
      if u.save
        redirect '/user/create', :success => 'User created'
      else
        redirect '/user/create', :error => errors(u)
      end
    end

    get '/user/list' do
      authenticated!
      @users = User.all
      erb :user_list
    end

    get '/user/delete' do
      authenticated!
      erb :user_delete
    end

    post '/user/delete' do
      authenticated!
      if u = User.first(:login => params[:login])
        s = Status.all(:login => params[:login])
        if s.destroy
        else
          redirect '/user/delete', :error => errors(s)
        end
        if u.destroy
          session[:user] = nil
          redirect '/user/delete', :success => 'User and statuses deleted'
        else
          redirect '/user/delete', :error => errors(u)
        end
      else
        redirect '/user/delete', :error => 'User does not exist'
      end
    end

    post '/status/create' do
      authenticated!
      s = Status.new
      s.status = params[:status]
      s.login = session[:user][:login]
      if s.save
        redirect '/', :success => 'Status created'
      else
        redirect '/', :error => errors(s)
      end
    end

    get '/status/list' do
      authenticated!
      @s = Status.all
      erb :status_list
    end

    post '/status/update' do
      authenticated!
      s = Status.first(:id => params[:id])
      if params[:delete]
        if s.destroy
          redirect '/', :success => 'Status deleted'
        else
          redirect back, :error => errors(s)
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
      authenticated!
      if @status = Status.first(:id => id)
        @comments = @status.comments
      else
        redirect '/' unless @status
      end
      erb :status_item
    end

    post '/status/comment' do
      authenicated!
      s = Status.first(:id => params[:id])
      if s.comments.create(
        :login => session[:user][:login],
        :email => session[:user][:email],
        :url   => "url",
        :body  => params[:body])
          redirect back, :success => 'Comment created'
      else
        redirect back, :error => errors(s)
      end
    end

    helpers do
      def errors(obj)
        tmp = []
        obj.errors.each do |e|
          tmp << e
        end
        tmp
      end

      def logged_in?
        return true if session[:user]
        nil
      end

      def authenticated!
        unless session[:user]
          redirect '/', :error => 'Unauthorised without login.'
        end
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
