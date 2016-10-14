require 'mysql2'
require 'active_record'
require 'pry'

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

#binding.pry

npc_id = Category.where(Name: 'NPCs').first.CategoryID
archivar_id = User.where(Name: 'Archivar').first.UserID

# Erstmal alle einfügen, an dieser Stelle muss natürlich noch die Verbindung zu Ronny's Skript / DB geschaffen werden
# Man könnte hier aber zum Beispiel auch die entstandene ID in Ronnys DB zurückschreiben. Das macht es für das Link genereieren leichter.
['Dardiana Falconsflight','Ilundur Phoreneus','Jarl der Graue','Jochen Malluck','Johannes vom Silberschweif','Marhand Serpenthelm',"Theoloseus D'Antanes",'Thoralf Halvarson','Tolf Shmid'].each do |name|
  next if Discussion.where(Name: name).any?
  Discussion.create CategoryID: npc_id, InsertUserID: archivar_id, Name: name, Body: "<h1>#{name}</h1>\n#TODO Hier kann alles zu dieser Person festgehalten werden", Format: 'HTML', DateInserted: Time.now, InsertIPAddress: '127.0.0.1'
end

# Sortiertung kann man leider nicht für einzelne Categorien einstellen. Wir haben Forumstyle aktiviert, das heißt da wo zuletzt was los war, das steht ganz oben.
# Um das zu "Umgehen" werden die NPC-Topics einfach sortiert und in der Reihenfolge "getoucht" so, dass die Zeitstempel dann passen sollten.
# Ein Hoch auf Backendzugriffe und mächte Programmiersprachen ;-)

Discussion.where(CategoryID: npc_id).order(Name: :asc).each do |npc|
  npc.DateInserted = Time.now
#  npc.UpdateUserID = archivar_id
#  npc.DateUpdated = Time.now
#  npc.UpdateIPAddress = '127.0.0.1',
#  npc.DateLastComment = Time.now,
#  npc.LastCommentUserID = archivar_id,

  npc.save
  sleep 1
end

npc_index = Discussion.where(Name: 'Schnellübersicht NPCs - alphabetisch').first
body = ''

last_letter = ''
qty = 0
letters = []

Discussion.where(CategoryID: npc_id).order(Name: :asc).select(:DiscussionID, :Name).each_with_index do |npc, idx|
  start_letter = npc.Name[0,1]
  if last_letter != start_letter
    letters << start_letter
    body += "</ul>" if idx > 0
    body += "<h2><a name='#{start_letter}'>#{start_letter}</h2>"
    body += "<ul>"
  end
  body += "<li><a href='/index.php?p=/discussion/#{npc.DiscussionID}'>#{npc.Name}</a></li>"
  last_letter = start_letter
  qty = idx
end
body += "</ul>"

head = "<span>Achtung - diese Liste wird automatisch erstellt und regelmäßig überschrieben. Manuelle Änderungen gehen verloren!</span>\nAnzahl erfasster NPC's: #{qty}<hr/>| #{letters.map{|a| "<a href='##{a}'>#{a}</a> | "}.join}<hr/>"

npc_index.Body = head + body
npc_index.save

# binding.pry

# Testdaten löschen
# Discussion.where(CategoryID: npc_id).delete_all

