require 'digest/sha1'
require 'dm-validations'
require 'dm-tags'
require 'date'

#DataMapper::Model.raise_on_save_failure = true

class Team
  include DataMapper::Resource

  has n, :users

  property :id,               Serial
  property :name,             String, :key => true, :required => true, :unique => true
  property :description,      Text

  validates_presence_of :name, :description
end

class User
  include DataMapper::Resource

  belongs_to :team

  has n, :items

  property :id,               Serial
  property :login,            String, :key => true, :length => (3..40), :required => true, :unique => true,
    :messages => {
      :presence  => "We need a login name. ",
      :is_unique => "We already have that login. "
    }
  property :hashed_password,  String
  property :email,            String, :required => true, :unique => true,
    :format => :email_address,
    :messages => {
      :presence  => "We need your email address. ",
      :is_unique => "We already have that email. ",
      :format    => "Doesn't look like an email address to me ... "
    }
  property :name,             String
  property :salt,             String
  property :created_at,       DateTime, :default => DateTime.now

  attr_accessor :password

  def password=(pass)
    @password = pass
    self.salt = Helpers::random_string(10) unless self.salt
    self.hashed_password = User.encrypt(@password, self.salt)
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  def self.authenticate(login, pass)
    u = User.first(:login => login)
    return nil if u.nil?
    return u if User.encrypt(pass, u.salt) == u.hashed_password
    nil
  end
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
end

class Comment
  include DataMapper::Resource

  belongs_to :item

  property :id,         Serial
  property :login,      String, :required => true
  property :name,       String, :required => true
  property :email,      String, :required => true
  property :url,        String, :required => true
  property :body,       Text, :required => true
  property :created_at, DateTime, :default => DateTime.now

  validates_presence_of :login, :name, :email, :url, :body
end

DataMapper.finalize
DataMapper.auto_upgrade!
