# Snorby - All About Simplicity.
# 
# Copyright (c) 2010 Dustin Willis Webber (dustin.webber at gmail.com)
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

namespace :snorby do
  
  desc 'Setup'  
  task :setup => :environment do
    require "./lib/snorby/dm/types"
        
    Rake::Task['secret'].invoke
    
    # Create the snorby database if it does not currently exist
    Rake::Task['db:create'].invoke
    
    # Setup the snorby database
    Rake::Task['db:autoupgrade'].invoke
    
    # Load Default Records
    Rake::Task['db:seed'].invoke
    
  end
  
  desc 'Update Snorby'
  task :update => :environment do
    require "./lib/snorby/dm/types"

    # Setup the snorby database
    Rake::Task['db:autoupgrade'].invoke
    
    # Load Default Records
    Rake::Task['db:seed'].invoke
    
  end
  
  desc 'Remove Old CSS/JS packages and re-bundle'
  task :refresh => :environment do
    `jammit`
  end
  
  desc 'Soft Reset - Reset Snorby metrics'
  task :soft_reset => :environment do
    
    # Reset Counter Cache Columns
    puts 'Reseting Snorby metrics and counter cache columns'
    Severity.update!(:events_count => 0)
    Sensor.update!(:events_count => 0)
    Signature.update!(:events_count => 0)

    puts 'This could take awhile. Please wait while the Snorby cache is rebuilt.'
    Snorby::Worker.reset_cache(:all, true)
  end
  
  desc 'Hard Reset - Rebuild Snorby Database'
  task :hard_reset => :environment do
    
    # Drop the snorby database if it exists
    Rake::Task['db:drop'].invoke
    
    # Invoke the snorby:setup rake task
    Rake::Task['snorby:setup'].invoke
    
  end
  
end
