# -*- ruby -*-

namespace :fountain do

  def prompt_variable(prompt, variable, previous)
    print prompt
    previous = previous.to_s.chomp
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
  task :s0_setup_jrc => :environment do

    SystemVariable.dump_vars

    prompt_variable_number("Set initial serial number",
                           :serialnumber)

    prompt_variable_value("Hostname for this instance",
                          :hostname)

    prompt_variable_value("ACP domain for this registrar",
                          :acp_domain)

    SystemVariable.dump_vars
  end

end
