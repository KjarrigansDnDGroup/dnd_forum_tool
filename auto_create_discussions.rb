require 'mysql2'
require 'active_record'
require 'pry'
require_relative 'connect_db'

class Discussion < ActiveRecord::Base
  self.table_name = 'GDN_Discussion'
  self.primary_key = 'DiscussionID'
end

class Category < ActiveRecord::Base
  self.table_name = 'GDN_Category'
  self.primary_key = 'CategoryID'
end

class Role < ActiveRecord::Base
  self.table_name = 'GDN_Role'
  self.primary_key = 'RoleID'
end

class User < ActiveRecord::Base
  self.table_name = 'GDN_User'
  self.primary_key = 'UserID'
end

connect_db
binding.pry

NpcID = Category.where(Name: 'NPCs').first.CategoryID
ArchivarID = User.where(Name: 'Archivar').first.UserID


# Erstmal alle einfügen, an dieser Stelle muss natürlich noch die Verbindung zu Ronny's Skript / DB geschaffen werden
# Man könnte hier aber zum Beispiel auch die entstandene ID in Ronnys DB zurückschreiben. Das macht es für das Link genereieren leichter.
def create_npc_templates
  ['Dardiana Falconsflight','Ilundur Phoreneus','Jarl der Graue','Jochen Malluck','Johannes vom Silberschweif','Marhand Serpenthelm',"Theoloseus D'Antanes",'Thoralf Halvarson','Tolf Shmid'].each do |name|
    next if Discussion.where(Name: name).any?
    Discussion.create CategoryID: NpcID, InsertUserID: ArchivarID, Name: name, Body: "<h1>#{name}</h1>\n<b>Profession:</b> Dorfschneider|Erzmagier|Mutti von Tarso\n<b>Aufenthaltsort:</b> Otternburg\n<b>Kurzbeschreibung:</b> Die taucht dann auch in der Übersicht auf<hr/>#TODO Hier kann alles zu dieser Person festgehalten werden", Format: 'HTML', DateInserted: Time.now, InsertIPAddress: '127.0.0.1'
  end

  cat = Category.find(NpcID)
  cat.CountDiscussions = Discussion.where(CategoryID: NpcID).count
  cat.save
end

def create_abc_sort
  npc_index = Discussion.where(Name: 'Schnellübersicht NPCs - alphabetisch').first
  body = ''

  last_letter = ''
  letters = []

  Discussion.where(CategoryID: NpcID).order(Name: :asc).select(:DiscussionID, :Name).each_with_index do |npc,idx|
    start_letter = npc.Name[0,1]
    if last_letter != start_letter
      letters << start_letter
      body += "</ul>" if idx > 0
      body += "<h2><a name='#{start_letter}'>#{start_letter}</h2>"
      body += "<ul>"
    end
    body += "<li><a href='/index.php?p=/discussion/#{npc.DiscussionID}'>#{npc.Name}</a></li>"
    last_letter = start_letter
  end
  body += "</ul>"
  
  head = "<span>Achtung - diese Liste wird automatisch erstellt und regelmäßig überschrieben. Manuelle Änderungen gehen verloren!</span><hr/>| #{letters.map{|a| "<a href='##{a}'>#{a}</a> | "}.join}<hr/>"
  
  npc_index.Body = head + body
  npc_index.UpdateUserID = ArchivarID
  npc_index.DateUpdated = Time.now
  npc_index.InsertIPAddress = '127.0.0.1'
  npc_index.save
end

create_npc_templates
create_abc_sort
