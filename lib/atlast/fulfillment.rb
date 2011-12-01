module Atlast
  class Fulfillment
    ROOT_URL = "https://api.atlastfulfillment.com"
    attr_accessor :key

    def initialize(key)
      @key = key
    end
    
    def products
      products_xml = RestClient.get(ROOT_URL + "/products.aspx", params: {key: key})
      Crack::XML.parse products_xml
    end

    def product(sku)
    end

    def inventory(sku=nil)
      params = {key: key}
      params[:sku] = sku if sku

      inventory_xml = RestClient.get ROOT_URL + "/inventory.aspx", params: params
      Crack::XML.parse inventory_xml
    end
    
    def available?(sku)
      inventory(sku)["response"]["products"]["product"]["availableQuantity"].to_i > 0
    end

    def ship(options)
      address = options[:address]
      ship_method = options[:ship_method]
      items = options[:items]
      order_id = options[:order_id] || UUID.new.generate

      builder = Builder::XmlMarkup.new
      builder.instruct! :xml, version: "1.0", encoding: "UTF-8"
      xml = builder.Orders(apiKey: key) do |orders|
        orders.Order(orderID: order_id) do |order|
          order.CustomerInfo do |ci|
            ci.FirstName address.first_name
            ci.LastName address.last_name
            ci.Address1 address.address
            ci.Address2 address.suite
            ci.City address.city
            ci.State address.state
            ci.Zip address.postal_code
            ci.Country "USA"
          end
          order.OrderDate Time.now.strftime("%D")
          order.ShipMethod ship_method
          order.Items do |xml_items|
            items.each do |item|
              xml_items.Item do |xml_item|
                xml_item.SKU item.sku
                xml_item.Qty item.quantity
              end
            end
          end
        end
      end
      response = RestClient.post(ROOT_URL + "/post_shipments.aspx", xml, content_type: :xml, accept: :xml)
      Crack::XML.parse response
    end

    def cancel(order_id)
      params = {key: key, orderId: order_id}
      response = RestClient.get ROOT_URL + "/cancel_shipment.aspx", params: params
      Crack::XML.parse response
    end
  end

end