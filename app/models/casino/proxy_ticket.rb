require 'addressable/uri'

class CASino::ProxyTicket
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::Ticket

  store_in collection: 'casino_proxy_tickets'

  field :ticket,          type: String
  field :service,         type: String
  field :consumed,        type: Mongoid::Boolean, default: false

  index ticket: 1

  self.ticket_prefix = 'PT'.freeze

  validates :ticket, :service, :consumed, :proxy_granting_ticket, presence: true
  validates :ticket, uniqueness: true
  belongs_to :proxy_granting_ticket, class_name: 'CASino::ProxyGrantingTicket', index: true, inverse_of: :proxy_tickets
  has_many :proxy_granting_tickets, class_name: 'CASino::ProxyGrantingTicket', as: :granter, dependent: :destroy

  def self.cleanup_unconsumed
    self.destroy_all({created_at: {'$lt' => CASino.config.proxy_ticket[:lifetime_unconsumed].seconds.ago}, consumed: false})
  end

  def self.cleanup_consumed
    self.destroy_all({created_at: {'$lt' => CASino.config.proxy_ticket[:lifetime_consumed].seconds.ago}, consumed: true})
  end

  def expired?
    lifetime = if consumed?
      CASino.config.proxy_ticket[:lifetime_consumed]
    else
      CASino.config.proxy_ticket[:lifetime_unconsumed]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
