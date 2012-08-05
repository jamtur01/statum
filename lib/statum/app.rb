$: << File.dirname(__FILE__)

require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/static_assets'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'data_mapper'
require 'json'
require 'pp'

def load_configuration(file, name)
  if !File.exist?(file)
    puts "There's no configuration file at #{file}!"
    exit!
  end
  json = File.read(file)
  Statum.const_set(name, JSON.parse(json))
end

module Statum
  class Application < Sinatra::Base

    register Sinatra::StaticAssets
    register Sinatra::Flash
    helpers Sinatra::RedirectWithFlash

    enable :sessions

    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')

    load_configuration("config/config.json", "CONFIG")

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
      @user = session[:user]
      @statuses = User.first(:login => session[:user][:login]).items if @user
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
      team = Team.new
      team.name = params[:name]
      team.description = params[:description]
      if team.save
        redirect '/team/create', :success => 'Team created'
      else
        redirect '/team/create', :error => errors(team)
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
      if team = Team.first(:name => params[:name])
        if team.destroy
          redirect '/team/delete', :success => 'Team deleted'
        else
          redirect '/user/delete', :error => errors(team)
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
      team = Team.first(:name => params[:team])
      if team.users.create(
        :login    => params[:login],
        :password => params[:password],
        :name     => params[:name],
        :email    => params[:email])
        redirect '/user/create', :success => 'User created'
      else
        redirect '/user/create', :error => errors(team)
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
      if user = User.first(:login => params[:login])
        items = Item.all(:user_login => params[:login])
        if items.destroy
        else
          redirect '/user/delete', :error => errors(items)
        end
        if user.destroy
          session[:user] = nil
          redirect '/user/delete', :success => 'User and statuses deleted'
        else
          redirect '/user/delete', :error => errors(user)
        end
      else
        redirect '/user/delete', :error => 'User does not exist'
      end
    end

    post '/status/create' do
      authenticated!
      user = User.first(:login => session[:user][:login])
      item = user.items.new(:status => params[:status]).tag_list = params[:tags]
      if user.save
        redirect '/', :success => 'Status created'
      else
        redirect '/', :error => errors(user)
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
      item = Item.first(:id => params[:id])
      if params[:delete]
        if item.destroy
          redirect '/', :success => 'Item deleted'
        else
          redirect back, :error => errors(item)
        end
      else
        if item.update(:status => params[:status])
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
        pp @comments
      else
        redirect '/' unless @status
      end
      erb :status_item
    end

    post '/status/comment' do
      authenticated!
      item = Item.first(:id => params[:id])
      if item.comments.create(
        :login => session[:user][:login],
        :email => session[:user][:email],
        :name  => session[:user][:name],
        :body  => params[:body])
          redirect back, :success => 'Comment created'
      else
        redirect back, :error => errors(item)
      end
    end

    get '/status/tag/:name' do |name|
      authenticated!
      @tag = Tag.first(:name => name)
      @statuses =  Item.all('taggings.tag_id' => @tag.id)
      erb :status_tags
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
