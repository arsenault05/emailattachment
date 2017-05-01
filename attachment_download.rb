require 'mail'
require 'yaml'
require 'google_drive'

PDF_MIME_TYPE = 'application/pdf'

config = YAML.load_file('config/config.yml')
session = GoogleDrive::Session.from_config("config/google_config.json")
exit
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

def upload_attachment(mail, download_path, session)
  mail.attachments.each do |attachment|
    mime_type = attachment.mime_type
    filename = create_filename(mail, attachment.filename)

    begin
      raise "invalid filetype #{mime_type} can only accept #{PDF_MIME_TYPE}" if mime_type != PDF_MIME_TYPE

      session.upload_from_file(attachment.filename, filename, convert: false)
      puts "Wrote file to google drive with name #{filename}"

      return true
    rescue => e
      puts "Unable to upload to google drive for #{filename} because #{e.message}"
      return false
    end
  end
end

def mark_as_read(uid, imap)
  imap.uid_store(uid, "+FLAGS", [Net::IMAP::SEEN])
end

Mail.find(keys: ['NOT','SEEN']) do |mail, imap, uid|
  mark_as_read(uid, imap) if upload_attachment(mail, config["download_path"], session)
end
