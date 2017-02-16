
class CASino::User
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: 'casino_users'

  field :authenticator,       type: String
  field :username,            type: String
  field :extra_attributes,    type: Hash

  index authenticator: 1
  index username: 1

  validates :authenticator, :username, presence: true

  has_many :ticket_granting_tickets, class_name: 'CASino::TicketGrantingTicket'
  has_many :two_factor_authenticators, class_name: 'CASino::TwoFactorAuthenticator'
  has_many :login_attempts, class_name: 'CASino::LoginAttempt'

  def active_two_factor_authenticator
    self.two_factor_authenticators.where(active: true).first
  end
end
