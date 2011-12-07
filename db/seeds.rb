# Define the snort schema version
SnortSchema.create(:vseq => 107, :ctime => Time.now, :version => "Snorby #{Snorby::VERSION}") if SnortSchema.first.blank?

# Default user setup
User.create(:name => 'Administrator', :email => 'admin@redborder.net', :password => 'redborder', :password_confirmation => 'redborder', :admin => true) if User.all.blank?

# Snorby General Settings
Setting.set(:company, 'redBorder Networks') unless Setting.company?
Setting.set(:email, 'admin@redborder.net') unless Setting.email?
Setting.set(:signature_lookup, 'http://rootedyour.com/snortsid?sid=$$gid$$:$$sid$$') unless Setting.signature_lookup?
Setting.set(:daily, 1) unless Setting.daily?
Setting.set(:weekly, 1) unless Setting.weekly?
Setting.set(:monthly, 1) unless Setting.monthly?
Setting.set(:lookups, 1) unless Setting.lookups?
Setting.set(:notes, 1) unless Setting.notes?
Setting.set(:geoip, 0) unless Setting.geoip?

# Remove Legacy Settings
Setting.get(:openfpc) ? Setting.get(:openfpc).destroy! : nil
Setting.get(:openfpc_url) ? Setting.get(:openfpc_url).destroy! : nil

# Full Packet Capture Support
Setting.set(:packet_capture_url, nil) unless Setting.packet_capture_url?
Setting.set(:packet_capture, nil) unless Setting.packet_capture?
Setting.set(:packet_capture_type, 'openfpc') unless Setting.packet_capture_type?
Setting.set(:packet_capture_auto_auth, 1) unless Setting.packet_capture_auto_auth?
Setting.set(:packet_capture_user, nil) unless Setting.packet_capture_user?
Setting.set(:packet_capture_password, nil) unless Setting.packet_capture_password?

# Setting.set(:geoip, nil) unless Setting.geoip?
Setting.set(:autodrop, nil) unless Setting.autodrop?
Setting.set(:autodrop_count, nil) unless Setting.autodrop_count?

# Load Default Classifications

Classification.first_or_create({ :name => "Unauthorized Root Access" }, {
  :name => 'Unauthorized Root Access',
  :description => 'Unauthorized Root Access',
  :hotkey => 1,
  :locked => true
})

Classification.first_or_create({ :name => "Unauthorized User Access" }, {
  :name => 'Unauthorized User Access',
  :description => 'Unauthorized User Access',
  :hotkey => 2,
  :locked => true
})

Classification.first_or_create({ :name => "Attempted Unauthorized Access" }, {
  :name => 'Attempted Unauthorized Access',
  :description => 'Attempted Unauthorized Access',
  :hotkey => 3,
  :locked => true
})

Classification.first_or_create({ :name => "Denial of Service Attack" }, {
  :name => 'Denial of Service Attack',
  :description => 'Denial of Service Attack',
  :hotkey => 4,
  :locked => true
})

Classification.first_or_create({ :name => "Policy Violation" }, {
  :name => 'Policy Violation',
  :description => 'Policy Violation',
  :hotkey => 5,
  :locked => true
})

Classification.first_or_create({:name => "Reconnaissance"}, {
  :name => 'Reconnaissance',
  :description => 'Reconnaissance',
  :hotkey => 6,
  :locked => true
})

Classification.first_or_create({:name => "Virus Infection"}, {
  :name => 'Virus Infection',
  :description => 'Virus Infection',
  :hotkey => 7,
  :locked => true
})

Classification.first_or_create({:name => "False Positive"}, {
  :name => 'False Positive',
  :description => 'False Positive',
  :hotkey => 8,
  :locked => true
})

# Load Default Severities
if Severity.all.blank?
  Severity.create(:id => 1, :sig_id => 1, :name => 'High Severity', :text_color => "#ffffff", :bg_color => "#ff0000")
  Severity.create(:id => 2, :sig_id => 2, :name => 'Medium Severity', :text_color => "#ffffff", :bg_color => "#fab908")
  Severity.create(:id => 3, :sig_id => 3, :name => 'Low Severity', :text_color => "#ffffff", :bg_color => "#3a781a")
end

# Load Default Action Rules
if RuleAction.all.blank?
  RuleAction.create(:id => 1, :name => 'pass'     , :description => 'Ignore the packet')
  RuleAction.create(:id => 2, :name => 'alert'    , :description => 'Generate an alert using the selected alert method, and then log the packet')
  RuleAction.create(:id => 3, :name => 'drop'     , :description => 'Block and log the packet')
  RuleAction.create(:id => 4, :name => 'log'      , :description => 'Log the packet')
  RuleAction.create(:id => 5, :name => 'sdrop'    , :description => 'Block the packet but do not log it')
  RuleAction.create(:id => 6, :name => 'reject'   , :description => 'Block the packet, log it, and then send a TCP reset if the protocol is TCP or an ICMP port unreachable')
  RuleAction.create(:id => 7, :name => 'inherited', :description => 'This rule will be inherited from its parents.')
end

# Sensor root
Sensor.create(:name => "root", :domain => true) if Sensor.first(:name => "root").nil?
