class GenericObjectDefinitionController < ApplicationController
  before_action :check_privileges
  before_action :get_session_data

  after_action :cleanup_action
  after_action :set_session_data

  include Mixins::GenericListMixin
  include Mixins::GenericSessionMixin
  include Mixins::GenericShowMixin

  menu_section :automate

  def self.model
    GenericObjectDefinition
  end

  def show_list
    build_tree
    super
    self.x_active_tree ||= :generic_object_definitions_tree
    self.x_node ||= 'root'
    node_info(x_node)
  end

  def show
    build_tree
    super
    self.x_node = "god-#{to_cid(params[:id])}"
    @breadcrumbs = []
  end

  def build_tree
    @tree = TreeBuilderGenericObjectDefinition.new(:generic_object_definitions_tree, :generic_object_definitions_tree, @sb)
  end

  def button
    if @display == 'generic_objects' && params[:pressed] == 'generic_object_tag'
      tag(GenericObject)
      return
    end
    javascript_redirect(
      case params[:pressed]
      when 'generic_object_definition_new'
        {:action => 'new'}
      when 'generic_object_definition_edit'
        {:action => 'edit', :id => from_cid(params[:id] || params[:miq_grid_checks])}
      when 'ab_group_new'
        {:action => 'custom_button_group_new', :id => from_cid(params[:id] || params[:miq_grid_checks])}
      when 'ab_group_edit'
        {:action => 'custom_button_group_edit', :id => from_cid(params[:id])}
      end
    )
  end

  def new
    assert_privileges('generic_object_definition_new')
    drop_breadcrumb(:name => _("Add a new Generic Object Class"), :url => "/generic_object_definition/new")
    @in_a_form = true
  end

  def edit
    assert_privileges('generic_object_definition_edit')
    drop_breadcrumb(:name => _("Edit Generic Object Class"), :url => "/generic_object_definition/edit/#{params[:id]}")
    @generic_object_definition = GenericObjectDefinition.find(params[:id])
    @in_a_form = true
  end

  def self.display_methods
    %w(generic_objects)
  end

  def default_show_template
    "generic_object_definition/show"
  end

  def display_tree
    true
  end

  def custom_button_group_new
    assert_privileges('ab_group_new')
    title = _("Add a new Custom Button Group")
    @generic_object_definition = GenericObjectDefinition.find(params[:id])
    render_form(title)
  end

  def custom_button_group_edit
    assert_privileges('ab_group_edit')
    @custom_button_group = CustomButtonSet.find(params[:id])
    title = _("Edit Custom Button Group '#{@custom_button_group.name}'")
    render_form(title)
  end

  private

  def node_type(node)
    node_prefix = node.split('-').first
    case node_prefix
    when 'root' then :root
    when 'god'  then :god
    when 'cbg'  then :button_group
    when 'xx'   then :actions
    else        raise 'Invalid node type.'
    end
  end

  def node_info(node)
    case node_type(node)
    when :root         then root_node_info
    when :god          then god_node_info(node)
    when :actions      then actions_node_info(node)
    when :button_group then custom_button_group_node_info(node)
    end
  end

  def root_node_info
    @root_node = true
    @right_cell_text = _("All %{models}") % {:models => _("Generic Object Classes")}
  end

  def god_node_info(node)
    @god_node = true
    @record = GenericObjectDefinition.find(from_cid(node.split('-').last))
    @right_cell_text = _("Generic Object Class %{record_name}") % {:record_name => @record.name}
  end

  def actions_node_info(node)
    @actions_node = true
    @record = GenericObjectDefinition.find(from_cid(node.split('-').last))
    @right_cell_text = _("Actions for %{model}") % {:model => _("Generic Object Class")}
  end

  def custom_button_group_node_info(node)
    @custom_button_group_node = true
    @record = CustomButtonSet.find(from_cid(node.split("-").last))
    @right_cell_text = _("Custom Button Set %{record_name}") % {:record_name => @record.name}
  end

  def render_form(title)
    presenter = ExplorerPresenter.new(:active_tree => x_active_tree)
    @in_a_form = true
    presenter[:right_cell_text] = title
    presenter.replace(:main_div, r[:partial => 'custom_button_group_form'])
    presenter.hide(:paging_div)
    presenter[:lock_sidebar] = true
    build_toolbar("x_summary_view_tb")

    render :json => presenter.for_render
  end

  def process_root_node(presenter)
    root_node_info
    process_show_list
    presenter.replace(:main_div, r[:partial => 'list'])
    presenter.show(:paging_div)
    build_toolbar("x_gtl_view_tb")
  end

  def process_god_node(presenter, node)
    god_node_info(node)
    presenter.replace(:main_div, r[:partial => 'show_god'])
    presenter.hide(:paging_div)
    build_toolbar("x_summary_view_tb")
  end

  def process_actions_node(presenter, node)
    actions_node_info(node)
    presenter.replace(:main_div, r[:partial => 'show_actions'])
    presenter.hide(:paging_div)
    build_toolbar("x_summary_view_tb")
  end

  def process_custom_button_group_node(presenter, node)
    custom_button_group_node_info(node)
    presenter.replace(:main_div, r[:partial => 'show_custom_button_group'])
    presenter.hide(:paging_div)
    build_toolbar("x_summary_view_tb")
  end

  def replace_right_cell
    presenter = ExplorerPresenter.new(:active_tree => x_active_tree)
    @explorer = false

    node = x_node || params[:id]

    v_tb = case node_type(node)
           when :root         then process_root_node(presenter)
           when :god          then process_god_node(presenter, node)
           when :actions      then process_actions_node(presenter, node)
           when :button_group then process_custom_button_group_node(presenter, node)
           end

    c_tb = build_toolbar(center_toolbar_filename)
    h_tb = build_toolbar("x_history_tb")

    presenter.reload_toolbars(:history => h_tb, :center => c_tb, :view => v_tb)
    presenter.set_visibility(true, :toolbar)

    presenter[:osf_node] = x_node
    presenter[:record_id] = @record.try(:id)
    presenter[:right_cell_text] = @right_cell_text

    render :json => presenter.for_render
  end

  def textual_group_list
    [%i(properties relationships attribute_details_list association_details_list method_details_list)]
  end

  helper_method :textual_group_list
end
