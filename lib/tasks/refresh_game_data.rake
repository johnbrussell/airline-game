desc "Add Markets to database."

task :refresh_data => :environment do
  GameData::Inputter.run
end
