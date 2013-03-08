module Backup
  class Model
    extend Dsl
 
    spec :initialize do
      dsl do
        spec :database do
          post_cond do |a|
            db = a[0]

            if db.class == Backup::Database::PostgreSQL
              postgres_succ = true
              n = 0 - "pg_dump".length - 1
              psql = db.pg_dump_utility[0..n] + "psql"

              username_options = db.username.to_s.empty? ? " " : "-U #{db.username.to_s}"
              password_options = db.password.to_s.empty? ? '' : "PGPASSWORD='#{password}' "

              cmd = "#{password_options} " + "#{psql} -d #{db.name} #{username_options} --command=\";\""

              pipeline = Pipeline.new
              pipeline << cmd
              pipeline.run

              postgres_succ = false if not pipeline.success?
            end

            (db.class == Backup::Database::PostgreSQL and postgres_succ) or
              db.class != Backup::Database::PostgreSQL
          end          
        end

        spec :store_with do
          post_cond do |a|
            sw = a[0]

            if sw.class == Backup::Storage::SFTP
              sftp_connect_ok = true

              begin
                Net::SFTP.start(sw.ip, sw.username, 
                                :password => sw.password, :port => sw.port) 
              rescue
                sftp_connect_ok = false
              end
            end

            (sw.class == Backup::Storage::SFTP and sftp_connect_ok) or
              sw.class != Backup::Storage::SFTP
          end
        end
      end
    end
  end
  
  class Archive
    extend Dsl

    spec :initialize do
      dsl do
        spec :add do
          pre_cond do |path|
            File.exist?(path)
          end
        end

        spec :exclude do
          pre_cond do |path|
            File.exist?(path)
          end
        end
      end

    end
  end

  module Storage
    class Local
      extend Dsl
      
      spec :initialize do
        dsl do
          spec :path= do
            # if dir path does not exist, backup will create it later
            
            pre_cond do |path|
              if File.exist?(path)
                # make sure the path is not an exisiting regular file
                File.directory?(path) and File.writable?(path) 
              else
                true
              end
            end
          end
        end
      end
    end

  end
end


