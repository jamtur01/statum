require 'spec_helper'

describe Statum::Application do

  describe "GET '/'" do
    it "should return the index page." do
      get '/'
      last_response.should be_ok
    end
  end

  describe "GET '/user/logout'" do
    it "should return the logout page." do
      get '/user/logout'
      last_response.should be_ok
    end
  end

  describe "GET '/team/create'" do
    it "should return the team creation page." do
      get '/team/create'
      last_response.should be_ok
    end
  end

  describe "GET '/team/list'" do
    it "should return the team listing page." do
      get '/team/list'
      last_response.should be_ok
    end
  end

  describe "GET '/team/delete'" do
    it "should return the team deletion page." do
      get '/team/delete'
      last_response.should be_ok
    end
  end

  describe "GET '/user/list'" do
    it "should return the user listing page." do
      get '/user/list'
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
