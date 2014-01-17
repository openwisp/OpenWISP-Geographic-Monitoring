module GroupsHelper
  
  # returns POST value if any
  # otherwise returns value from DB if any
  # otherwise returns general default value (from CONFIG)
  def alerts_placeholder(group, field)
    value = group.attributes[field]
    
    param = params[:group][field.to_sym] rescue nil
    
    if param
      return param
    elsif value.nil?
      return CONFIG[field]
    else
      return value
    end
  end
  
end
