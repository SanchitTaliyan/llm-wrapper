class BaseSerializer
  def self.serialize(object, options = {})
    new(object, options).serialize
  end

  def initialize(object, options = {})
    @object = object
    @options = options
  end

  def serialize
    raise NotImplementedError, "Subclasses must implement #serialize"
  end

  private

  attr_reader :object, :options

  def formatted_timestamp(timestamp)
    timestamp&.iso8601
  end
end
