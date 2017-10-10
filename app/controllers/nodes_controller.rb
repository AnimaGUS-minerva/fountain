class NodesController < ApplicationController
  before_action :set_node, only: [:show, :edit, :update, :destroy]

  active_scaffold :node do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_node
      @node = Node.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def node_params
      params.require(:node).permit(:name, :fqdn, :eui64, :device_type_id, :manufacturer_id, :idevid)
    end
end
