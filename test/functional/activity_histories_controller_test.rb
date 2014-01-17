require 'test_helper'

class ActivityHistoriesControllerTest < ActionController::TestCase
  test "should not get index unless authenticated" do
    get :index, :wisp_id => 1
    assert_redirected_to new_user_session_url
  end

  test "should get index if wisp_viewer" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    get :index, { :wisp_id => wisp.name }
    assert_response :success
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", "%s&#x25BE;" % [I18n.t(:Wisp)]
  end
  
  test "should get show" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    get :show, { :format => 'json', :wisp_id => wisp.name, :access_point_id => 1 }
    assert_response :success
  end
  
  test "should write file in tmp folder" do
    # create new file in tmp folder
    file = File.new('tmp/testfile', 'w+')
    assert file.to_s.length > 0, 'tmp folder is not writable'
    # delete file
    file = File.delete('tmp/testfile')
    assert file == 1, 'could not delete test file from tmp folder'
  end
  
  test "should export a file" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    json = %q{[["Marino1","Piazza Matteotti","2012-02-22","Piazza Matteotti","Marino ","","sì","100.0%","0.0%"],["RaggioDiSole","B&B Raggio di Sole","2012-06-13","Via IV Novembre, 116","Trevignano Romano","B&B Raggio di Sole - Trevignano Romano","sì","100.0%","0.0%"],["ht11","Bar L'Appuntamento","2011-09-19","Via Flaminia, 1805","Roma","Bar L'appuntamento\n","sì","99.9%","0.1%"],["sirit02","Accademia di San Luca - Giardino","2011-11-07","Piazza  Accademia di San Luca","Roma","","sì","99.9%","0.1%"],["Cerveteri_1","Museo","2011-12-05","Piazza Santa Maria","Cerveteri","","sì","99.9%","0.1%"],["Sirit39","","2012-01-17","via delle tre cannelle, 1","Roma","","no","99.9%","0.1%"],["CinemaAdriano","Cinema Adriano","2012-01-23","Piazza Cavour 22","Roma","","sì","99.9%","0.1%"],["Jenne_Comune","Municipio","2012-02-22","Via IV Novembre 10","Jenne","","sì","99.9%","0.1%"],["OceanSurf","Ocean surf","2012-02-22","Viale Adriatico 4","Cerveteri","","sì","99.9%","0.1%"],["Colleferro_bibl","Biblioteca comunale","2012-02-27","Via Carpinetana sud 144","Colleferro","","sì","99.9%","0.1%"],["Pisoniano_bibl","Biblioteca comunale","2012-02-27","Via Piagge","Pisoniano","","sì","99.9%","0.1%"],["chiostro","Chiosco del Bramante - libreria","2012-03-07","Via Arco della Pace 5","Roma","","sì","99.9%","0.1%"],["H2S22","That’s Amore","2012-03-27","Via in Arcione 115","Roma","","sì","99.9%","0.1%"],["H2S23","Camping Int. Castelfusano","2012-03-27","Via Litoranea 132 Km","Roma","","sì","99.9%","0.1%"],["Lion05","S.S Lazio Baseball","2012-05-03","via della villa di lucina 12","Roma","S.S Lazio Baseball","sì","99.9%","0.1%"],["Lion09","a.s.d Funsport","2012-05-09","via giuseppe de luca 30","Roma","","sì","99.9%","0.1%"],["RoccaCanterano","Municipio","2012-05-24","Via Del Municipio, 31","Rocca Canterano","","sì","99.9%","0.1%"],["ht08","ASD De Rossi Fitness & Wellness ","2011-09-19","Via Appia Nuova 464","Roma","Associazione Sportiva\n\nASD De Rossi...","sì","99.8%","0.2%"],["ht10","ABC American Bar & Coffee","2011-09-19","Via Pian di Sco, 60 ","Roma","ABC American Bar & Coffee\n\nVia Pian...","sì","99.8%","0.2%"],["ht15","WiCoffee BAR","2011-11-04","Via Cave di Pietralata, 25 ","Roma","","sì","99.8%","0.2%"],["sirit22","Hotel&Residence T-Village","2011-12-13","via delle Tamerici 49","Anzio","","sì","99.8%","0.2%"],["CAPomezia2","Centro Anziani Torvajanica","2011-12-15","via Gran Bretagna 42","Pomezia","","sì","99.8%","0.2%"],["ht21","Wellness Club","2012-02-01","Viale Rousseau 124","Roma","","sì","99.8%","0.2%"],["LadispoliBibl","Biblioteca comunale","2012-02-23","via caltagirone","Ladispoli","","sì","99.8%","0.2%"],["cnt_sangiovanni","Complesso Ospedaliero San Giovanni-Ad...","2012-04-11","via dell'Amba Aradam","Roma","","sì","99.8%","0.2%"],["Lion23","","2012-06-07","Via Domenico Jachino, 181","Roma","","sì","99.8%","0.2%"],["CentroLepetit","Centro Culturale Lepetit","2012-02-16","via roberto lepetit, 86","Roma","","sì","99.7%","0.3%"],["Manziana_munic","Municipio","2012-02-22","Largo Gioacchino Fara ","Manziana","","sì","99.7%","0.3%"],["Provinciattiva2","Provinciattiva S.p.A.","2012-05-10","Via Angelo Bargoni, 70","Roma","","sì","99.7%","0.3%"],["BarCasaComune","Bar Casa Comune","2012-05-11","Lungomare marina di palo laziale","Ladispoli","","sì","99.7%","0.3%"],["CaffèTirreno","Gran caffè Tirreno","2011-12-15","Via Sergio Angelucci ","Cerveteri","","sì","99.6%","0.4%"],["Affile_polizia","Polizia Municipale","2012-02-22","Via Monteduomo 1","Affile","","sì","99.6%","0.4%"],["RianoGiardRosta","La Rosta","2012-05-17","via taddeide","Riano","","sì","99.6%","0.4%"],["Valmontone2","Municipio","2012-01-25","Via Nazionale 5","Valmontone","","sì","99.5%","0.5%"],["RoccaSStefano","Pontica","2012-02-27","Piazza Pontica","Rocca Santo Stefano","","sì","99.5%","0.5%"],["ScuolaIAlpi","Scuola Ilaria Alpi ","2012-05-11","Via Varsavia, 5","Ladispoli","","sì","99.5%","0.5%"],["ht17","Studio 13 Scuola professionale per tr...","2012-02-01","Piazza Cavour 13 ","Roma","","sì","99.4%","0.6%"],["MissPizza","Miss Pizza","2012-01-17","Via Giuseppe Gioacchino Belli 19","Roma","","sì","99.2%","0.8%"],["H2S05","H2S","2011-07-29","via assisi","roma","","sì","99.1%","0.9%"],["Tecnotown","Tecnotown","2011-11-07","Via Spallanzani 1","Roma","","sì","99.1%","0.9%"],["ht12","Nuova Polisportiva De Rossi ","2011-11-04","Via di Vigna Fabbri","Roma","","sì","98.9%","1.1%"],["domus","Domus di Palazzo Valentini","2012-03-07","Via Quattro Novembre 119","Roma","","sì","98.9%","1.1%"],["CNR_MontorioR","Municipio","2012-05-15","via 4 Novembre","Montorio Romano","","sì","98.8%","1.2%"],["ComuneLariano","Municipio","2012-02-22","Piazza Santa Eurosia 1","Lariano","","sì","98.8%","1.2%"],["H2S20","","2012-03-09","Via Assisi","Roma","","no","98.8%","1.2%"],["Subiaco2","Scuola Angelucci","2012-03-18","Via Carlo Alberto Dalla Chiesa","Subiaco ","","sì","98.8%","1.2%"],["ht09","Pub Il Clown","2011-09-19","Via Litoranea 22","Roma","PUB \"IL CLOWN\"\n\nVIA LITORANEA, 22\n...","sì","98.7%","1.3%"],["CACAscolano1","Centro Anziani Campo Ascolano","2012-05-09","Via Po, 43","Pomezia","","sì","98.7%","1.3%"],["MonterotondoBib","Biblioteca Comunale","2012-05-22","Piazza Don Minzoni ","Monterotondo","","sì","98.7%","1.3%"],["Civitavecchia3","Tribunale (2°piano)","2012-03-18","Via Terme di Traiano","Civitavecchia","","sì","98.6%","1.4%"],["Sirit55","Liberi di ","2012-02-14","Piazza Santa Maria Liberatrice, 46","Roma","","sì","98.5%","1.5%"],["ht14","Club Residence I cieli di Roma","2011-11-04","Via Francesca Bertini, 8","Roma","","sì","98.4%","1.6%"],["RoccaDiPapa","Biblioteca comunale","2012-02-27","Viale Enrico Ferri 67","Rocca di Papa","","sì","98.4%","1.6%"],["ht13","Club Residence I cieli di Roma","2011-11-04","Via Francesca Bertini, 8","Roma","","sì","98.3%","1.7%"],["Lion01","Circolo sportivo \"Villa flaminia\"","2012-04-18","via donatello 20","Roma","l'access point si trova nella sala Bar","sì","98.3%","1.7%"],["Nereo","Nereo Protezione Civile","2012-03-15","Via Fenicotteri 6","Ardea","","sì","98.2%","1.8%"],["Ht04","Ristorante Evandro","2011-09-08","Via Egna, 3","Roma","Ristorante Evandro ap2","sì","97.6%","2.4%"],["Lion15_SSpirito","Ospedale Santo Spirito","2012-05-22","lungotevere in sassia 1","Roma","Configurazione ip statica: \n10.65.1....","sì","97.6%","2.4%"],["OlevanoMunic","Municipio","2011-11-23","Via del Municipio","Olevano Romano","Ufficio anagrafe-Municipio, Via del M...","sì","97.2%","2.8%"],["Enoteca","Enoteca della Provincia di Roma","2012-01-17","Via del Foro Traiano 82 ","Roma","","sì","97.1%","2.9%"],["Ht03","Ristorante Evandro","2011-09-08","Via Egna, 3","Roma","Ristorante Evandro ap1","sì","96.9%","3.1%"],["Zagarolo1","Piazza Indipendenza","2012-05-18","piazza indipendenza","Zagarolo","","sì","96.9%","3.1%"],["Zagarolo2","BAR Nemi - Stazione FS","2012-05-18","Piazzale della Stazione","Zagarolo","","sì","96.4%","3.6%"],["valentino","Valentino","2011-07-11","Via dei Luceri","Roma","","sì","96.2%","3.8%"],["Aricciacampanil","Campanile","2011-12-15","Corso Garibaldi 1","Ariccia"," ","sì","96.1%","3.9%"],["H2S12","Sporting Palace","2011-12-14","Via Mantova 1","Roma","","sì","96.0%","4.0%"],["Lion16_SSpirito","Ospedale Santo Spirito","2012-05-22","lungotevere in sassia 1","Roma","Configurazione ip statica: \n10.65.1....","sì","95.7%","4.3%"],["Ht05","Due Emme Bar","2011-09-08","Via Monte Noce, 1","Sacrofano","Due Emme Bar","sì","95.5%","4.5%"],["H2S07","Equipe Food","2011-09-21","Piazza San Claudio, 165","Roma","Equipe Food","sì","95.5%","4.5%"],["Bellegra","Municipio","2011-11-07","Piazza del Municipio","Bellegra","unicipio, Piazza del Municipio\nrefer...","sì","95.2%","4.8%"],["phoenix03","Scuola Media  Di Donato","2012-05-27","via Bixio 83","Roma","","sì","95.1%","4.9%"],["barocciaio","Il Barrocciaio","2011-07-11","Via dei Salentini,12","Roma","","sì","94.9%","5.1%"],["ht19","La fonte del gelato ","2012-02-01","Piazza della Pace 6","Ciampino","","sì","94.6%","5.4%"],["Lion20","circolo ippico Acquasanta","2012-05-27","via vallericcia","Roma","","sì","94.6%","5.4%"],["H2S21","Bar Treccì","2012-03-09","Via  De Rinaldis 30","Roma","","sì","94.5%","5.5%"],["ht16","Bar La caffettiera","2011-11-04","Piazza di Pietra, 65 ","Roma","","sì","94.4%","5.6%"],["Rignano2","Giardini","2011-12-15","Piazza IV Novembre 1","Rignano Flaminio","","sì","93.8%","6.2%"],["colonna_traiana","Colonna Traiana","2011-12-19","via di Sant'Eufemia","Roma","","sì","93.8%","6.2%"],["Rignano1","Municipio","2012-01-12","Piazza IV Novembre 1","Rignano Flaminio","","sì","93.8%","6.2%"],["frascatimunic2","Municipio","2011-12-13","piazza Marconi","Frascati","","sì","93.7%","6.3%"],["CNR_Guidonia1","Municipio ","2012-02-20","Piazza Matteotti","Guidonia Montecelio","","sì","93.4%","6.6%"],["Rainbow04","Rainbow Magic Land","2012-04-19","via della pace","Valmontone","ip: 172.20.1.200\n\nKS Tuffatori","sì","93.4%","6.6%"],["H2S11","Retecamere","2011-11-24","Via Valadier 42","Roma","","sì","93.2%","6.8%"],["ht18","Hotel Regio","2012-02-01","via Volturno 22","Roma","","sì","93.2%","6.8%"],["Lion06","Centro anzianiPullino","2012-05-03","via pullino 97","Roma","ip Statico\n\n192.168.10.30\n\nsubnet...","sì","93.2%","6.8%"],["Lion17_SSpirito","Ospedale Santo Spirito","2012-05-22","lungotevere in sassia 1","Roma","Configurazione ip statica: \n10.65.1....","sì","93.2%","6.8%"],["Rainbow02","Rainbow Magic Land","2012-04-19","via della pace","Valmontone","ip: 172.20.1.100\n\nKS MOTTA","sì","93.1%","6.9%"],["Provinciattiva1","Provinciattiva","2011-11-23","Via Angelo Bargoni, 40","Roma","","sì","92.9%","7.1%"],["Valmontone1","Stazione F.S.","2012-01-25","Piazza XXV Aprile","Valmontone","","sì","92.9%","7.1%"],["Lion07","Lavanderia Ondablu","2012-05-04","via giuseppe de mattheis 3","Roma","","sì","92.9%","7.1%"],["Lion11","Emmeci Sport","2012-05-10","via Pellaro 1","roma","","sì","92.9%","7.1%"],["CNR_FonteNuova","Piazza delle rose - Santa Lucia","2012-02-07","Piazza delle Rose","Fonte Nuova","","sì","92.7%","7.3%"]]}
    post :export, :wisp_id => wisp.name, :data => json, 'CONTENT_TYPE' => 'application/json', :format => 'json'
    assert_response :success, "couldn't post data"
    json = ActiveSupport::JSON.decode(response.body)
    assert json['url'] == "/wisps/#{wisp.name}/send_report", 'json url param mismatch'
    file = File.open('tmp/availability-report.xls')
    assert file.inspect == '#<File:tmp/availability-report.xls>', 'something went wrong with report file creation'
    get :send_report, :wisp_id => wisp.name
    assert_response :success, "couldn't download report"
    assert_raise Errno::ENOENT do
      file = File.open('tmp/availability-report.xls')
    end
    assert_raise ActionController::MissingFile do
      get :send_report, :wisp_id => wisp.name
    end
  end
  
  test "status column is present if configured accordingly" do   
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    
    CONFIG['showstatus'] = true
    get :index, :wisp_id => wisp.name
    assert_select '#report th.status', I18n.t(:Status)
    
    CONFIG['showstatus'] = false
    get :index, :wisp_id => wisp.name
    assert !response.body.index('class="status">%s</th>' % I18n.t(:Status))
  end
  
  test "availability report for wisp name containing space" do
    sign_in users(:admin)
    get :index, { :wisp_id => wisps(:freewifibrescia).name.gsub(' ', '-') }
    assert_response :success
    assert_select 'table#report', 1
  end
end
