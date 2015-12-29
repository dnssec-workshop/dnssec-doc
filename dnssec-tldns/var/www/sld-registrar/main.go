package main

import (
	"log"
	"os"
	"strings"
	"strconv"
	"regexp"
	"html/template"
	"net/http"
	"database/sql"
	_ "github.com/go-sql-driver/mysql"
)

var listenAddr string = ""
var listenPort int = 9100

var programDir string = "/var/www/sld-registrar"

var (
	stdlog = log.New(os.Stdout, "[sld-registrar:info]: ", log.Ldate|log.Ltime)
	errlog = log.New(os.Stderr, "[sld-registrar:fail]: ", log.Ldate|log.Ltime|log.Lshortfile)
)

var db *sql.DB
var mysqlHost string = "localhost"
var mysqlPort int = 3306
var mysqlUsername string = "root"
var mysqlPassword string = "root"
var mysqlDatabase string = "sld"
var mysqlTable string = "domains"
var mysqlField string = "name"


func emptyResponse(w http.ResponseWriter, r *http.Request) {
	stdlog.Println(r.Method + " " + r.RequestURI + " - no content")
	w.WriteHeader(http.StatusNoContent)
}

func listDomains(w http.ResponseWriter, r *http.Request) {
	stdlog.Println(r.Method + " " + r.RequestURI)

	template_file := programDir + "/list.tpl"

	type data_template struct {
		Title string
		Status string
		Message string
		NameList []string
	}

	data := data_template {
		Title: "Registered Domains",
	}

	t, err := template.ParseFiles(template_file)
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		errlog.Println("Parsing template file '" + template_file + "' returned:", err)
		return
	}

	// load domain list from DB
	rows, err := db.Query("SELECT name FROM " + mysqlTable)
	if err != nil {
		errlog.Println("Mysql query error:", err)
		data.Status = "ERROR"
		data.Message = "Failed to query database for domain list."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	if err = rows.Err() ; err != nil {
		errlog.Println("Missed to read all rows from database:", err)
		data.Status = "ERROR"
		data.Message = "Unable to read all row keys from database"

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		errlog.Println("Mysql column name query error:", err)
		data.Status = "ERROR"
		data.Message = "Unable to read data keys from database."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	// Make a slice for the values
	values := make([]sql.RawBytes, len(columns))

	// rows.Scan wants '[]interface{}' as an argument, so we must copy the
	// references into such a slice
	// See http://code.google.com/p/go-wiki/wiki/InterfaceSlice for details
	scanArgs := make([]interface{}, len(values))
	for i := range values {
		scanArgs[i] = &values[i]
	}

	// Fetch rows
	var domainList []string
	for rows.Next() {
		// get RawBytes from data
		err = rows.Scan(scanArgs...)
		if err != nil {
			errlog.Println("Failed to scan database for domains:", err)
			data.Status = "ERROR"
			data.Message = "Unable to read domain list from database"

			w.WriteHeader(http.StatusServiceUnavailable)
			err = t.Execute(w, data)
			if err != nil {
				errlog.Println("Template execution failed:", err)
			}
			return
		}

		for _, val := range values {
			domainList = append(domainList, string(val))
		}
	}

	data.NameList = domainList

	err = t.Execute(w, data)
	if err != nil {
		errlog.Println("Template execution failed:", err)

		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}
}

func showEditDomain(w http.ResponseWriter, r *http.Request) {
	stdlog.Println(r.Method + " " + r.RequestURI)

	type data_template struct {
		Title string
		Status string
		Message string
		DomainList []map[string][]string
	}

	data := data_template {
	}

	action := r.RequestURI[1:5]
	origin_action := action

	template_file := programDir + "/" + action + ".tpl"

	t, err := template.ParseFiles(template_file)
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		errlog.Println("Parsing template file '" + template_file + "' returned:", err)
		return
	}

	// load user input
	err = r.ParseForm()
	if err != nil {
		errlog.Println("Request form parsing returned:", err)
		data.Status = "ERROR"
		data.Message = "Request data could not be processed."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	// insert/update domain data
	saveError := false
	if action == "save" {
		data.Title = "Process Status"
		if r.Form["save"] != nil {
			// check required data
			editDomain := make(map[string][]string)

			errlog.Println(r.Form)
			requiredKeys := []string{ "name", "nserver1_name" }
			for _, key := range requiredKeys {
				if len(r.Form[key]) < 1 {
					saveError = true
					action = "edit"
					data.Status = "ERROR"
					data.Message = "Data of field " + key + " is reqiured but not set"
					break
				}
				if r.Form[key][0] == "" {
					saveError = true
					action = "edit"
					data.Status = "ERROR"
					data.Message = "Data of field " + key + " is reqiured but not set"
					break
				}
				editDomain[key] = []string{r.Form[key][0]}
			}

			if saveError != true {
				optionalStringKeys := []string{ "ownerc_fk", "adminc_fk", "techc_fk", "zonec_fk", "nserver1_ip", "nserver2_name", "nserver2_ip", "nserver3_name", "nserver3_ip", "dnskey1_key", "dnskey2_key" }
				for _, key := range optionalStringKeys {
					if len(r.Form[key]) > 0 {
						editDomain[key] = []string{r.Form[key][0]}
					} else {
						editDomain[key] = []string{""}
					}
				}

				optionalIntKeys := []string{ "dnskey1_flags", "dnskey1_algo", "dnskey2_flags", "dnskey2_algo" }
				for _, key := range optionalIntKeys {
					if len(r.Form[key]) > 0 {
						editDomain[key] = []string{r.Form[key][0]}
					} else {
						editDomain[key] = []string{""}
					}
				}

				// filter data
				nameCheck := []string{ "name", "nserver1_name", "nserver2_name", "nserver3_name", "ownerc_fk", "adminc_fk", "techc_fk", "zonec_fk" }
				for _, key := range nameCheck {
					editDomain[key][0] = filterString(editDomain[key][0], "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-")
				}

				ipCheck := []string{ "nserver1_ip", "nserver2_ip", "nserver3_ip" }
				for _, key := range ipCheck {
					editDomain[key][0] = filterString(editDomain[key][0], "0123456789.")
				}

				intCheck := []string{ "dnskey1_flags", "dnskey2_flags", "dnskey1_algo", "dnskey2_algo" }
				for _, key := range intCheck {
					editDomain[key][0] = filterString(editDomain[key][0], "0123456789")
				}

				domainRE, _ := regexp.Compile("[a-z]+\\.(aaa|aarp|abb|abbott|abogado|ac|academy|accenture|accountant|accountants|aco|active|actor|ad|ads|adult|ae|aeg|aero|af|afl|ag|agency|ai|aig|airforce|airtel|al|allfinanz|alsace|am|amica|amsterdam|analytics|android|ao|apartments|app|apple|aq|aquarelle|ar|aramco|archi|army|arpa|arte|as|asia|associates|at|attorney|au|auction|audi|audio|author|auto|autos|aw|ax|axa|az|azure|ba|band|bank|bar|barcelona|barclaycard|barclays|bargains|bauhaus|bayern|bb|bbc|bbva|bcn|bd|be|beats|beer|bentley|berlin|best|bet|bf|bg|bh|bharti|bi|bible|bid|bike|bing|bingo|bio|biz|bj|black|blackfriday|bloomberg|blue|bm|bms|bmw|bn|bnl|bnpparibas|bo|boats|boehringer|bom|bond|boo|book|boots|bosch|bostik|bot|boutique|br|bradesco|bridgestone|broadway|broker|brother|brussels|bs|bt|budapest|bugatti|build|builders|business|buy|buzz|bv|bw|by|bz|bzh|ca|cab|cafe|cal|call|camera|camp|cancerresearch|canon|capetown|capital|car|caravan|cards|care|career|careers|cars|cartier|casa|cash|casino|cat|catering|cba|cbn|cc|cd|ceb|center|ceo|cern|cf|cfa|cfd|cg|ch|chanel|channel|chat|cheap|chloe|christmas|chrome|church|ci|cipriani|circle|cisco|citic|city|cityeats|ck|cl|claims|cleaning|click|clinic|clothing|cloud|club|clubmed|cm|cn|co|coach|codes|coffee|college|cologne|com|commbank|community|company|computer|comsec|condos|construction|consulting|contact|contractors|cooking|cool|coop|corsica|country|coupons|courses|cr|credit|creditcard|creditunion|cricket|crown|crs|cruises|csc|cu|cuisinella|cv|cw|cx|cy|cymru|cyou|cz|dabur|dad|dance|date|dating|datsun|day|dclk|de|dealer|deals|degree|delivery|dell|delta|democrat|dental|dentist|desi|design|dev|diamonds|diet|digital|direct|directory|discount|dj|dk|dm|dnp|do|docs|dog|doha|domains|doosan|download|drive|durban|dvag|dz|earth|eat|ec|edu|education|ee|eg|email|emerck|energy|engineer|engineering|enterprises|epson|equipment|er|erni|es|esq|estate|et|eu|eurovision|eus|events|everbank|exchange|expert|exposed|express|fage|fail|fairwinds|faith|family|fan|fans|farm|fashion|fast|feedback|ferrero|fi|film|final|finance|financial|firestone|firmdale|fish|fishing|fit|fitness|fj|fk|flights|florist|flowers|flsmidth|fly|fm|fo|foo|football|ford|forex|forsale|forum|foundation|fox|fr|frl|frogans|fund|furniture|futbol|fyi|ga|gal|gallery|game|garden|gb|gbiz|gd|gdn|ge|gea|gent|genting|gf|gg|ggee|gh|gi|gift|gifts|gives|giving|gl|glass|gle|global|globo|gm|gmail|gmo|gmx|gn|gold|goldpoint|golf|goo|goog|google|gop|got|gov|gp|gq|gr|grainger|graphics|gratis|green|gripe|group|gs|gt|gu|gucci|guge|guide|guitars|guru|gw|gy|hamburg|hangout|haus|healthcare|help|here|hermes|hiphop|hitachi|hiv|hk|hm|hn|hockey|holdings|holiday|homedepot|homes|honda|horse|host|hosting|hoteles|hotmail|house|how|hr|hsbc|ht|hu|hyundai|ibm|icbc|ice|icu|id|ie|ifm|iinet|il|im|immo|immobilien|in|industries|infiniti|info|ing|ink|institute|insurance|insure|int|international|investments|io|ipiranga|iq|ir|irish|is|ist|istanbul|it|itau|iwc|jaguar|java|jcb|je|jetzt|jewelry|jlc|jll|jm|jmp|jo|jobs|joburg|jot|joy|jp|jprs|juegos|kaufen|kddi|ke|kfh|kg|kh|ki|kia|kim|kinder|kitchen|kiwi|km|kn|koeln|komatsu|kp|kpn|kr|krd|kred|kw|ky|kyoto|kz|la|lacaixa|lamborghini|lamer|lancaster|land|landrover|lasalle|lat|latrobe|law|lawyer|lb|lc|lds|lease|leclerc|legal|lexus|lgbt|li|liaison|lidl|life|lifestyle|lighting|like|limited|limo|lincoln|linde|link|live|lixil|lk|loan|loans|lol|london|lotte|lotto|love|lr|ls|lt|ltd|ltda|lu|lupin|luxe|luxury|lv|ly|ma|madrid|maif|maison|man|management|mango|market|marketing|markets|marriott|mba|mc|md|me|med|media|meet|melbourne|meme|memorial|men|menu|meo|mg|mh|miami|microsoft|mil|mini|mk|ml|mm|mma|mn|mo|mobi|mobily|moda|moe|moi|mom|monash|money|montblanc|mormon|mortgage|moscow|motorcycles|mov|movie|movistar|mp|mq|mr|ms|mt|mtn|mtpc|mtr|mu|museum|mutuelle|mv|mw|mx|my|mz|na|nadex|nagoya|name|navy|nc|ne|nec|net|netbank|network|neustar|new|news|nexus|nf|ng|ngo|nhk|ni|nico|ninja|nissan|nl|no|nokia|norton|nowruz|np|nr|nra|nrw|ntt|nu|nyc|nz|obi|office|okinawa|om|omega|one|ong|onl|online|ooo|oracle|orange|org|organic|origins|osaka|otsuka|ovh|pa|page|panerai|paris|pars|partners|parts|party|pe|pet|pf|pg|ph|pharmacy|philips|photo|photography|photos|physio|piaget|pics|pictet|pictures|pid|pin|ping|pink|pizza|pk|pl|place|play|playstation|plumbing|plus|pm|pn|pohl|poker|porn|post|pr|praxi|press|pro|prod|productions|prof|properties|property|protection|ps|pt|pub|pw|py|qa|qpon|quebec|racing|re|read|realtor|realty|recipes|red|redstone|redumbrella|rehab|reise|reisen|reit|ren|rent|rentals|repair|report|republican|rest|restaurant|review|reviews|rexroth|rich|ricoh|rio|rip|ro|rocher|rocks|rodeo|room|rs|rsvp|ru|ruhr|run|rw|rwe|ryukyu|sa|saarland|safe|safety|sakura|sale|salon|samsung|sandvik|sandvikcoromant|sanofi|sap|sapo|sarl|sas|saxo|sb|sbs|sc|sca|scb|schaeffler|schmidt|scholarships|school|schule|schwarz|science|scor|scot|sd|se|seat|security|seek|sener|services|seven|sew|sex|sexy|sfr|sg|sh|sharp|shell|shia|shiksha|shoes|show|shriram|si|singles|site|sj|sk|ski|sky|skype|sl|sm|smile|sn|sncf|so|soccer|social|software|sohu|solar|solutions|sony|soy|space|spiegel|spreadbetting|sr|srl|st|stada|star|starhub|statefarm|statoil|stc|stcgroup|stockholm|storage|studio|study|style|su|sucks|supplies|supply|support|surf|surgery|suzuki|sv|swatch|swiss|sx|sy|sydney|symantec|systems|sz|tab|taipei|tatamotors|tatar|tattoo|tax|taxi|tc|tci|td|team|tech|technology|tel|telefonica|temasek|tennis|tf|tg|th|thd|theater|theatre|tickets|tienda|tips|tires|tirol|tj|tk|tl|tm|tn|to|today|tokyo|tools|top|toray|toshiba|tours|town|toyota|toys|tr|trade|trading|training|travel|travelers|travelersinsurance|trust|trv|tt|tui|tushu|tv|tw|tz|ua|ubs|ug|uk|university|uno|uol|us|uy|uz|va|vacations|vana|vc|ve|vegas|ventures|verisign|versicherung|vet|vg|vi|viajes|video|villas|vin|vip|virgin|vision|vista|vistaprint|viva|vlaanderen|vn|vodka|vote|voting|voto|voyage|vu|wales|walter|wang|wanggou|watch|watches|webcam|weber|website|wed|wedding|weir|wf|whoswho|wien|wiki|williamhill|win|windows|wine|wme|work|works|world|ws|wtc|wtf|xbox|xerox|xin|xn--11b4c3d|xn--1qqw23a|xn--30rr7y|xn--3bst00m|xn--3ds443g|xn--3e0b707e|xn--3pxu8k|xn--42c2d9a|xn--45brj9c|xn--45q11c|xn--4gbrim|xn--55qw42g|xn--55qx5d|xn--6frz82g|xn--6qq986b3xl|xn--80adxhks|xn--80ao21a|xn--80asehdb|xn--80aswg|xn--90a3ac|xn--90ais|xn--9dbq2a|xn--9et52u|xn--b4w605ferd|xn--c1avg|xn--c2br7g|xn--cg4bki|xn--clchc0ea0b2g2a9gcd|xn--czr694b|xn--czrs0t|xn--czru2d|xn--d1acj3b|xn--d1alf|xn--eckvdtc9d|xn--efvy88h|xn--estv75g|xn--fhbei|xn--fiq228c5hs|xn--fiq64b|xn--fiqs8s|xn--fiqz9s|xn--fjq720a|xn--flw351e|xn--fpcrj9c3d|xn--fzc2c9e2c|xn--gecrj9c|xn--h2brj9c|xn--hxt814e|xn--i1b6b1a6a2e|xn--imr513n|xn--io0a7i|xn--j1aef|xn--j1amh|xn--j6w193g|xn--jlq61u9w7b|xn--kcrx77d1x4a|xn--kprw13d|xn--kpry57d|xn--kpu716f|xn--kput3i|xn--l1acc|xn--lgbbat1ad8j|xn--mgb9awbf|xn--mgba3a3ejt|xn--mgba3a4f16a|xn--mgbaam7a8h|xn--mgbab2bd|xn--mgbayh7gpa|xn--mgbb9fbpob|xn--mgbbh1a71e|xn--mgbc0a9azcg|xn--mgberp4a5d4ar|xn--mgbpl2fh|xn--mgbt3dhd|xn--mgbtx2b|xn--mgbx4cd0ab|xn--mk1bu44c|xn--mxtq1m|xn--ngbc5azd|xn--ngbe9e0a|xn--node|xn--nqv7f|xn--nqv7fs00ema|xn--nyqy26a|xn--o3cw4h|xn--ogbpf8fl|xn--p1acf|xn--p1ai|xn--pbt977c|xn--pgbs0dh|xn--pssy2u|xn--q9jyb4c|xn--qcka1pmc|xn--qxam|xn--rhqv96g|xn--s9brj9c|xn--ses554g|xn--t60b56a|xn--tckwe|xn--unup4y|xn--vermgensberater-ctb|xn--vermgensberatung-pwb|xn--vhquv|xn--vuq861b|xn--wgbh1c|xn--wgbl6a|xn--xhq521b|xn--xkc2al3hye2a|xn--xkc2dl3a5ee0h|xn--y9a3aq|xn--yfro4i67o|xn--ygbi2ammx|xn--zfr164b|xperia|xxx|xyz|yachts|yamaxun|yandex|ye|yodobashi|yoga|yokohama|youtube|yt|za|zara|zero|zip|zm|zone|zuerich|zw)$")
				checkDomainName := []string{ "name", "nserver1_name", "nserver2_name", "nserver3_name" }
				for _, key := range checkDomainName {
					if len(editDomain[key]) > 0 && editDomain[key][0] != "" {
						if ! domainRE.MatchString(editDomain[key][0]) {
							saveError = true
							action = "edit"
							data.Status = "ERROR"
							data.Message = "Data of field '" + key + "' is not a valid domain name: " + editDomain[key][0]
							break
						}
					}
				}
			}

			// save domain
			if saveError != true {
				stmt, err := db.Prepare(
					"insert into " + mysqlTable +
					" (name, ownerc_fk, techc_fk, adminc_fk, zonec_fk, created, updated" +
					", dnskey1_flags, dnskey1_algo, dnskey1_key" +
					", dnskey2_flags, dnskey2_algo, dnskey2_key" +
					", nserver1_name, nserver1_ip, nserver2_name" +
					", nserver2_ip, nserver3_name, nserver3_ip" +
					") values(?, ?, ?, ?, ?, now(), now(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?" +
					") ON DUPLICATE KEY UPDATE" +
					"  ownerc_fk=?, techc_fk=?, adminc_fk=?, zonec_fk=?" +
					", updated=now(), dnskey1_flags=?, dnskey1_algo=?, dnskey1_key=?" +
					", dnskey2_flags=?, dnskey2_algo=?, dnskey2_key=?" +
					", nserver1_name=?, nserver1_ip=?, nserver2_name=?" +
					", nserver2_ip=?, nserver3_name=?, nserver3_ip=?" )

				if err != nil {
					errlog.Println("DB statement preparation failed:", err)
					data.Status = "ERROR"
					data.Message = "Failed to prepare database statement"

					w.WriteHeader(http.StatusServiceUnavailable)
					err = t.Execute(w, data)
					if err != nil {
						errlog.Println("Template execution failed:", err)
					}
					return
				}

				_, err = stmt.Exec(
					editDomain["name"][0],
					editDomain["ownerc_fk"][0], editDomain["techc_fk"][0],
					editDomain["adminc_fk"][0], editDomain["zonec_fk"][0],
					editDomain["dnskey1_flags"][0], editDomain["dnskey1_algo"][0], editDomain["dnskey1_key"][0],
					editDomain["dnskey2_flags"][0], editDomain["dnskey2_algo"][0], editDomain["dnskey2_key"][0],
					editDomain["nserver1_name"][0], editDomain["nserver1_ip"][0],
					editDomain["nserver2_name"][0], editDomain["nserver2_ip"][0],
					editDomain["nserver3_name"][0], editDomain["nserver3_ip"][0],
					editDomain["ownerc_fk"][0], editDomain["techc_fk"][0],
					editDomain["adminc_fk"][0], editDomain["zonec_fk"][0],
					editDomain["dnskey1_flags"][0], editDomain["dnskey1_algo"][0], editDomain["dnskey1_key"][0],
					editDomain["dnskey2_flags"][0], editDomain["dnskey2_algo"][0], editDomain["dnskey2_key"][0],
					editDomain["nserver1_name"][0], editDomain["nserver1_ip"][0],
					editDomain["nserver2_name"][0], editDomain["nserver2_ip"][0],
					editDomain["nserver3_name"][0], editDomain["nserver3_ip"][0] )

				if err != nil {
					errlog.Println("DB query failed:", err)
					w.WriteHeader(http.StatusBadRequest)
					data.Status = "ERROR"
					data.Message = "Failed to write domain to database"
				} else {
					data.Status = "OKAY"
					data.Message = "Domain data saved"
					editDomain["savePostAction"] = []string{"show"}
					data.DomainList = append(data.DomainList, editDomain)
				}

				err = t.Execute(w, data)
				if err != nil {
					errlog.Println("Template execution failed:", err)
				}
				return
			} else {
				editDomain["savePostAction"] = []string{"edit"}
				data.DomainList = append(data.DomainList, editDomain)
			}

		} else {
			w.WriteHeader(http.StatusBadRequest)
			data.Status = "ERROR"
			data.Message = "No domain data supplied"

			err = t.Execute(w, data)
			if err != nil {
				errlog.Println("Template execution failed:", err)
			}
			return
		}
	}


	if data.Title == "" {
		if action == "show" {
			data.Title = "Show domain"
		} else if action == "edit" {
			data.Title = "Edit domain"
		}
	}


	if action == "show" && len(r.Form["name"]) < 1 {
		errlog.Println("No domain name for query specified")
		data.Status = "ERROR"
		data.Message = "Please specify a domain name to search for."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	domainName := ""
	if len(r.Form["name"]) > 0 {
		domainName = r.Form["name"][0]
	}

	domainName = filterString(domainName, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-")
	stdlog.Println("Querying data for name:", domainName)

	// load domain info from DB
	rows, err := db.Query("SELECT * FROM " + mysqlTable + " where " + mysqlField + "=?", domainName)
	if err != nil {
		errlog.Println("Mysql query error:", err)
		data.Status = "ERROR"
		data.Message = "Failed to query database for requested domain name."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	if err = rows.Err() ; err != nil {
		errlog.Println("Missed to read all rows from database:", err)
		data.Status = "ERROR"
		data.Message = "Unable to read all row keys from database"

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		errlog.Println("Mysql column name query error:", err)
		data.Status = "ERROR"
		data.Message = "Unable to read data keys from database."

		w.WriteHeader(http.StatusServiceUnavailable)
		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}

	emptyDomain := make(map[string][]string)
	if action == "edit" {
		for _, rowName := range columns {
			emptyDomain[string(rowName)] = []string{""}
		}
	}

	// Make a slice for the values
	values := make([]sql.RawBytes, len(columns))

	// rows.Scan wants '[]interface{}' as an argument, so we must copy the
	// references into such a slice
	// See http://code.google.com/p/go-wiki/wiki/InterfaceSlice for details
	scanArgs := make([]interface{}, len(values))
	for i := range values {
		scanArgs[i] = &values[i]
	}

	// Fetch rows
	var domainData []map[string][]string
	for rows.Next() {
		// get RawBytes from data
		err = rows.Scan(scanArgs...)
		if err != nil {
			errlog.Println("Failed to scan database for domain:", err)
			data.Status = "ERROR"
			data.Message = "Unable to read domain record from database"

			w.WriteHeader(http.StatusServiceUnavailable)
			err = t.Execute(w, data)
			if err != nil {
				errlog.Println("Template execution failed:", err)
			}
			return
		}

		// Now do something with the data.
		// Here we just print each column as a string.
		var value string
		element := make(map[string][]string)
		for i, col := range values {
			// Here we can check if the value is nil (NULL value)
			if col == nil {
				value = ""
			} else {
				value = string(col)
			}
			element[columns[i]] = []string{value}
		}
		domainData = append(domainData, element)
	}

	if action == "show" {
		if len(domainData) < 1 {
			errlog.Println("No database records for domains: " + domainName)
			data.Status = "FREE"
			data.Message = "Domain NOT registered"

			w.WriteHeader(http.StatusNotFound)
			err = t.Execute(w, data)
			if err != nil {
				errlog.Println("Template execution failed:", err)
			}
			return
		}

		data.Status = "REGISTERED"
		data.Message = "Domain registered"
	}

	if action == "edit" && origin_action != "save" {
		data.Status = "NEW"
		if data.Message == "" {
			data.Message = "Fill in data to register new domain"
		}
		emptyDomain["name"][0] = "new domain"
		domainData = append(domainData, emptyDomain)
	}

	if origin_action == "save" {
		if saveError == true {
			w.WriteHeader(http.StatusBadRequest)
		}
	} else {
		data.DomainList = domainData
	}

	err = t.Execute(w, data)
	if err != nil {
		errlog.Println("Template execution failed:", err)

		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}
}

func main() {
	// Connect database
	var err error
	db, err = sql.Open("mysql",    mysqlUsername + ":" + mysqlPassword +
					"@tcp(" + mysqlHost + ":" + strconv.Itoa(mysqlPort) + ")/" +
					mysqlDatabase + "?charset=utf8")

	if err != nil {
		errlog.Println("Database initialization failed:", err)
	}

	err = db.Ping()
	if err != nil {
		errlog.Println("Error on opening database connection:")
	}

	// Configure HTTP handlers
	http.HandleFunc("/show", showEditDomain)
	http.HandleFunc("/edit", showEditDomain)
	http.HandleFunc("/save", showEditDomain)
	http.HandleFunc("/list", listDomains)
	http.HandleFunc("/favicon.ico", emptyResponse)
	http.HandleFunc("/", listDomains)

	stdlog.Println("Starting on " + listenAddr + ":" + strconv.Itoa(listenPort))

	err2 := http.ListenAndServe(listenAddr + ":" + strconv.Itoa(listenPort), nil)
	if err2 != nil {
		errlog.Println("Failed to bind on" + listenAddr + ":" + strconv.Itoa(listenPort) + ":", err)
	}
}

// Based on http://rosettacode.org/wiki/Strip_a_set_of_characters_from_a_string#Go
func filterString(str, chr string) string {
	return strings.Map(func(r rune) rune {
		if strings.IndexRune(chr, r) >= 0 {
			return r
		}
		return -1
	}, str)
}
