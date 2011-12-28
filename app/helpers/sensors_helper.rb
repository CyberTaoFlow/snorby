module SensorsHelper
  def selected_preprocessor_value(role, preprocessor)
    return role.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor]["mode"] unless role.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor].nil?
    "inherited"
  end

  def selected_variable_value(role, variable)
    return role.override_attributes["redBorder"]["snort"]["vars"][variable] unless role.override_attributes["redBorder"]["snort"]["vars"][variable].nil?
    nil
  end
end
