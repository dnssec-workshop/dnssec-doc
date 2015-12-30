<h1>{{.Title}}</h1>
<p><b>{{.Status}}{{.Message}}</b></p>
<p><a href="/edit">Register new domain</a></p>
{{range .NameList}}
<a href="/show?name={{.}}">{{.}}</a> - <a href="/edit?name={{.}}">edit</a><br />
{{end}}
