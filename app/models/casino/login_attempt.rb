class CASino::LoginAttempt
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::BrowserInfo

  store_in collection: 'casino_login_attempts'

  field :successful,    type: Mongoid::Boolean, default: false
  field :user_ip,       type: String
  field :user_agent,    type: String

  belongs_to :user, class_name: 'CASino::User'

  validates :user, presence: true

end
