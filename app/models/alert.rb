class Alert < ActiveRecord::Base
  belongs_to :access_point

  def send_email(ap=nil)
    # retrieve AP if not passed
    if ap.nil?
      ap = AccessPoint.with_properties_and_group.find(self.access_point_id)
    end

    # send email to group
    unless ap.group_alerts_email.blank?
      begin
        AlertMailer.notification(self, ap, ap.group_alerts_email).deliver
      rescue Exception => e
        log_exception(e)
        return false
      end
    end

    # send email to manager if any
    unless ap.manager_email.blank?
      begin
        AlertMailer.notification(self, ap, ap.manager_email, false).deliver
      rescue Exception => e
        log_exception(e)
        return false
      end
    end

    # set sent as true and save
    self.sent = true
    self.save!
    return true
  end

  ### static methods

  # create alert
  def self.build(params)
    # returns true if alert has been created, false otherwise

    if params[:access_point_id].nil?
      raise(ArgumentError, ':access_point_id parameter missing')
    elsif params[:status].nil?
      raise(ArgumentError, ':status parameter missing')
    end

    status = params[:status] ? 'up' : 'down'
    ap_id = params[:access_point_id]

    # check if there is any pending alert for the specified access point
    # which has not been sent yet
    # and delete it cos is no longer needed
    # (status has changed before the time specified in the threshold)
    pending_alerts = Alert.where(
      :access_point_id => ap_id,
      :sent => false
    ).destroy_all()

    # check if the previous alert for this access point has the same action (up or down)
    # in case the action is the same don't create alert
    # this avoids sending more consecutive alerts with same message
    # (immagine receiving 3 times an UP alert without getting any DOWN, we want to avoid this, right?)
    last_alert = Alert.where(
      :access_point_id => ap_id,
      :sent => true
    ).last

    if last_alert and last_alert.action == status
      return false
    end

    # create alert
    Alert.create(
      :access_point_id => ap_id,
      :action => status
    )

    return true
  end

  # send all
  def self.send_all
    # init counter
    sent = 0

    # find unsent alerts
    alerts = where(:sent => false)

    # loop over collection
    alerts.each do |alert|
      begin
        ap = AccessPoint.with_properties_and_group.find(alert.access_point_id)
      rescue ActiveRecord::RecordNotFound
        # if ap not found destroy alert and continue
        alert.destroy
        next
      end

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
        if alert.send_email(ap)
          # increment counter
          sent += 1
        end
      end
    end

    return sent
  end
end
