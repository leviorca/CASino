
class CASino::ServiceRule
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: 'casino_service_rules'

  field :enabled,         type: Mongoid::Boolean, default: true
  field :order,           type: Integer
  field :name,            type: String
  field :url,             type: String
  field :regex,           type: Mongoid::Boolean, default: false

  index url: 1

  validates :enabled, :order, :name, :regex, presence: true
  validates :url, uniqueness: true, presence: true

  def self.allowed?(service_url)
    rules = self.where(enabled: true)
    if rules.empty? && !CASino.config.require_service_rules
      true
    else
      rules.any? { |rule| rule.allows?(service_url) }
    end
  end

  def allows?(service_url)
    if self.regex?
      regex = Regexp.new self.url, true
      if regex =~ service_url
        return true
      end
    elsif self.url == service_url
      return true
    end
    false
  end
end
