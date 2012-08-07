module QuerystringHelper
  def querystring(parameters, arguments=false)
    if arguments
      arguments.each do |key,value|
        next if parameters.key?(key)
        parameters[key] = value
      end
    end
    # print querystring if needed
    if parameters.length > 0
      # first character of the querystring is ?
      querystring = '?'
      # counter
      i = 0
      # loop over each parameter: key > value
      parameters.each do |key,value|
        # put & only if needed
        ampersand = i > 0 ? '&' : ''
        querystring += ampersand+key+'='+value
        i+=1
      end
      "#{querystring}"
    end
  end
  
  def appendToQuerystring(url, parameters)
    if parameters.length > 0
      if url.scan('?').length < 1
        url = url + '?'
        amp_needed = false
      else
        amp_needed = true
      end
      # counter
      i = 0
      querystring = ''
      # loop over each parameter: key > value
      parameters.each do |key,value|
        # put & only if needed
        ampersand = (amp_needed and i < 1) ? '&' : ''
        querystring += ampersand+key+'='+value
        i+=1
      end
      url = url + querystring
    end
    "#{url}"
  end
end