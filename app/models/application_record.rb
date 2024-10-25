class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.enum_choices_for_selection(enum_name)
    send(enum_name.to_s.pluralize).map { |enum_key, enum_value| [human_enum_name(enum_name, enum_key), enum_value] }
  end

  def self.human_enum_name(enum_name, enum_value)
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def human_enum_value_name(enum_name)
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{send(enum_name)}")
  end
end
