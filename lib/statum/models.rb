require 'date'
require 'send_status_email'
require 'send_comment_email'
require 'dm-tags'

DataMapper::Model.raise_on_save_failure = true

class Team
  include DataMapper::Resource

  property :id,               Serial
  property :name,             String
  property :description,      Text

end

class User
  include DataMapper::Resource

  has n, :items

  property :id,               Serial
  property :user,             String, :key => true, :unique => true
  property :name,             String
end

class Item
  include DataMapper::Resource

  belongs_to :user

  has n, :comments, :constraint => :destroy

  has_tags

  property :id, Serial
  property :status, Text
  property :created_at, DateTime, :default => DateTime.now
  property :updated_on, DateTime

  validates_presence_of :status

  before :save, :count
  after :save do |item|
    if @saved == 0
      @saved = 1
      Statum::SendStatusEmail.new(item)
    end
  end

  def count
    if !self.saved?
     @saved = 0
    end
  end

end

class Comment
  include DataMapper::Resource

  belongs_to :item

  property :id,         Serial
  property :login,      String, :required => true
  property :name,       String, :required => true
  property :email,      String, :required => true
  property :body,       Text, :required => true
  property :created_at, DateTime, :default => DateTime.now

  before :create, :count
  after :create do |comment|
    pp comment
    if @saved == 0
      @saved = 1
      Statum::SendCommentEmail.new(comment)
    end
  end

  def count
    if !self.saved?
     @saved = 0
    end
  end

  validates_presence_of :login, :name, :email, :body
end

DataMapper.finalize
DataMapper.auto_upgrade!
