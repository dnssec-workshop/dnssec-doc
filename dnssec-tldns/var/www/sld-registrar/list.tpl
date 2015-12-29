<h1>{{.Title}}</h1>
<p><b>{{.Status}}{{.Message}}</b></p>
{{range .NameList}}
<a href="/show?name={{.}}">{{.}}</a> - <a href="/edit?name={{.}}">edit</a><br />
{{end}}
