#! /usr/bin/ruby -Ku

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'tempfile'
require 'nkf'   # to convert UTF8

def field(key, value)
  puts "  #{key} = {#{value}},\r"
end


if ARGV[0] == "-d"
  $down = true
  ARGV.shift
else
  $down = false
end

uri = ARGV[0]

#file = Tempfile.new("journal-archive-work")
file = open("resent.html","w+")
open(uri){|u|
  file.write NKF.nkf("-w",u.read)
}
file.rewind

html = Hpricot(file)

file.close

doc =Hpricot( (html/"body").inner_html )

ttls = (doc/'td.blackbd').select{|x| (x/:a).size > 0}.map{|x| x.inner_text}
paper_list = (doc/'td.black').select{|x| x.inner_text =~ /pp\./}
links = paper_list.map{|x| (x/'a').map{|a| a['href']} }
bodies = paper_list.map{|x| x.inner_text}

data = bodies.map{|x| x.gsub(/\n/,'|')}.join("\n").scan(/^([^|]+)\|([^,]+),.*Vol\.\D*(\d+).*\((\d+)\).*No\.\D*(\d+).*pp\.\D*(\d+-\d+)/)

puts <<KKK
% This file was created with JabRef 2.7.2.\r
% Encoding: UTF8\r
KKK

dir = File.basename(Dir.pwd)

ttls.size.times do |i|
  title = ttls[i].gsub(/:/,'：')
  abstract_link, pdf_link = *links[i]
  authors,journal,volume,year,number,pages = *data[i]
  #authors = NKF.nkf("-Ws", authors)
  first_page, last_page = * pages.split(/-+/)
  tag = [year,volume,first_page].join('_')
  pdf_file = "#{tag}_#{title}.pdf"
  unless File.file?(pdf_file)
    if $down
      $stderr.puts "Fetching #{pdf_file}"
      $stderr.puts "from: #{pdf_link}"
      open(pdf_link,"rb") do |efile|
        open(pdf_file,"wb") do |out|
          out.write(efile.read)
          out.close
        end
      end
    end
  end
  #pdf_file = NKF.nkf("-Ws",pdf_file)
  #title = {#{NKF.nkf("-Ws",title)}},
  #journal = {#{NKF.nkf("-Ws",journal)}},
  puts "@ARTICLE{#{tag},\r"
  field "author", authors.split(/,/).join(' and ')
  field "title", title
  field "journal", journal
  field "year", year
  field "volume", volume
  field "pages", pages
  field "number", number if number
  field "url", abstract_link
  field "memo", "PDF_LINK: #{pdf_link}"
  field "file", "#{pdf_file}:#{dir}\\\\#{pdf_file}:PDF"
  puts "}\r\n\r"
end




