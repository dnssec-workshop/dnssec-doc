<h1>{{.Title}}</h1>
<b>{{.Status}}{{.Message}}</b>
{{range .NameList}}
<a href="/show?name={{.}}">{{.}}</a><br />
{{end}}
