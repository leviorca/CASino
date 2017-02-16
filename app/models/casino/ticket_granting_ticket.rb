require 'user_agent'

class CASino::TicketGrantingTicket
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::Ticket
  include CASino::ModelConcern::BrowserInfo

  store_in collection: 'casino_ticket_granting_tickets'

  field :ticket,                                type: String
  field :user_agent,                            type: String
  field :awaiting_two_factor_authentication,    type: Mongoid::Boolean, default: false
  field :long_term,                             type: Mongoid::Boolean, default: false
  field :user_ip,                               type: String

  index ticket: 1

  self.ticket_prefix = 'TGC'.freeze

  validates :ticket, :awaiting_two_factor_authentication, :long_term, :user, presence: true

  belongs_to :user, class_name: 'CASino::User'
  has_many :service_tickets, class_name: 'CASino::ServiceTicket', dependent: :destroy

  scope :active, -> { where(awaiting_two_factor_authentication: false).order_by(updated_at: :desc) }

  def self.cleanup(user = nil)
    if user.nil?
      base = self
    else
      base = user.ticket_granting_tickets
    end
    tgts = base.or({
      created_at: {'$lt' => CASino.config.two_factor_authenticator[:timeout].seconds.ago},
      awaiting_two_factor_authentication: true
    }).or({
      created_at: {'$lt' => CASino.config.ticket_granting_ticket[:lifetime].seconds.ago},
      long_term: false
    }).or({
      created_at: {'$lt' => CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.ago}
    })
    CASino::ServiceTicket.in(ticket_granting_ticket_id: tgts.map(&:id)).destroy_all
    tgts.destroy_all
  end

  def same_user?(other_ticket)
    if other_ticket.nil?
      false
    else
      other_ticket.user_id == self.user_id
    end
  end

  def expired?
    if awaiting_two_factor_authentication?
      lifetime = CASino.config.two_factor_authenticator[:timeout]
    elsif long_term?
      lifetime = CASino.config.ticket_granting_ticket[:lifetime_long_term]
    else
      lifetime = CASino.config.ticket_granting_ticket[:lifetime]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
