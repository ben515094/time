class User < ActiveRecord::Base
  before_save :lowercaseID
  before_save :encrypt_password
  has_many :timelogs
  belongs_to :school
  

  # Setup accessible (or protected) attributes for your model
  attr_accessible :school, :school_id, :tools, :conduct, :email, :password, :password_confirmation, :name_first, :name_last, :phone, :admin, :userid
  # attr_accessible :title, :body
  attr_accessor :password
  
  validates_uniqueness_of :userid
  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email
  
  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
  def lowercaseID
    self.userid = self.userid.downcase
  end
  def signed_in
    if self.timelogs.in_today.nil? || self.timelogs.in_today.empty?
      return false
    else
      return self.timelogs.in_today.first
    end
  end
  def full_name
    return "#{self.name_first} #{self.name_last}"
  end
  def build_hours
    total = 0
    self.timelogs.each do |log|
      if log.timein > ApplicationHelper.getStartBuildDate
        total = total + log.time_logged
      end
    end
    return Time.at(total).utc.strftime("%H:%M:%S")
  end
  def total_hours
    total = 0
    self.timelogs.each do |log|
      if log.timein>ApplicationHelper.getStartDate
        total = total + log.time_logged
      end
    end
    return Time.at(total).utc.strftime("%H:%M:%S")
  end
  def grouped_logs
    self.timelogs.order('timein asc').group_by{ |u| ApplicationHelper.toLocalTime(u.timein).beginning_of_week }
  end
end
