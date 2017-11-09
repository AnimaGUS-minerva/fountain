# -*- ruby -*-

namespace :fountain do

  def prompt_variable(prompt, variable, previous)
    print prompt
    print "(default #{previous}): "
    value = STDIN.gets

    if value.blank?
      value = previous
    end

    value
  end

  def prompt_variable_number(prompt, variable)
    SystemVariable.setnumber(variable,
                             prompt_variable(prompt,
                                             variable,
                                             SystemVariable.number(variable)))
  end

  def prompt_variable_value(prompt, variable)
    SystemVariable.setvalue(variable,
                            prompt_variable(prompt,
                                            variable,
                                            SystemVariable.string(variable)))
  end

  desc "Do initial setup of sytem variables"
  task :setup_masa => :environment do

    SystemVariable.dump_vars

    prompt_variable_number("Set initial serial number",
                           :serialnumber)

    prompt_variable_value("Hostname for this instance",
                          :hostname)

    prompt_variable_value("Inventory directory for this instance",
                          :inventory_dir)

    prompt_variable_value("Setup inventory base mac address",
                          :base_mac)

    SystemVariable.dump_vars
  end

end
