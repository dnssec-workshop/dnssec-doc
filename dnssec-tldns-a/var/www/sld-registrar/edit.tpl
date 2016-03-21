<html>
<head>
<title>{{.Title}}</title>
</head>
<body>
<style>
body { font-family: monospace; }
</style>
<h1>{{.Title}}</h1>
<p><b>{{.Status}}: {{.Message}}</b></p>
<p>Allowed TLDs: at, com, de, it, net, nl, org, pl, se</p>
<p>Note: Field marked with an asterisk (<b>*</b>) are mandatory.</p>
<hr />
{{range .DomainList}}
<form action="/save" method="post">
<table>
<tr><td>Domain name:</td><td><input type="text" name="name" value="{{index .name 0}}" />&nbsp;<b>*</b></td></tr>
<tr><td><br /></td></tr>
<tr><td>OwnerC Handle:</td><td><input type="text" name="ownerc_fk" value="{{index .ownerc_fk 0}}" /></td></tr>
<tr><td>AdminC Handle:</td><td><input type="text" name="adminc_fk" value="{{index .adminc_fk 0}}" /></td></tr>
<tr><td>TechC Handle:</td><td><input type="text" name="techc_fk" value="{{index .techc_fk 0}}" /></td></tr>
<tr><td>ZoneC Handle:</td><td><input type="text" name="zonec_fk" value="{{index .zonec_fk 0}}" /></td></tr>
<tr><td><br /></td></tr>
<tr><td>Nserver1:</td><td><input type="text" name="nserver1_name" value="{{index .nserver1_name 0}}" />&nbsp;<b>*</b>&nbsp;Glue-IP: <input type="text" name="nserver1_ip" value="{{index .nserver1_ip 0}}" /></td></tr>
<tr><td>Nserver2:</td><td><input type="text" name="nserver2_name" value="{{index .nserver2_name 0}}" />&nbsp;&nbsp;&nbsp;Glue-IP: <input type="text" name="nserver2_ip" value="{{index .nserver2_ip 0}}" /></td></tr>
<tr><td>Nserver3:</td><td><input type="text" name="nserver3_name" value="{{index .nserver3_name 0}}" />&nbsp;&nbsp;&nbsp;Glue-IP: <input type="text" name="nserver3_ip" value="{{index .nserver3_ip 0}}" /></td></tr>
<tr><td><br /></td></tr>
<tr><td>DNSSEC Key 1 flags:</td><td><input type="text" name="dnskey1_flags" value="{{index .dnskey1_flags 0}}" /></td></tr>
<tr><td>DNSSEC Key 1 algorithm_id:</td><td><input type="text" name="dnskey1_algo" value="{{index .dnskey1_algo 0}}" /></td></tr>
<tr><td>DNSSEC Key 1 key_data:</td><td><textarea name="dnskey1_key" rows="10" cols="70">{{index .dnskey1_key 0}}</textarea></td></tr>
<tr><td><br /></td></tr>
<tr><td>DNSSEC Key 2 flags:</td><td><input type="text" name="dnskey2_flags" value="{{index .dnskey2_flags 0}}" /></td></tr>
<tr><td>DNSSEC Key 2 algorithm_id:</td><td><input type="text" name="dnskey2_algo" value="{{index .dnskey2_algo 0}}" /></td></tr>
<tr><td>DNSSEC Key 2 key_data:</td><td><textarea name="dnskey2_key" rows="10" cols="70">{{index .dnskey2_key 0}}</textarea></td></tr>
<tr><td><input type="submit" name="save" value="Submit" /></td><td></td></tr>
</table>
<br />
<hr />
</form>
{{end}}
</body>
</html>
