module SensorsHelper
  def selected_preprocessor_value(rule, preprocessor)
    return rule.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor]["mode"] unless rule.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor].nil?
    "inherited"
  end
end
