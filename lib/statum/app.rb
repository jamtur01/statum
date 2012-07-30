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
    #DataMapper::Logger.new(STDOUT, :debug)
    DataMapper.setup(:default, "sqlite3:db/statum.db")

    require 'models'

    before do
      @app_name = "Statum"
    end

    get '/' do
      @u = session[:user]
      @statuses = User.first(:login => session[:user][:login]).items if @u
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

    get '/team/create' do
      authenticated!
      erb :team_create
    end

    post '/team/create' do
      authenticated!
      t = Team.new
      t.name = params[:name]
      t.description = params[:description]
      if t.save
        redirect '/team/create', :success => 'Team created'
      else
        redirect '/team/create', :error => errors(t)
      end
    end

    get '/team/list' do
      authenticated!
      @teams = Team.all
      erb :team_list
    end

    get '/team/delete' do
      authenticated!
      erb :team_delete
    end

    post '/team/delete' do
      authenticated!
      if t = Team.first(:name => params[:name])
        if t.destroy
          redirect '/team/delete', :success => 'Team deleted'
        else
          redirect '/user/delete', :error => errors(t)
        end
      else
        redirect '/team/delete', :error => 'Team does not exist'
      end
    end

    get '/user/create' do
      authenticated!
      @teams = Team.all
      erb :user_create
    end

    post '/user/create' do
      authenticated!
      t = Team.first(:name => params[:team])
      if t.users.create(
        :login    => params[:login],
        :password => params[:password],
        :name     => params[:name],
        :email    => params[:email])
        redirect '/user/create', :success => 'User created'
      else
        redirect '/user/create', :error => errors(t)
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
        s = Item.all(:user_login => params[:login])
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
      u = User.first(:login => session[:user][:login])
      if u.items.create(
        :status  => params[:status])
          redirect '/', :success => 'Status created'
      else
        redirect '/', :error => errors(u)
      end
    end

    get '/status/list' do
      authenticated!
      @statuses = User.first(:login => session[:user][:login]).items
      erb :status_list
    end

    get '/status/team' do
      authenticated!
      @teams = Team.all
      erb :status_team
    end

    post '/status/update' do
      authenticated!
      s = Item.first(:id => params[:id])
      if params[:delete]
        if s.destroy
          redirect '/', :success => 'Item deleted'
        else
          redirect back, :error => errors(s)
        end
      else
        if s.update(:status => params[:status])
          redirect back, :success => 'Item updated'
        else
          redirect back
        end
      end
    end

    get '/status/:id' do |id|
      authenticated!
      if @status = Item.first(:id => id)
        @comments = @status.comments
      else
        redirect '/' unless @status
      end
      erb :status_item
    end

    post '/status/comment' do
      authenticated!
      s = Item.first(:id => params[:id])
      if s.comments.create(
        :login => session[:user][:login],
        :email => session[:user][:email],
        :name  => session[:user][:name],
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
