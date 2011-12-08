#! /usr/bin/ruby
#

require 'nkf'

def value(line)
  line.split(/"/)[-2]
end

def fout(name, value)
  puts "  #{name} = {#{value}},"
end

out = open("rename.sh","w")

while line=gets
  case line
  when /title *=/
    ttl = value(line)
  when /volume/
    vol = value(line)
  when /pages/
    pages = value(line)
    fpage = pages.split(/-/).shift
  when /journal *=/
    base = value(line)
    jnl = base.split(/\s*[:ÅF]/).shift
    line = nil
    fout "journal", jnl
  when /year/
    year,month,day = value(line).split(/-/)
    line = nil
    fout "year", year
    fout "month", month
    fout "day", day
  when /url/i
    tag = line.split('/')[-2]
    puts line
    pdfname = [year,vol,fpage,ttl.sub(/ *: */,"ÅE")].join("_")+".pdf"
    ciniipdf = tag+".pdf"
#    if File.file?(ciniipdf)
#      File.rename(ciniipdf,NKF.nkf("-Sw",pdfname))
#    end
    out.puts "mv '#{ciniipdf}' '#{NKF.nkf("-Sw",pdfname)}'"
    fout "pdf",pdfname
  end
  puts line if line
end


