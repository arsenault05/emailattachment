require 'mail'
require 'yaml'

config = YAML.load_file('config.yml')

Mail.defaults do
  retriever_method :imap, :address    => config["mail_config"]["address"],
                          :port       => config["mail_config"]["port"],
                          :user_name  => config["mail_config"]["user_name"],
                          :password   => config["mail_config"]["password"],
                          :enable_ssl => true
end

def create_filename(mail, filename)
  address = mail.from.to_s
  sent = mail.date.to_s

  filename = "#{address}_#{sent}_#{filename}"
  filename.gsub(/[^0-9a-z\._-]/i, '')
end

def download_attachment(mail, download_path)
  mail.attachments.each do |attachment|
    filename = create_filename(mail, attachment.filename)

    begin
      File.open("#{download_path}/#{filename}", "w+b", 0644) do |f|
        f.write attachment.body.decoded
        puts "Wrote file to #{download_path} with name #{filename}"
      end
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end

Mail.find_and_delete do |mail|
  download_attachment(mail, config["download_path"])
end
