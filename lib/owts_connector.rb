module OwtsConnector
  require "xmlrpc/client"

  class << self
    def connect(host, path = '/owts/xmlrpc_request', port = 443, use_ssl = true)
      $OwtsConnector_connection = XMLRPC::Client.new3( :host => host, :path => path, :port => port, :use_ssl => use_ssl).proxy("locator")
    end

    def connected?
      !$OwtsConnector_connection.blank?
    end

    def clients(ap_cn)
      begin
        [$OwtsConnector_connection.clients_list(ap_cn)].flatten
      rescue EOFError
        retry
      rescue
        []
      end
    end

    def find_client(client_mac)
      begin
        $OwtsConnector_connection.find_client_ap(client_mac)
      rescue EOFError
        retry
      rescue
        nil
      end
    end
  end
end
