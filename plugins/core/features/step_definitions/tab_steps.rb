
Given /^there is an? (\w+) open$/ do |tab_type| # "
  Redcar.win.new_tab(Redcar.const_get(tab_type))
end

Then /^I should see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.visible_contents_as_string.should include(text)
end

Then /^I should not see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.visible_contents_as_string.should_not include(text)
end