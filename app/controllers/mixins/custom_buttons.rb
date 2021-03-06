module Mixins::CustomButtons
  extend ActiveSupport::Concern

  def custom_toolbar
    return nil unless self.class.instance_eval { @custom_buttons }

    @explorer ? custom_toolbar_explorer : custom_toolbar_simple
  end

  def custom_toolbar_explorer
    if x_tree
      if @display == "main" && @record
        Mixins::CustomButtons::Result.new(:single)
      elsif @lastaction == "show_list"
        Mixins::CustomButtons::Result.new(:list)
      elsif x_tree[:tree] == :rbac_tree
        Mixins::CustomButtons::Result.new(:single)
      else
        'blank_view_tb'
      end
    end
  end

  def custom_toolbar_simple
    if @record && %w(show show_dashboard).include?(@lastaction) && %w(dashboard main).include?(@display)
      Mixins::CustomButtons::Result.new(:single)
    elsif @lastaction == "show_list"
      Mixins::CustomButtons::Result.new(:list)
    end
  end

  class_methods do
    def has_custom_buttons
      @custom_buttons = true
    end
  end
end
