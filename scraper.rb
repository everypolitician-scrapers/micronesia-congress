#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

terms = { 
  19 => 'http://www.fsmcongress.fm/19th%20Congress/19members.html',
  18 => 'http://www.fsmcongress.fm/18th%20Congress/member.html',
  17 => 'http://www.fsmcongress.fm/17th%20Congress/members%20page.html',
}

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.xpath('.//p[contains(., "Speaker")]/ancestor::table//img').each do |img|
    data = img.xpath('../following-sibling::p').map { |n| n && n.text.gsub(/[[:space:]]/, ' ').strip }.compact.reject(&:empty?)
    # Work around Vice Speaker Martin having an extra level of # nesting
    data = img.xpath('../../following-sibling::p').map { |n| n && n.text.strip }.compact if data.size.zero?

    data << URI.join(url, URI.escape(img.attr('src')))
    data << term
    puts data.to_csv
  end
end

terms.each do |term, url|
  scrape_list(term, url)
end
