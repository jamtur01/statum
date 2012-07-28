require 'spec_helper'

describe Statum::Application do

  describe "GET '/'" do
    it "should return the index page." do
      get '/'
      last_response.should be_ok
    end
  end

  describe "GET '/user/login'" do
    it "should return the login page." do
      get '/user/login'
      last_response.should be_ok
    end
  end

  describe "GET '/user/logout'" do
    it "should return the logout page." do
      get '/user/logout'
      last_response.should be_ok
    end
  end

  describe "GET '/user/create'" do
    it "should return the user creation page." do
      get '/user/create'
      last_response.should be_ok
    end
  end

  describe "GET '/user/list'" do
    it "should return the user listing page." do
      get '/user/list'
      last_response.should be_ok
    end
  end

  describe "GET '/user/delete'" do
    it "should return the user deletion page." do
      get '/user/delete'
      last_response.should be_ok
    end
  end

  describe "GET '/status/list'" do
    it "should return the status listing page." do
      get '/status/list'
      last_response.should be_ok
    end
  end
end
