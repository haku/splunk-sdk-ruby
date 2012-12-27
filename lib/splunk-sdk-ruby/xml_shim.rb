def require_xml_library(library)
  if library == :nokogiri
    require 'nokogiri'
    $default_xml_library = :nokogiri
  else
    require 'rexml/document'
    require 'rexml/streamlistener'
    $xml_library = :rexml
  end
end

if ENV['RUBY_XML_LIBRARY'].nil?
  begin
    require_xml_library(:nokogiri)
  rescue LoadError
    require_xml_library(:rexml)
  end
elsif ENV['RUBY_XML_LIBRARY'].downcase == "rexml"
  require_xml_library(:rexml)
elsif ENV['RUBY_XML_LIBRARY'].downcase == "nokogiri"
  require_xml_library(:nokogiri)
else # Default: try to use Nokogiri, and otherwise fall back on REXML.
  raise StandardError.new("Unknown XML library: #{ENV['RUBY_XML_LIBRARY']}")
end