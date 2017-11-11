class ManufacturersController < AdminController
  before_action :set_manufacturer, only: [:show, :edit, :update, :destroy]

  active_scaffold :manufacturer do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_manufacturer
      @manufacturer = Manufacturer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manufacturer_params
      params.require(:manufacturer).permit(:name)
    end
end
