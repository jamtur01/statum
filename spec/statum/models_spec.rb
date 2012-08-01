require File.dirname(__FILE__) + '/../spec_helper'
require 'statum/models'

describe Team do
  it { should have_property :id   }
  it { should have_property :name   }
  it { should have_property :description   }
end

describe User do
  it { should have_property :id   }
  it { should have_property :user   }
  it { should have_property :name   }
end

describe Item do
  it { should have_property :id   }
  it { should have_property :status   }
  it { should have_property :created_at   }
  it { should have_property :updated_on   }
end

describe Comment do
  it { should have_property :id   }
  it { should have_property :body   }
  it { should have_property :email   }
  it { should have_property :name   }
  it { should have_property :login   }
end
