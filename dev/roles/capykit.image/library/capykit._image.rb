#!/usr/bin/env ruby
# WANT_JSON

# Load QB's Ansible module autorun harness
load ENV['QB_AM_AUTORUN_PATH'] if ENV['QB_AM_AUTORUN_PATH']

require 'nrser/core_ext/object/lazy_var'

require 'qb'
require 'qb/docker'
require 'qb/docker/image/module'

class CapykitImageGetArgs < QB::Docker::Image::Module
  def self.repo
    "beiarea"
  end # .repo
  
  
  def self.repo_name
    "capykit"
  end # .repo_name
  
  
  def main
    super
  end
end # class
