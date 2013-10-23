class Alert < ActiveRecord::Base
  belongs_to :access_point
  
  def send_email(ap=nil)
    # retrieve AP if 
    if ap.nil?
      ap = AccessPoint.with_properties_and_group.find(self.access_point_id)
    end
    
    puts "sending email..."
    
    self.sent = true
    self.save!
  end
  
  ### static methods
  
  # create alert
  def self.build(params)
    if params[:access_point_id].nil?
      raise(ArgumentError, ':access_point_id parameter missing')
    elsif params[:status].nil?
      raise(ArgumentError, ':status parameter missing')
    end
    
    # check if there is any pending alert for the specified access point
    # which has not been sent yet
    # and delete it cos is no longer needed
    # (status has changed before the time specified in the threshold)
    pending_alerts = Alert.where(
      :access_point_id => params[:access_point_id],
      :sent => false
    ).destroy_all()
    
    # create alert
    Alert.create(
      :access_point_id => params[:access_point_id],
      :action => params[:status] ? 'up' : 'down'
    )
  end
  
  # send all
  def self.send_all
    # init counter
    sent = 0
    
    # find unsent alerts
    alerts = where(:sent => false)
    
    # loop over collection
    alerts.each do |alert|
      ap = AccessPoint.with_properties_and_group.find(alert.access_point_id)
      
      # if alerts for this ap are deactivated skip and destroy the alert
      unless ap.alerts?
        alert.destroy
        next
      end
      
      # retrieve threshold
      threshold = ap.method("threshold_#{alert.action}").call
      threshold = threshold.to_i.minutes
      
      # (if the time in which the ap changed its status + the threshold time) is less than now
      # it means the threshold time has passed
      if alert.created_at + threshold < DateTime.now
        # send
        alert.send_email(ap)
        # increment counter
        sent += 1
      end
    end
    
    return sent
  end
end
