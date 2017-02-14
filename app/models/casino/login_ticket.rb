class CASino::LoginTicket
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::Ticket
  include CASino::ModelConcern::ConsumableTicket

  store_in collection: 'casino_login_tickets'

  field :ticket,   type: String

  index ticket: 1

  self.ticket_prefix = 'LT'.freeze

  validates :ticket, presence: true

  def self.cleanup
    delete_all(created_at: {'$lt' => CASino.config.login_ticket[:lifetime].seconds.ago})
  end

  def expired?
    (Time.now - (self.created_at || Time.now)) > CASino.config.login_ticket[:lifetime].seconds
  end
end
