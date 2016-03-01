<html>
<head>
<title>{{.Title}}</title>
</head>
<body>
<style>
body { font-family: monospace; }
tr { vertical-align: top; }
</style>
<h1>{{.Title}}</h1>
<p><b>{{.Status}}: {{.Message}}</b></p>
<table>
{{range .DomainList}}
<tr><td>Domain name</td><td>{{index .name 0}}</td></tr>
<tr><td>Created</td><td>{{index .created 0}}</td></tr>
<tr><td>Updated</td><td>{{index .updated 0}}</td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td>OwnerC Handle</td><td>{{index .ownerc_fk 0}}</td></tr>
<tr><td>AdminC Handle</td><td>{{index .adminc_fk 0}}</td></tr>
<tr><td>TechC Handle</td><td>{{index .techc_fk 0}}</td></tr>
<tr><td>ZoneC Handle</td><td>{{index .zonec_fk 0}}</td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td>Nameserver:</td></tr>
<tr><td>Nserver1</td><td>{{index .nserver1_name 0}}</td></tr>
<tr><td>Nserver1 Glue-IP:</td><td>{{index .nserver1_ip 0}}</td></tr>
<tr><td>Nserver2</td><td>{{index .nserver2_name 0}}</td></tr>
<tr><td>Nserver2 Glue-IP:</td><td>{{index .nserver2_ip 0}}</td></tr>
<tr><td>Nserver3</td><td>{{index .nserver3_name 0}}</td></tr>
<tr><td>Nserver3 Glue-IP:</td><td>{{index .nserver3_ip 0}}</td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td>DNSSEC Key 1 flags</td><td>{{index .dnskey1_flags 0}}</td></tr>
<tr><td>DNSSEC Key 1 algorithm_id</td><td>{{index .dnskey1_algo 0}}</td></tr>
<tr><td>DNSSEC Key 1 key_data</td><td>{{range .dnskey1_key}}{{.}}<br />{{end}}</td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td>DNSSEC Key 2 flags</td><td>{{index .dnskey2_flags 0}}</td></tr>
<tr><td>DNSSEC Key 2 algorithm_id</td><td>{{index .dnskey2_algo 0}}</td></tr>
<tr><td>DNSSEC Key 2 key_data</td><td>{{range .dnskey2_key}}{{.}}<br />{{end}}</td></tr>
{{end}}
</table>
<br />
<a href="/list">List domains</a>
</body>
</html>
