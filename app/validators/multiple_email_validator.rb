class MultipleEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    values = value.split(',')
    
    for value in values
      unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        record.errors[attribute] << (options[:message] || I18n.t(:Value_is_not_an_email, :value => value))
      end
    end
  end
end