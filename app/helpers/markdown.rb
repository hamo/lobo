#!/usr/bin/env ruby
# coding: utf-8
#Description: Markdown renderer for Redcarpet
#

# a Markdown renderer with some limitations
class HTMLStripped < Redcarpet::Render::HTML
  #def block_code(code, language)
    #Albino.safe_colorize(code, language)
  #end

  def header(text, level)
    "<strong>#{'#'* level} #{text} #{'#' * level}</strong>"
  end
end

MARKDOWN ||= Redcarpet::Markdown.new(
  HTMLStripped.new(
    :hard_wrap => true,
    :no_images => true,
    :filter_html => true,
    :no_styles => true,
  )
)
