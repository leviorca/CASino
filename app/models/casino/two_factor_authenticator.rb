
class CASino::TwoFactorAuthenticator
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: 'casino_two_factor_authenticators'

  field :secret,                                type: String
  field :active,    type: Mongoid::Boolean, default: false

  validates :secret, :active, :user, presence: true

  belongs_to :user, class_name: 'CASino::User', index: true

  scope :active, -> { where(active: true) }

  def self.cleanup
    self.delete_all({created_at: {'$lt' => self.lifetime.ago}, active: false})
  end

  def self.lifetime
    CASino.config.two_factor_authenticator[:lifetime_inactive].seconds
  end

  def expired?
    !self.active? && (Time.now - (self.created_at || Time.now)) > self.class.lifetime
  end
end
