require 'mysql2'
require 'active_record'
require 'pry'
require_relative 'connect_db'

class Discussion < ActiveRecord::Base
  self.table_name = 'GDN_Discussion'
  self.primary_key = 'DiscussionID'

  def place
    @place ||= self.stub =~ /<b>Aufenthaltsort:(&nbsp;|\s)?<\/b>(<span>|&nbsp;|\s)*(.*?)(<\/span>|<br>|<hr>)/ ? $3.strip : 'Unbekannt'
    # @place ||= self.stub =~ /<b>Aufenthaltsort:(&nbsp;|\s)?<\/b>(&nbsp;|\s)?(.*?)<br>/ ? $3.strip : 'Unbekannt'
  end

  def prof
    @prof ||= self.stub =~ /<b>Profession:(&nbsp;|\s)?<\/b>(&nbsp;|\s)?(.*?)<br>/ ? $3.strip : 'Unbekannt'
  end

  def desc
    @desc ||= begin
      ele = self.stub =~ /<b>Kurzbeschreibung:(&nbsp;|\s)?<\/b>(&nbsp;|\s)?(.*?)<[bh]r>/ ? "(#{$3.strip})" : ''
      ele =~ %r{(-)} ? '' : ele
    end
  end
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

NpcID = Category.where(Name: 'NPCs').first.CategoryID
ArchivarID = User.where(Name: 'Archivar').first.UserID


# Erstmal alle einfügen, an dieser Stelle muss natürlich noch die Verbindung zu Ronny's Skript / DB geschaffen werden
# Man könnte hier aber zum Beispiel auch die entstandene ID in Ronnys DB zurückschreiben. Das macht es für das Link genereieren leichter.
def create_npc_templates
  ['Anselm Pechstein' , 'Gloria Pechstein ' , 'Abigail Kupferstich' , 'Florence Kupferstich' , 'Oberst Barn Schlick' , 'Alisa Schlick' , 'Bruder Mathes' , 'Claudine' , 'Johann Müllerson' , 'Johanna Müllerson' , 'Otto Müllerson' , 'Dala Müllerson' , 'Gunnar Bräuerle' , 'Marina Bräuerle' , 'Tim Halling' , 'Thea Halling' , 'Till Halling' , 'Tom Halling' , 'Johann Bennett' , 'Martin Bontrauer' , 'Berta Bontrauer' , 'Bruno Wollschläger' , 'Gabriela Wollschlägel' , 'Brehm Wollschläger' , 'Karl Tannhaus' , 'Liv Tannhaus' , 'Philippa Tannhaus' , 'Eliaz Wachtendorf' , 'Lisa Wachtendorf' , 'Gerrith Lew Wachtendorf' , 'Ungart' , 'Drusella' , 'Josefine' , 'Draig'].each do |name|
  # ['Dardiana Falconsflight','Ilundur Phoreneus','Jarl der Graue','Jochen Malluck','Johannes vom Silberschweif','Marhand Serpenthelm',"Theoloseus D'Antanes",'Thoralf Halvarson','Tolf Shmid'].each do |name|
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

  Discussion.where(CategoryID: NpcID).select('DiscussionID, Name, SUBSTRING(Body, 1, 250) AS stub').order(Name: :asc).each_with_index do |npc,idx|
    next if npc.Name =~ /Vorlage/

  # Discussion.where(CategoryID: NpcID).order(Name: :asc).select(:DiscussionID, :Name).each_with_index do |npc,idx|
    start_letter = npc.Name[0,1]
    if last_letter != start_letter
      letters << start_letter
      body += "</ul>" if idx > 0
      body += "<h2><a name='#{start_letter}'>#{start_letter}</h2>"
      body += "<ul>"
    end
    body += "<li><a href='/index.php?p=/discussion/#{npc.DiscussionID}'>#{npc.Name}</a> - #{npc.prof} aus #{npc.place} #{npc.desc}</li>"
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

def create_city_sort
  npc_index = Discussion.where(Name: 'Schnellübersicht NPCs - sortiert nach Orten').first
  body = ''

  list = {}
  Discussion.where(CategoryID: NpcID).select('DiscussionID, Name, SUBSTRING(Body, 1, 250) AS stub').order(Name: :asc).each do |npc|
    next if npc.Name =~ /Vorlage/

    list[npc.place] ||= []
    list[npc.place] << npc
  end

  list.sort.to_h.each_with_index do |(place,npcs),idx|
    body += "<h2><a name='#{place.underscore}'>#{place}</h2>"
    body += "<ul>"
    npcs.each do |npc|
      body += "<li><a href='/index.php?p=/discussion/#{npc.DiscussionID}'>#{npc.Name}</a> - #{npc.prof} #{npc.desc}</li>"
    end
    body += "</ul>"
  end

  head = "<span>Achtung - diese Liste wird automatisch erstellt und regelmäßig überschrieben. Manuelle Änderungen gehen verloren!</span><hr/>| #{list.keys.map{|a| "<a href='##{a.underscore}'>#{a}</a> | "}.join}<hr/>"

  npc_index.Body = head + body
  npc_index.UpdateUserID = ArchivarID
  npc_index.DateUpdated = Time.now
  npc_index.InsertIPAddress = '127.0.0.1'
  npc_index.save

  list.keys
end

PROF = /(Schneider|Schmied|Händler|Gerber)/
def create_prof_sort
  npc_index = Discussion.where(Name: 'Schnellübersicht NPCs - Händler und Handwerker').first
  body = ''

  list = {}
  Discussion.where(CategoryID: NpcID).select('DiscussionID, Name, SUBSTRING(Body, 1, 250) AS stub').order(Name: :asc).each do |npc|
    next if npc.Name =~ /Vorlage/ or npc.prof !~ PROF
    cat = $1

    list[cat] ||= []
    list[cat] << npc
  end
  
  list.sort.to_h.each_with_index do |(place,npcs),idx|
    body += "<h2><a name='#{place.underscore}'>#{place}</h2>"
    body += "<ul>"
    npcs.each do |npc|
      body += "<li><a href='/index.php?p=/discussion/#{npc.DiscussionID}'>#{npc.Name}</a> - #{npc.prof} aus #{npc.place} #{npc.desc}</li>"
    end
    body += "</ul>"
  end

  head = "<span>Achtung - diese Liste wird automatisch erstellt und regelmäßig überschrieben. Manuelle Änderungen gehen verloren!</span><hr/>| #{list.keys.map{|a| "<a href='##{a.underscore}'>#{a}</a> | "}.join}<hr/>"

  npc_index.Body = head + body
  npc_index.UpdateUserID = ArchivarID
  npc_index.DateUpdated = Time.now
  npc_index.InsertIPAddress = '127.0.0.1'
  npc_index.save
end

def create_or_update_places(places_with_npcs={})
  places_with_npcs.each do |npcp|
    d = Discussion.find_or_create_by(CategoryID: PlaceID, name: npcp)
    if d.Body.blank?
      # Use Template
    end

    # Update npc-list
  end
end

#create_npc_templates
create_abc_sort
create_prof_sort

npcp = create_city_sort
# create_or_update_places(npcp)

#binding.pry
