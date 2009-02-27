class TinybackupsController < ActionController::Base
  
  layout nil
  before_filter :load_config
  
  def new
    all_tables = []
    mysql = ActiveRecord::Base.connection.execute("show tables")
    mysql.each {|t| all_tables << t}
    @exclude_tables = all_tables.flatten.grep(/log/).join(", ")
  end
  
  def create
    system "#{mysqldump_command} | nice #{compress_command} > #{target_filename}"
    send_file(target_filename, :filname => target_filename)
  end
  
  
private
  def load_config
    @config = ActiveRecord::Base.connection.instance_variable_get("@config")
    @db_name = @config[:database]
  end
  
  def compress_command
    if params[:compress] == "bzip2"
      "bzip2 -9 - "
    else
      "gzip -9 - "
    end
  end
  
  def ext
    if params[:compress] == "bzip2"
      "bz2"
    else
      "gz"
    end
  end
  
  def target_filename
    @target_filename ||= File.join(RAILS_ROOT, "tmp", Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S.sql.#{ext}"))
  end
  
  def mysqldump_command
    exclude_tables = params[:exclude_tables].split(",").collect(&:strip)
    password = @config[:password] ? "--pasword=\"#{password}\"" : nil
    
    "mysqldump -ceKq --single-transaction --tz-utc -u #{@config[:username]} #{password} #{@db_name} #{exclude_tables.map{|t| "--ignore-table=#{@db_name}.#{t}"}.join(" ")}"
  end
end