package main

import (
	"log"
	"os"
	"strings"
	"strconv"
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
	errlog.Println(r.Form)
	if action == "save" {
		data.Title = "Process Status"
		if r.Form["save"] != nil {
			data.Status = "OKAY"
			data.Message = "Domain data saved"
		} else {
			w.WriteHeader(http.StatusBadRequest)
			data.Status = "ERROR"
			data.Message = "No domain data supplied"
		}

		err = t.Execute(w, data)
		if err != nil {
			errlog.Println("Template execution failed:", err)
		}
		return
	}


	if action == "show" {
		data.Title = "Show domain"
	} else if action == "edit" {
		data.Title = "Edit domain"
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

	domainName = filterString(domainName, "aabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-")
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

	if action == "edit" {
		data.Status = "NEW"
		data.Message = "Fill in data to register new domain"
		emptyDomain["name"][0] = "new domain"
		domainData = append(domainData, emptyDomain)
	}

	data.DomainList = domainData

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
