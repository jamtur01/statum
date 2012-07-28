require 'digest/sha1'
require 'dm-validations'
require 'date'

class User
  include DataMapper::Resource

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
  property :salt,             String
  property :created_at,       DateTime, :default => DateTime.now

  attr_accessor :password
  validates_presence_of :password

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

class Status
  include DataMapper::Resource

  property :id, Serial
  property :status, Text, :required => true
  property :created_at, DateTime
  property :updated_on, DateTime
  property :login, String, :required => true

  validates_presence_of :login, :status
end

DataMapper.finalize
DataMapper.auto_upgrade!
