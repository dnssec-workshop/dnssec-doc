<h1>{{.Title}}</h1>
<p><b>{{.Status}}: {{.Message}}</b></p>
{{range .DomainList}}
{{index .savePostAction 0}} <a href="/{{index .savePostAction 0}}?name={{index .name 0}}">{{index .name 0}}</a> - <a href="/list">List domains</a> - <a href="/edit">Register new domain</a>
{{end}}
